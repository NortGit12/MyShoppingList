//
//  StoreCategoryModelController.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/23/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

class StoreCategoryModelController {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    static let sharedController = StoreCategoryModelController()
    let cloudKitManager = CloudKitManager()
    var storeCategories = [StoreCategory]()
    static let defaultStoreCategoryName = "Grocery"
    
    //==================================================
    // MARK: - Initializer(s)
    //==================================================
    
    init() {
        
        // Run createMockData() to populate the StoreCategories
//        createMockData()
    }
    
    //==================================================
    // MARK: - Method(s)
    //==================================================
    
    func createStoreCategory(name: String, image: UIImage, imageFlat: UIImage, sourceIsRemoteNotification: Bool = false, completion: (() -> Void)? = nil) {
        
        guard let imageData = UIImagePNGRepresentation(image)
            , imageFlatData = UIImagePNGRepresentation(imageFlat)
            , storeCategory = StoreCategory(name: name, image: imageData, imageFlat: imageFlatData, stores: nil)
            else {
                
                NSLog("Error: Could not either access the image data or create a new StoreCategory.")
                return
            }
        
        PersistenceController.sharedController.saveContext()
        
        if sourceIsRemoteNotification == false {
            
            if let storeCategoryCloudKitRecord = storeCategory.cloudKitRecord {
                
                cloudKitManager.saveRecord(cloudKitManager.publicDatabase, record: storeCategoryCloudKitRecord, completion: { (record, error) in
                    
                    defer {
                        
                        if let completion = completion {
                            completion()
                        }
                    }
                    
                    if error != nil {
                        
                        NSLog("Error: New Store Category \"\(storeCategory.name)\" could not be saved to CloudKit: \(error)")
                        return
                    }
                    
                    if let record = record {
                        
                        let moc = PersistenceController.sharedController.moc
                        
                        /*
                         The "...AndWait" makes the subsequent work wait for the performBlock to finish.  By default, the moc.performBlock(...) is asynchronous, so the work in there would be done asynchronously on another thread and the subsequent lines would run immediately.
                         */
                        
                        moc.performBlockAndWait({
                            
                            storeCategory.updateRecordIDData(record)
                            NSLog("New Store Category \"\(storeCategory.name)\" successfully saved to CloudKit.")
                        })
                    }
                })
            }
        }
    }
    
    func fetchStoreCategoryByIdName(idName: String) -> StoreCategory? {
        
        if idName.isEmpty { return nil }
        
        let request = NSFetchRequest(entityName: StoreCategory.type)
        let predicate = NSPredicate(format: "recordName == %@", argumentArray: [idName])
        request.predicate = predicate
        
        let resultsArray = (try? PersistenceController.sharedController.moc.executeFetchRequest(request)) as? [StoreCategory] ?? nil
        
        return resultsArray?.first
    }
    
    func fetchStoreCategoryByName(name: String) -> StoreCategory? {
        
        if name.isEmpty { return nil }
        
        let request = NSFetchRequest(entityName: StoreCategory.type)
        let predicate = NSPredicate(format: "name == %@", argumentArray: [name])
        request.predicate = predicate
        
        let resultsArray = (try? PersistenceController.sharedController.moc.executeFetchRequest(request)) as? [StoreCategory] ?? nil
        
        return resultsArray?.first
    }
    
    func fetchStoreCategories() -> [StoreCategory]? {
    
        let request = NSFetchRequest(entityName: StoreCategory.type)
        let predicate = NSPredicate(value: true)
        request.predicate = predicate
        
        var resultsArray = [StoreCategory]()
        do {
            if let tempResultsArray = try PersistenceController.sharedController.moc.executeFetchRequest(request) as? [StoreCategory] {
                resultsArray = tempResultsArray
            }
        } catch let error as NSError {
            NSLog("Error: Troublems.  \(error.localizedDescription)")
        }
        
        resultsArray.sortInPlace({ $0.0.name < $0.1.name })
        
        return resultsArray
    }
    
