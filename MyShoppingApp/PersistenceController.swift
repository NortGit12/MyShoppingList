//
//  PersistenceController.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/23/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

class PersistenceController {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    static let sharedController = PersistenceController()
    let moc = Stack.sharedStack.managedObjectContext
    var cloudKitManager = CloudKitManager()
    var isSyncing: Bool = false
    
    //==================================================
    // MARK: - Methods
    //==================================================
    
    func saveContext() {
        
        do {
            try moc.save()
        } catch {
            print("Error: Failed to save the Managed Object Context")
        }
    }
    
    //==================================================
    // MARK: - CloudKit Persistence Methods
    //==================================================
    
    func syncedManagedObjects(type: String) -> [CloudKitManagedObject] {
        
        let request = NSFetchRequest(entityName: type)
        let predicate = NSPredicate(format: " recordIDData != nil")
        request.predicate = predicate
        
        let syncedRecords = (try? PersistenceController.sharedController.moc.executeFetchRequest(request)) as? [CloudKitManagedObject] ?? []
        
        return syncedRecords
    }
    
    func unsyncedManagedObjects(type: String) -> [CloudKitManagedObject] {
        
        let request = NSFetchRequest(entityName: type)
        let predicate = NSPredicate(format: " recordIDData == nil")
        request.predicate = predicate
        
        let unsyncedRecords = (try? PersistenceController.sharedController.moc.executeFetchRequest(request)) as? [CloudKitManagedObject] ?? []
        
        return unsyncedRecords
    }
    
    func fetchNewRecords(type: String, completion: (() -> Void)? = nil) {
        
//        var referencesToExclude = [CKReference]()
        
        var predicate: NSPredicate!
        let moc = PersistenceController.sharedController.moc
//        moc.performBlockAndWait {
        
            /*
             All users will use the same set of ten Store Categories.  They should only see their Stores and Items.
             */
//            if type != StoreCategory.type {
//            
//                guard let creatorUserRecord = UserController.sharedController.loggedInUserRecord
//                    , creatorUserRecordID = creatorUserRecord.creatorUserRecordID
//                    else {
//                        
//                        NSLog("Error: Could not either identify the logged in user or get their record ID.")
//                        return
//                }
//                
//                referencesToExclude = self.syncedManagedObjects(type).flatMap({ $0.cloudKitReference })
//
//                predicate = NSPredicate(format: " NOT(recordID IN %@)", argumentArray: [referencesToExclude])
//                let specificUserPredicate = NSPredicate(format: "creatorUserRecordID == %@", argumentArray: [creatorUserRecordID])
//                
//                predicate = NSCompoundPredicate(type: .AndPredicateType, subpredicates: [recordExclusionPredicate, specificUserPredicate])
//            }
            
//            referencesToExclude = self.syncedManagedObjects(type).flatMap({ $0.cloudKitReference })
//            
//            if referencesToExclude.isEmpty {
//                predicate = NSPredicate(value: true)
//            }
//        }
        
//        // Get all of the records (StoreCategories from the public database and Stores and Items from the private database)
//        let predicate = NSPredicate(value: true)
        
        predicate = NSPredicate(value: true)

        let database: CKDatabase
        switch type {
        case StoreCategory.type: database = cloudKitManager.publicDatabase
        default: database = cloudKitManager.privateDatabase
        }
        
//        self.cloudKitManager.fetchRecordsWithType(type, predicate: predicate, recordFetchedBlock: { (record) in
        cloudKitManager.fetchRecordsWithType(database, type: type, predicate: predicate, recordFetchedBlock: { (record) in
        
            /*
             Again, doing this CoreData work on the same thread as the moc
             */
            
            moc.performBlock({
                
                self.evaluateToCreateNewCoreDataObjectsForCloudKitRecordsByType(type, record: record)
                
                PersistenceController.sharedController.saveContext()
            })
            
        }) { (records, error) in        // completion block
            
            if error != nil {
                print("Error: Could not fetch unsynced CloudKit records: \(error)")
            }
            
            if let completion = completion {
                completion()
            }
        }
    }
    
    func evaluateToCreateNewCoreDataObjectsForCloudKitRecordsByType(type: String, record: CKRecord) {
        
        switch type {
            
        case StoreCategory.type:
            
            // Existing CoreData StoreCategory
            guard let _ = StoreCategoryModelController.sharedController.fetchStoreCategoryByIdName(record.recordID.recordName) else {
                
                // New CoreData StoreCategory
                guard let _ = StoreCategory(record: record) else {
                    
                    NSLog("Error: Could not create a new Store Category from the CloudKit record.")
                    return
                }
                
                return
            }
            
        case Store.type:
            
            // Existing CoreData Store
            guard let _ = StoreModelController.sharedController.fetchStoreByIdName(record.recordID.recordName) else {
                
                // New CoreData Store
                guard let _ = Store(record: record) else {
                    
                    NSLog("Error: Could not create a new Store from the CloudKit record.")
                    return
                }
                
                return
            }
            
        case Item.type:
            
            // Existing CoreData Item
            guard let _ = ItemModelController.sharedController.fetchItemByIdName(record.recordID.recordName) else {
                
                // New CoreData Item
                guard let _ = Item(record: record) else {
                    
                    NSLog("Error: Could not create a new Item from the CloudKit record.")
                    return
                }
                
                return
            }
            
        default: return
        }
    }
    
