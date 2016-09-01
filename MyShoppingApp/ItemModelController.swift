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
        
        guard let item = Item(name: name, quantity: quantity, notes: notes, store: store) else { return }
        
        PersistenceController.sharedController.saveContext()
        
        if let completion = completion {
            
            completion()
        }
        
        if let itemCloudKitRecord = item.cloudKitRecord {
            
            cloudKitManager.saveRecord(itemCloudKitRecord, completion: { (record, error) in
                
                if error != nil {
                    
                    NSLog("Error: New Item could not be saved to CloudKit: \(error?.localizedDescription)")
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
        
        var resultsArray = (try? PersistenceController.sharedController.moc.executeFetchRequest(request)) as? [Item]
        resultsArray?.sortInPlace({ $0.name < $1.name })
        
        return resultsArray ?? nil
    }
    
    func updateItem(item: Item, store: Store, completion: (() -> Void)? = nil) {
        
        guard let notes = item.notes
            else { return }
        
        let request = NSFetchRequest(entityName: Item.type)
        let predicate = NSPredicate(format: "recordName = %@", argumentArray: [item.recordName])
        request.predicate = predicate
        
        let resultsArray = (try? PersistenceController.sharedController.moc.executeFetchRequest(request)) as? [Item]
        let existingItem = resultsArray?.first
        
        existingItem?.name = item.name
        existingItem?.quantity = item.quantity
        existingItem?.notes = notes
        
        PersistenceController.sharedController.saveContext()
        
        if let completion = completion {
            completion()
        }
        
        if let itemCloudKitRecord = item.cloudKitRecord {
        
            cloudKitManager.modifyRecord(itemCloudKitRecord, completion: { (record, error) in
                
                if error != nil {
                    NSLog("Error: Could not modify an existing item in CloudKit: \(error?.localizedDescription)")
                }
                
                if let record = record {
                    NSLog("Updated item save successfully to CloudKit.")
                }
            })
        }
    }
    
    func deleteItem(item: Item, store: Store, completion: (() -> Void)? = nil) {
        
        if let itemCloudKitRecord = item.cloudKitRecord {
            
            cloudKitManager.deleteRecordWithID(itemCloudKitRecord.recordID, completion: { (recordID, error) in
                
                if error != nil {
                    
                    NSLog("Error: Item could not be deleted in CloudKit: \(error)")
                }
                
                if let recordID = recordID {
                    
                    print("Item with the ID of \"\(recordID)\" successfully deleted from CloudKit")
                }
                
                PersistenceController.sharedController.moc.deleteObject(item)
                
                PersistenceController.sharedController.saveContext()
                
                if let completion = completion {
                    
                    completion()
                }
            })
        }
    }
}





