    func fetchStoresForStoreCategory(storeCategory: StoreCategory) -> [Store]? {
        
        guard let storesSet = storeCategory.stores
            , storesArray = Array(storesSet) as? [Store]
            else {
            
                NSLog("Error: Could not either unwrap the set of Stores or convert it to an Array of Stores.")
                return nil
            }
        
        let sortedStoresArray = storesArray.sort({ $0.0.name < $0.1.name })
        
        return sortedStoresArray
    }
    
    func updateStoreCategory(storeCategory: StoreCategory, sourceIsRemoteNotification: Bool = false, completion: (() -> Void)? = nil) {
        
        let request = NSFetchRequest(entityName: StoreCategory.type)
        let predicate = NSPredicate(format: "recordName = %@", argumentArray: [storeCategory.recordName])
        request.predicate = predicate
        
        let resultsArray = (try? PersistenceController.sharedController.moc.executeFetchRequest(request)) as? [StoreCategory]
        guard let existingStoreCategory = resultsArray?.first else {
            
            NSLog("Error: Existing StoreCategory could not be found.")
            return
        }
        
        existingStoreCategory.name = storeCategory.name
        existingStoreCategory.image = storeCategory.image
        existingStoreCategory.image_flat = storeCategory.image_flat
        existingStoreCategory.stores = storeCategory.stores
        
        PersistenceController.sharedController.saveContext()
        
        if sourceIsRemoteNotification == false {
            
            if let storeCategoryCloudKitRecord = storeCategory.cloudKitRecord {
                
                cloudKitManager.modifyRecords(cloudKitManager.publicDatabase, records: [storeCategoryCloudKitRecord], perRecordCompletion: nil, completion: { (records, error) in
                    
                    defer {
                        
                        if let completion = completion {
                            completion()
                        }
                    }
                    
                    if error != nil {
                        
                        NSLog("Error: Could not modify the existing \"\(storeCategory.name)\" store category in CloudKit: \(error?.localizedDescription)")
                        return
                    }
                    
                    if let _ = records {
                        
                        NSLog("Updated \"\(storeCategory.name)\" store category saved successfully to CloudKit.")
                    }
                })
                
            }
        } else {
            
            if let completion = completion {
                completion()
            }
        }
    }
    
    func updateStoreCategory(record: CKRecord, sourceIsRemoteNotification: Bool = false, completion: (() -> Void)? = nil) {
        
        guard let name = record[StoreCategory.nameKey] as? String
            , let imageAssetData = record[StoreCategory.imageKey] as? CKAsset
            , let image = NSData(contentsOfURL: imageAssetData.fileURL)
            , let image_flatData = record[StoreCategory.imageFlatKey] as? CKAsset
            , let image_flat = NSData(contentsOfURL: image_flatData.fileURL)
            else {
                
                print("Error: Could not extract the required store category data from the CloudKit record.")
                return
            }
        
        let recordName = record.recordID.recordName
        var stores = NSOrderedSet()
        if let storesReferences = record[StoreCategory.storesKey] as? [CKReference] {
            
            let storesArray = setStores(storesReferences)
            stores = NSOrderedSet(array: storesArray)
        }
        
        let request = NSFetchRequest(entityName: StoreCategory.type)
        let predicate = NSPredicate(format: "recordName = %@", argumentArray: [recordName])
        request.predicate = predicate
        
        let resultsArray = (try? PersistenceController.sharedController.moc.executeFetchRequest(request)) as? [StoreCategory]
        guard let existingStoreCategory = resultsArray?.first else {
            
            NSLog("Error: Existing StoreCategory could not be found.")
            return
        }
        
        existingStoreCategory.name = name
        existingStoreCategory.image = image
        existingStoreCategory.image_flat = image_flat
        existingStoreCategory.stores = stores
        
        PersistenceController.sharedController.saveContext()
        
        if sourceIsRemoteNotification == false {
            
            if let storeCategoryCloudKitRecord = existingStoreCategory.cloudKitRecord {
                
                cloudKitManager.modifyRecords(cloudKitManager.publicDatabase, records: [storeCategoryCloudKitRecord], perRecordCompletion: nil, completion: { (records, error) in
                    
                    defer {
                        
                        if let completion = completion {
                            completion()
                        }
                    }
                    
                    if error != nil {
                        
                        NSLog("Error: Could not modify the existing \"\(existingStoreCategory.name)\" store category in CloudKit: \(error?.localizedDescription)")
                        return
                    }
                    
                    if let _ = records {
                        
                        NSLog("Updated \"\(existingStoreCategory.name)\" store category saved successfully to CloudKit.")
                    }
                })
                
            }
        } else {
            
            if let completion = completion {
                completion()
            }
        }
    }
    