    func pushChangesToCloudKit(completion: ((success: Bool, error: NSError?) -> Void)? = nil) {
        
        let unsyncedManagedObjectsArray = self.unsyncedManagedObjects(StoreCategory.type) + self.unsyncedManagedObjects(Store.type) + self.unsyncedManagedObjects(Item.type)
        let unsyncedRecordsArray = unsyncedManagedObjectsArray.flatMap({ $0.cloudKitRecord })
        
//        cloudKitManager.saveRecords(unsyncedRecordsArray, perRecordCompletion: { (record, error) in     // per record block
        cloudKitManager.saveRecords(cloudKitManager.privateDatabase, records: unsyncedRecordsArray, perRecordCompletion: { (record, error) in     // per record block
            
            if error != nil {
                print("Error: Could not push unsynced record to CloudKit: \(error)")
            }
            
            guard let record = record else {
                
                NSLog("Error: Could not unwrap the saved record.")
                return
            }
            
            /*
             This supports multi-threading.  Anything we do with MangedObjectContexts must need to be done on the same thread that it is in.  The code inside this cloudKitManager.saveRecords(...) method will be on a background thread and the MangedObjectContext (moc) is on the main thread, so we need a way to get this.  ALL pieces of things that deal with Core Data need to be in here, working on the main thread where the moc is.  In here the $0.recordName accesses Core Data and so does the .update(...) method.
             */
            
            let moc = PersistenceController.sharedController.moc
            moc.performBlock({
            
                if let matchingRecord = unsyncedManagedObjectsArray.filter({ $0.recordName == record.recordID.recordName }).first {
                    
                    matchingRecord.updateRecordIDData(record)
                }
            })
            
        }) { (records, error) in        // completion block
            
            if error != nil {
                print("Error saving unsynced record to CloudKit: \(error)")
            }
            
            if let completion = completion {
                
                let success = records != nil
                completion(success: success, error: error)
            }
        }
    }
    
    func performFullSync(completion: (() -> Void)? = nil) {
        
        if isSyncing == true {
            
            if let completion = completion {
                
                // Doing this here is okay, but not ideal
                completion()
            }
        } else {
            
            isSyncing = true
            
            pushChangesToCloudKit({ (_) in
                
                print("Pushing changes to CloudKit...")
                
                self.fetchNewRecords(StoreCategory.type) {
                    
                    print("Fetching new StoreCategories from CloudKit...")
                    
                    self.fetchNewRecords(Store.type) {
                        
                        print("Fetching new Stores from CloudKit...")
                    
                        self.fetchNewRecords(Item.type) {
                            
                            print("Fetching new Items from CloudKit...")
                    
                            self.isSyncing = false
                            
                            if let completion = completion {
                                completion()
                            }
                        }
                    }
                }
            })
        }
    }
    
    func identifyManagedObjectType(recordID: CKRecordID) -> String {
        
        let storeCategoryManagedObject = StoreCategoryModelController.sharedController.fetchStoreCategoryByIdName(recordID.recordName)
        let storeManagedObject = StoreModelController.sharedController.fetchStoreByIdName(recordID.recordName)
        let itemManagedObject = ItemModelController.sharedController.fetchItemByIdName(recordID.recordName)
        
        var managedObjectType = String()
        
        if storeCategoryManagedObject != nil { managedObjectType = StoreCategory.type}
        else if storeManagedObject != nil { managedObjectType = Store.type}
        else if itemManagedObject != nil { managedObjectType = Item.type}
        
        return managedObjectType
    }
    
    func createUpdateSubscription(recordType: String) {
        
        let predicate = NSPredicate(value: true)
        
        var database: CKDatabase
        var desiredKeys: [String]?
        switch recordType {
        case StoreCategory.type:
            database = cloudKitManager.publicDatabase
            desiredKeys = [StoreCategory.nameKey, StoreCategory.imageKey, StoreCategory.imageFlatKey, StoreCategory.storesKey]
        case Store.type:
            database = cloudKitManager.privateDatabase
            desiredKeys = [Store.nameKey, Store.imageKey, Store.categoriesKey, Store.itemsKey]
        case Item.type:
            database = cloudKitManager.privateDatabase
            desiredKeys = [Item.nameKey, Item.quantityKey, Item.notesKey, Item.storeKey]
        default:
            NSLog("Error: Could not identify the record type when attempting to create an update subscription.")
            return
        }
        
        cloudKitManager.subscribe(database, type: recordType, predicate: predicate, subscriptionID: "\(recordType)Updates", contentAvailable: true, alertBody: nil, desiredKeys: desiredKeys, options: .FiresOnRecordUpdate) { (subscription, error) in
            
            // TODO: Implement this, possibly making it flexible enough for creating, update, & delete
        }
    }
    
    func createDeleteSubscription() {
        
        
    }
}

















