//
//  StoreModelController.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/24/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import UIKit
import CoreData

class StoreModelController {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    static let sharedController = StoreModelController()
    let cloudKitManager = CloudKitManager()
    
    //==================================================
    // MARK: - Initializer(s)
    //==================================================
    
    //==================================================
    // MARK: - Methods
    //==================================================
    
    func createStore(name: String, image: UIImage?, categories: [StoreCategory], completion: (() -> Void)? = nil) {
        
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
        
        if let completion = completion {
            
            completion()
        }
        
        if let storeCloudKitRecord = store.cloudKitRecord {
            
            cloudKitManager.saveRecord(cloudKitManager.privateDatabase, record: storeCloudKitRecord, completion: { (record, error) in
            
                if error != nil {
                    
                    NSLog("Error: New Store could not be saved to CloudKit: \(error)")
                }
                
                if let record = record {
                    
                    let moc = PersistenceController.sharedController.moc
                    
                    /*
                     The "...AndWait" makes the subsequent work wait for the performBlock to finish.  By default, the moc.performBlock(...) is asynchronous, so the work in there would be done asynchronously on another thread and the subsequent lines would run immediately.
                     */
                    
                    moc.performBlockAndWait({ store.updateRecordIDData(record) })
                }
            })
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
    
    func updateStore(store: Store, completion: (() -> Void)? = nil) {
        
        let request = NSFetchRequest(entityName: Store.type)
        let predicate = NSPredicate(format: "recordName = %@", argumentArray: [store.recordName])
        request.predicate = predicate
        
        let resultsArray = (try? PersistenceController.sharedController.moc.executeFetchRequest(request)) as? [Store]
        let existingStore = resultsArray?.first
        
        existingStore?.name = store.name
        existingStore?.image = store.image
        existingStore?.categories = store.categories
        
        PersistenceController.sharedController.saveContext()
        
        if let completion = completion {
            completion()
        }
        
        if let storeCloudKitRecord = store.cloudKitRecord {
            
            cloudKitManager.modifyRecords(cloudKitManager.privateDatabase, records: [storeCloudKitRecord], perRecordCompletion: nil, completion: { (records, error) in
            
                if error != nil {
                    
                    NSLog("Error: Could not modify the existing \"\(store.name)\" store in CloudKit: \(error?.localizedDescription)")
                    
                    if let completion = completion {
                        completion()
                    }
                }
                
                if let _ = records {
                    
                    NSLog("Updated \"\(store.name)\" store saved successfully to CloudKit.")
                }
            })
            
        }
    }
    
    func deleteStore(store: Store, completion: (() -> Void)? = nil) {
        
        if let storeCloudKitRecord = store.cloudKitRecord {
            
            cloudKitManager.deleteRecordWithID(cloudKitManager.privateDatabase, recordID: storeCloudKitRecord.recordID, completion: { (recordID, error) in
            
                if error != nil {
                    
                    NSLog("Error: Store could not be deleted in CloudKit: \(error)")
                }
                
                if let _ = recordID {
                    
                    print("Store \"\(store.name)\" successfully deleted \"\(store.name)\" from CloudKit")
                }
                
                PersistenceController.sharedController.moc.deleteObject(store)
                
                PersistenceController.sharedController.saveContext()
                
                if let completion = completion {
                    
                    completion()
                }
            })
        }
    }
}




