    //==================================================
    // MARK: - Subscription
    //==================================================
    
    func subscribeToStoreCategoriesForOptionType(optionType: CKSubscriptionOptions, completion: ((success: Bool, error: NSError?) -> Void)?) {
        
        var optionTypeString: String
        switch optionType {
        case CKSubscriptionOptions.FiresOnRecordCreation: optionTypeString = "New"
        case CKSubscriptionOptions.FiresOnRecordUpdate: optionTypeString = "Updated"
        case CKSubscriptionOptions.FiresOnRecordDeletion: optionTypeString = "Deleted"
        default:
            NSLog("Error: Unsupported CKSubscriptionOption (\(optionType))used for StoreCategory.")
            return
        }
        
        let predicate = NSPredicate(value: true)
        let desiredKeys = [StoreCategory.nameKey]
        
        cloudKitManager.subscribe(cloudKitManager.publicDatabase, type: StoreCategory.type, predicate: predicate, subscriptionID: "all\(optionTypeString)StoreCategories", contentAvailable: true, desiredKeys: desiredKeys, options: optionType) { (subscription, error) in
            
            if error != nil {
                
                NSLog("Error: There was a problem creating the \(optionTypeString.lowercaseString) StoreCategory subscription.  \(error!.localizedDescription)")
            }
            
            if let completion = completion {
                
                let success = subscription != nil
                completion(success: success, error: error)
            }
        }
    }
    
    //==================================================
    // MARK: - Other
    //==================================================
    
    func setStores(storesReferences: [CKReference]) -> [Store] {
        
        var storesArray = [Store]()
        for storeReference in storesReferences {
            
            let storeIDName = storeReference.recordID.recordName
            if let store = StoreModelController.sharedController.fetchStoreByIdName(storeIDName) {
                
                storesArray.append(store)
            }
        }
        
        return storesArray
    }
    
    func createMockData() {
        
        createStoreCategory("Cars", image: UIImage(named: "cars")!, imageFlat: UIImage(named: "cars_flat")!)
        createStoreCategory("Clothing", image: UIImage(named: "clothing")!, imageFlat: UIImage(named: "clothing_flat")!)
        createStoreCategory("Department", image: UIImage(named: "department-store")!, imageFlat: UIImage(named: "department-store_flat")!)
        createStoreCategory("Electronics", image: UIImage(named: "electronics")!, imageFlat: UIImage(named: "electronics_flat")!)
        createStoreCategory("Grocery", image: UIImage(named: "groceries")!, imageFlat: UIImage(named: "groceries_flat")!)
        createStoreCategory("Health & Beauty", image: UIImage(named: "health-and-beauty")!, imageFlat: UIImage(named: "health-and-beauty_flat")!)
        createStoreCategory("Home Improvement", image: UIImage(named: "home-improvement")!, imageFlat: UIImage(named: "home-improvement_flat")!)
        createStoreCategory("Misc", image: UIImage(named: "misc")!, imageFlat: UIImage(named: "misc_flat")!)
        createStoreCategory("Office Supply", image: UIImage(named: "office-supply")!, imageFlat: UIImage(named: "office-supply_flat")!)
        createStoreCategory("Pet", image: UIImage(named: "pet")!, imageFlat: UIImage(named: "pet_flat")!)
    }
}
