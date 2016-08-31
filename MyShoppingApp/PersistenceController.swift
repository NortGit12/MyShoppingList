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
        
        var referencesToExclude = [CKReference]()
        
        var predicate: NSPredicate!
        let moc = PersistenceController.sharedController.moc
        moc.performBlockAndWait {
            
            referencesToExclude = self.syncedManagedObjects(type).flatMap({ $0.cloudKitReference })
            
            predicate = NSPredicate(format: " NOT(recordID IN %@)", argumentArray: [referencesToExclude])
            
            if referencesToExclude.isEmpty {
                predicate = NSPredicate(value: true)
            }
        }
        
        cloudKitManager.fetchRecordsWithType(type, predicate: predicate, recordFetchedBlock: { (record) in
            
            /*
             Again, doing this CoreData work on the same thread as the moc
             */
            
            moc.performBlock({
                
                switch type {
                    
                case StoreCategory.type:
                    
                    // Existing CoreData StoreCategory
                    guard let _ = StoreCategoryModelController.sharedController.getStoreCategoryByIdName(record.recordID.recordName) else {
                        
                        // New CoreData StoreCategory
                        guard let _ = StoreCategory(record: record) else {
                            
                            NSLog("Error: Could not create a new Store Category from the CloudKit record.")
                            return
                        }
                        
                        return
                    }
                    
                case Store.type:
                    
                    // Existing CoreData Store
                    guard let _ = StoreModelController.sharedController.getStoreByIdName(record.recordID.recordName) else {
                        
                        // New CoreData Store
                        guard let _ = Store(record: record) else {
                            
                            NSLog("Error: Could not create a new Store from the CloudKit record.")
                            return
                        }
                        
                        return
                    }
                
                case Item.type:
                    
                    // Existing CoreData Item
                    guard let _ = ItemModelController.sharedController.getItemByIdName(record.recordID.recordName) else {
                        
                        // New CoreData Item
                        guard let _ = Item(record: record) else {
                            
                            NSLog("Error: Could not create a new Item from the CloudKit record.")
                            return
                        }
                        
                        return
                    }
                    
                default: return
                }
                
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
    
    func pushChangesToCloudKit(completion: ((success: Bool, error: NSError?) -> Void)? = nil) {
        
        let unsyncedManagedObjectsArray = self.unsyncedManagedObjects(StoreCategory.type) + self.unsyncedManagedObjects(Store.type) + self.unsyncedManagedObjects(Item.type)
        let unsyncedRecordsArray = unsyncedManagedObjectsArray.flatMap({ $0.cloudKitRecord })
        
        cloudKitManager.saveRecords(unsyncedRecordsArray, perRecordCompletion: { (record, error) in     // per record block
            
            if error != nil {
                print("Error: Could not push unsynced record to CloudKit: \(error)")
            }
            
            guard let record = record else { return }
            
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
}