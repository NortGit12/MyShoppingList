//
//  StoreModelController.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/24/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

class StoreModelController {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    static let sharedController = StoreModelController()
    let cloudKitManager = CloudKitManager()
    
    //==================================================
    // MARK: - Methods
    //==================================================
    
    func createStore(name: String, image: UIImage?, categories: [StoreCategory], sourceIsRemoteNotification: Bool = false, completion: (() -> Void)? = nil) {
        
        var storeImage: UIImage
        if let image = image {
            storeImage = image
        } else {
            storeImage = UIImage(named: "default-image_store")!
        }
        
        guard let imageData = UIImagePNGRepresentation(storeImage)
            , store = Store(name: name, image: imageData, categories: categories, items: nil)
            else {
                
                NSLog("Error: Could not either access the image data or create a new Store.")
                return
            }
        
        PersistenceController.sharedController.saveContext()
        
        if sourceIsRemoteNotification == false {
            
            if let storeCloudKitRecord = store.cloudKitRecord {
                
                cloudKitManager.saveRecord(cloudKitManager.privateDatabase, record: storeCloudKitRecord, completion: { (record, error) in
                    
                    defer {
                        
                        if let completion = completion {
                            completion()
                        }
                    }
                    
                    if error != nil {
                        
                        NSLog("Error: New Store \"\(store.name)\" could not be saved to CloudKit: \(error)")
                        return
                    }
                    
                    if let record = record {
                        
                        let moc = PersistenceController.sharedController.moc
                        
                        /*
                         The "...AndWait" makes the subsequent work wait for the performBlock to finish.  By default, the moc.performBlock(...) is asynchronous, so the work in there would be done asynchronously on another thread and the subsequent lines would run immediately.
                         */
                        
                        moc.performBlockAndWait({
                            
                            store.updateRecordIDData(record)
                            NSLog("New Store \"\(store.name)\" successfully saved to CloudKit.")
                        })
                    }
                })
            }
        }
    }
    
    func fetchStoreByIdName(idName: String) -> Store? {
        
        if idName.isEmpty { return nil }
        
        let request = NSFetchRequest(entityName: Store.type)
        let predicate = NSPredicate(format: "recordName == %@", argumentArray: [idName])
        request.predicate = predicate
        
        let resultsArray = (try? PersistenceController.sharedController.moc.executeFetchRequest(request)) as? [Store]
        
        return resultsArray?.first ?? nil
    }
    
    func fetchStores() -> [Store]? {
        
        let request = NSFetchRequest(entityName: Store.type)
        let predicate = NSPredicate(value: true)
        request.predicate = predicate
        
        var resultsArray = (try? PersistenceController.sharedController.moc.executeFetchRequest(request)) as? [Store]
        resultsArray?.sortInPlace({ $0.0.name < $0.1.name })
        
        return resultsArray ?? nil
    }
    
    func updateStore(store: Store, sourceIsRemoteNotification: Bool = false, completion: (() -> Void)? = nil) {
        
        let request = NSFetchRequest(entityName: Store.type)
        let predicate = NSPredicate(format: "recordName = %@", argumentArray: [store.recordName])
        request.predicate = predicate
        
        let resultsArray = (try? PersistenceController.sharedController.moc.executeFetchRequest(request)) as? [Store]
        let existingStore = resultsArray?.first
        
        existingStore?.name = store.name
        existingStore?.image = store.image
        existingStore?.categories = store.categories
        
        PersistenceController.sharedController.saveContext()
        
        if sourceIsRemoteNotification == false {
        
            if let storeCloudKitRecord = store.cloudKitRecord {
                
                cloudKitManager.modifyRecords(cloudKitManager.privateDatabase, records: [storeCloudKitRecord], perRecordCompletion: nil, completion: { (records, error) in
                    
                    defer {
                        
                        if let completion = completion {
                            completion()
                        }
                    }
                    
                    if error != nil {
                        
                        NSLog("Error: Could not modify the existing \"\(store.name)\" store in CloudKit: \(error?.localizedDescription)")
                        return
                    }
                    
                    if let _ = records {
                        
                        NSLog("Updated \"\(store.name)\" store saved successfully to CloudKit.")
                    }
                })
            }
        } else {
            
            if let completion = completion {
                completion()
            }
        }
    }
    
