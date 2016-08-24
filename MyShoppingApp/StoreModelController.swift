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
    
    func createStore(name: String, image: UIImage, categories: [StoreCategory], completion: (() -> Void)? = nil) {
        
        guard let imageData = UIImagePNGRepresentation(image)
            , store = Store(name: name, image: imageData, categories: categories)
            else { return }
        
        PersistenceController.sharedController.saveContext()
        
        if let completion = completion {
            
            completion()
        }
        
        if let storeCloudKitRecord = store.cloudKitRecord {
            
            cloudKitManager.saveRecord(storeCloudKitRecord, completion: { (record, error) in
                
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
    
    func getStoreByIdName(idName: String) -> Store? {
        
        if idName.isEmpty { return nil }
        
        let request = NSFetchRequest(entityName: Store.type)
        let predicate = NSPredicate(format: "recordName == %@", argumentArray: [idName])
        request.predicate = predicate
        
        let resultsArray = (try? PersistenceController.sharedController.moc.executeFetchRequest(request)) as? [Store]
        
        return resultsArray?.first ?? nil
    }
    
    func getStores() -> [Store]? {
        
        let request = NSFetchRequest(entityName: Store.type)
        let predicate = NSPredicate(value: true)
        request.predicate = predicate
        
        return (try? PersistenceController.sharedController.moc.executeFetchRequest(request)) as? [Store] ?? nil
    }
}



















