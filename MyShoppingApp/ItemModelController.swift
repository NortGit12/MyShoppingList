//
//  ItemModelController.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/24/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import Foundation
import CoreData

class ItemModelController {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    static let sharedController = ItemModelController()
    let cloudKitManager = CloudKitManager()
    
    //==================================================
    // MARK: - Initializer(s)
    //==================================================
    
    
    
    //==================================================
    // MARK: - Methods
    //==================================================
    
    func createItem(name: String, quantity: String, notes: String?, store: Store, completion: (() -> Void)? = nil) {
        
        guard let item = Item(name: name, quantity: quantity, notes: (notes ?? nil)!, store: store) else { return }
        
        PersistenceController.sharedController.saveContext()
        
        if let completion = completion {
            
            completion()
        }
        
        if let itemCloudKitRecord = item.cloudKitRecord {
            
            cloudKitManager.saveRecord(itemCloudKitRecord, completion: { (record, error) in
                
                if error != nil {
                    
                    NSLog("Error: New Item could not be saved to CloudKit: \(error)")
                }
                
                if let record = record {
                    
                    let moc = PersistenceController.sharedController.moc
                    
                    /*
                     The "...AndWait" makes the subsequent work wait for the performBlock to finish.  By default, the mockPerformBlock(...) is asynchronous, so the work in there would be done asynchronously on another thread and the subsequent lines would run immediately.
                     */
                    
                    moc.performBlockAndWait({ item.updateRecordIDData(record) })
                }
            })
        }
    }
    
    func getItemByIdName(idName: String) -> Item? {
        
        if idName.isEmpty { return nil }
        
        let request = NSFetchRequest(entityName: Item.type)
        let predicate = NSPredicate(format: "recordName  == %@", argumentArray: [idName])
        request.predicate = predicate
        
        let resultsArray = (try? PersistenceController.sharedController.moc.executeFetchRequest(request)) as? [Item]
        
        return resultsArray?.first ?? nil
    }
    
    func getItemsForStore(store: Store) -> [Item]? {
        
        let storeIdName = store.recordName
        
        let request = NSFetchRequest(entityName: Item.type)
        let predicate = NSPredicate(format: "store.recordName == %@", argumentArray: [storeIdName])
        request.predicate = predicate
        
        return (try? PersistenceController.sharedController.moc.executeFetchRequest(request)) as? [Item] ?? nil
    }
}





