    func updateStore(record: CKRecord, sourceIsRemoteNotification: Bool = false, completion: (() -> Void)? = nil) {
        
        guard let name = record[StoreCategory.nameKey] as? String
            , let imageAssetData = record[StoreCategory.imageKey] as? CKAsset
            , let image = NSData(contentsOfURL: imageAssetData.fileURL)
            else {
                
                print("Error: Could not extract the required store data from the CloudKit record.")
                return
        }
        
        let recordName = record.recordID.recordName
        var storeCategories = NSOrderedSet()
        if let storeCategoriesReferencesArray = record[Store.categoriesKey] as? [CKReference] {
            
            let storeCategoriesArray = setStoreCategories(storeCategoriesReferencesArray)
            
            storeCategories = NSOrderedSet(array: storeCategoriesArray)
        }
        
        let request = NSFetchRequest(entityName: Store.type)
        let predicate = NSPredicate(format: "recordName = %@", argumentArray: [recordName])
        request.predicate = predicate
        
        let resultsArray = (try? PersistenceController.sharedController.moc.executeFetchRequest(request)) as? [Store]
        guard let existingStore = resultsArray?.first else {
            
            NSLog("Error: Existing StoreCategory could not be found.")
            return
        }
        
        existingStore.categories = storeCategories
        existingStore.image = image
        existingStore.name = name
        existingStore.recordIDData = nil
        
        PersistenceController.sharedController.saveContext()
        
        if sourceIsRemoteNotification == false {
            
            if let storeCloudKitRecord = existingStore.cloudKitRecord {
                
                cloudKitManager.modifyRecords(cloudKitManager.publicDatabase, records: [storeCloudKitRecord], perRecordCompletion: nil, completion: { (records, error) in
                    
                    defer {
                        
                        if let completion = completion {
                            completion()
                        }
                    }
                    
                    if error != nil {
                        
                        NSLog("Error: Could not modify the existing \"\(existingStore.name)\" store in CloudKit: \(error?.localizedDescription)")
                        return
                    }
                    
                    if let _ = records {
                        
                        NSLog("Updated \"\(existingStore.name)\" store saved successfully to CloudKit.")
                    }
                })
                
            }
        } else {
            
            if let completion = completion {
                completion()
            }
        }
    }
    
    func deleteStore(store: Store, sourceIsRemoteNotification: Bool = false, completion: (() -> Void)? = nil) {
        
        if let storeCloudKitRecord = store.cloudKitRecord {
            
            PersistenceController.sharedController.moc.deleteObject(store)
            PersistenceController.sharedController.saveContext()
            
            if sourceIsRemoteNotification == false {
                
                cloudKitManager.deleteRecordWithID(cloudKitManager.privateDatabase, recordID: storeCloudKitRecord.recordID, completion: { (recordID, error) in
                    
                    if let storeName = storeCloudKitRecord[Store.nameKey] {
                        
                        defer {
                            
                            if let completion = completion {
                                completion()
                            }
                        }
                        
                        if error != nil {
                            
                            NSLog("Error: Store \"\(storeName)\" could not be deleted in CloudKit: \(error)")
                            return
                        }
                        
                        if let _ = recordID {
                            
                            print("Store \"\(storeName)\" successfully deleted from CloudKit")
                        }
                    }
                })
            }
        }
    }
    
    //==================================================
    // MARK: - Subscription
    //==================================================
    
    func subscribeToStoresForOptionType(optionType: CKSubscriptionOptions, completion: ((success: Bool, error: NSError?) -> Void)?) {
        
        var optionTypeString: String
        switch optionType {
        case CKSubscriptionOptions.FiresOnRecordCreation: optionTypeString = "New"
        case CKSubscriptionOptions.FiresOnRecordUpdate: optionTypeString = "Updated"
        case CKSubscriptionOptions.FiresOnRecordDeletion: optionTypeString = "Deleted"
        default:
            NSLog("Error: Unsupported CKSubscriptionOption (\(optionType))used for Store.")
            return
        }
        
        let predicate = NSPredicate(value: true)
        let desiredKeys = [Store.nameKey]
        
        cloudKitManager.subscribe(cloudKitManager.privateDatabase, type: Store.type, predicate: predicate, subscriptionID: "all\(optionTypeString)Stores", contentAvailable: true, desiredKeys: desiredKeys, options: optionType) { (subscription, error) in
            
            if error != nil {
                
                NSLog("Error: There was a problem creating the \(optionTypeString.lowercaseString) Store subscription.  \(error!.localizedDescription)")
            }
            
            if let completion = completion {
                
                let success = subscription != nil
                completion(success: success, error: error)
            }
        }
    }
    
    //==================================================
    // MARK: - Methods
    //==================================================
    
    func setStoreCategories(storeCategoriesReferencesArray: [CKReference]) -> [StoreCategory] {
        
        var storeCategoriesArray = [StoreCategory]()
        for storeCategoryReference in storeCategoriesReferencesArray {
            
            let storeCategoryIDName = storeCategoryReference.recordID.recordName
            if let storeCategory = StoreCategoryModelController.sharedController.fetchStoreCategoryByIdName(storeCategoryIDName) {
                
                storeCategoriesArray.append(storeCategory)
            }
        }
        
        return storeCategoriesArray
    }
}




















