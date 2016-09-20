//
//  ItemModelController.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/24/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

class ItemModelController {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    static let sharedController = ItemModelController()
    let cloudKitManager = CloudKitManager()
    
    //==================================================
    // MARK: - Methods
    //==================================================
    
    func createItem(name: String, quantity: String, notes: String?, store: Store, sourceIsRemoteNotification: Bool = false, completion: (() -> Void)? = nil) {
        
        guard let item = Item(name: name, quantity: quantity, notes: notes, store: store) else {
            
            NSLog("Error: Could not create a new Store instance.")
            return
        }
        
        PersistenceController.sharedController.saveContext()
        
        if sourceIsRemoteNotification == false {
            
            if let itemCloudKitRecord = item.cloudKitRecord {
                
                cloudKitManager.saveRecord(cloudKitManager.privateDatabase, record: itemCloudKitRecord, completion: { (record, error) in
                    
                    defer {
                        
                        if let completion = completion {
                            completion()
                        }
                    }
                    
                    if error != nil {
                        
                        NSLog("Error: New Item \"\(item.name)\" could not be saved to CloudKit: \(error?.localizedDescription)")
                        return
                    }
                    
                    if let record = record {
                        
                        let moc = PersistenceController.sharedController.moc
                        
                        /*
                         The "...AndWait" makes the subsequent work wait for the performBlock to finish.  By default, the mockPerformBlock(...) is asynchronous, so the work in there would be done asynchronously on another thread and the subsequent lines would run immediately.
                         */
                        
                        moc.performBlockAndWait({
                            
                            item.updateRecordIDData(record)
                            NSLog("New Item \"\(item.name)\" successfully saved to CloudKit.")
                        })
                    }
                })
            }
        }
    }
    
    func fetchItemByIdName(idName: String) -> Item? {
        
        if idName.isEmpty { return nil }
        
        let request = NSFetchRequest(entityName: Item.type)
        let predicate = NSPredicate(format: "recordName  == %@", argumentArray: [idName])
        request.predicate = predicate
        
        let resultsArray = (try? PersistenceController.sharedController.moc.executeFetchRequest(request)) as? [Item]
        
        return resultsArray?.first ?? nil
    }
    
    func fetchItemsForStore(store: Store) -> [Item]? {
        
        let storeIdName = store.recordName
        
        let request = NSFetchRequest(entityName: Item.type)
        let predicate = NSPredicate(format: "store.recordName == %@", argumentArray: [storeIdName])
        request.predicate = predicate
        
        var resultsArray = (try? PersistenceController.sharedController.moc.executeFetchRequest(request)) as? [Item]
        resultsArray?.sortInPlace({ $0.name < $1.name })
        
        return resultsArray ?? nil
    }
    
    func updateItem(item: Item, sourceIsRemoteNotification: Bool = false, completion: (() -> Void)? = nil) {
        
        let request = NSFetchRequest(entityName: Item.type)
        let predicate = NSPredicate(format: "recordName = %@", argumentArray: [item.recordName])
        request.predicate = predicate
        
        let resultsArray = (try? PersistenceController.sharedController.moc.executeFetchRequest(request)) as? [Item]
        let existingItem = resultsArray?.first
        
        existingItem?.name = item.name
        existingItem?.quantity = item.quantity
        existingItem?.notes = item.notes
        
        PersistenceController.sharedController.saveContext()
        
        if sourceIsRemoteNotification == false {
            
            if let itemCloudKitRecord = item.cloudKitRecord {
                
                cloudKitManager.modifyRecords(cloudKitManager.privateDatabase, records: [itemCloudKitRecord], perRecordCompletion: nil, completion: { (records, error) in
                    
                    defer {
                        
                        if let completion = completion {
                            completion()
                        }
                    }
                    
                    if error != nil {
                        
                        NSLog("Error: Could not modify the existing \"\(item.name)\" item in CloudKit: \(error?.localizedDescription)")
                        return
                    }
                    
                    if let _ = records {
                        
                        NSLog("Updated \"\(item.name)\" item saved successfully to CloudKit.")
                    }
                })
                
            }
        } else {
            
            if let completion = completion {
                completion()
            }
        }
    }
    
    func updateItem(record: CKRecord, sourceIsRemoteNotification: Bool = false, completion: (() -> Void)? = nil) {
        
        guard let name = record[Item.nameKey] as? String
            , let quantity = record[Item.quantityKey] as? String
            , let notes = record[Item.notesKey] as? String
            , let storeReference = record[Item.storeKey] as? CKReference
            else {
                
                print("Error: Could not extract the required item data from the CloudKit record.")
                return
        }
        
        let recordName = record.recordID.recordName
        
        let storeIDName = storeReference.recordID.recordName
        guard let store = StoreModelController.sharedController.fetchStoreByIdName(storeIDName) else {
            
            NSLog("Error: Could not identify the item's store by its ID name \"\(storeIDName)\".")
            return
        }
        
        let request = NSFetchRequest(entityName: Item.type)
        let predicate = NSPredicate(format: "recordName = %@", argumentArray: [recordName])
        request.predicate = predicate
        
        let resultsArray = (try? PersistenceController.sharedController.moc.executeFetchRequest(request)) as? [Item]
        guard let existingItem = resultsArray?.first else {
            
            NSLog("Error: Existing StoreCategory could not be found.")
            return
        }
        
        existingItem.name = name
        existingItem.notes = notes
        existingItem.quantity = quantity
        existingItem.recordIDData = nil
        existingItem.store = store
        
        PersistenceController.sharedController.saveContext()
        
        if sourceIsRemoteNotification == false {
            
            if let itemCloudKitRecord = existingItem.cloudKitRecord {
                
                cloudKitManager.modifyRecords(cloudKitManager.publicDatabase, records: [itemCloudKitRecord], perRecordCompletion: nil, completion: { (records, error) in
                    
                    defer {
                        
                        if let completion = completion {
                            completion()
                        }
                    }
                    
                    if error != nil {
                        
                        NSLog("Error: Could not modify the existing \"\(existingItem.name)\" item in CloudKit: \(error?.localizedDescription)")
                        return
                    }
                    
                    if let _ = records {
                        
                        NSLog("Updated \"\(existingItem.name)\" item saved successfully to CloudKit.")
                    }
                })
                
            }
        } else {
            
            if let completion = completion {
                completion()
            }
        }
    }
    
    func deleteItem(item: Item, sourceIsRemoteNotification: Bool = false, completion: (() -> Void)? = nil) {
        
        if let itemCloudKitRecord = item.cloudKitRecord {
            
            PersistenceController.sharedController.moc.deleteObject(item)
            PersistenceController.sharedController.saveContext()
            
            if sourceIsRemoteNotification == false {
                
                
                cloudKitManager.deleteRecordWithID(cloudKitManager.privateDatabase, recordID: itemCloudKitRecord.recordID, completion: { (recordID, error) in
                    
                    if let itemName = itemCloudKitRecord[Item.nameKey] {
                        
                        defer {
                            
                            if let completion = completion {
                                completion()
                            }
                        }
                        
                        if error != nil {
                            
                            NSLog("Error: Item \"\(itemName)\" could not be deleted in CloudKit: \(error)")
                            return
                        }
                        
                        if let _ = recordID {
                            
                            print("Item \"\(itemName)\" successfully deleted from CloudKit")
                        }
                    }
                })
            }
        }

    }
    
    //==================================================
    // MARK: - Subscription
    //==================================================
    
    func subscribeToItemsForOptionType(optionType: CKSubscriptionOptions, completion: ((success: Bool, error: NSError?) -> Void)?) {
        
        var optionTypeString: String
        switch optionType {
        case CKSubscriptionOptions.FiresOnRecordCreation: optionTypeString = "New"
        case CKSubscriptionOptions.FiresOnRecordUpdate: optionTypeString = "Updated"
        case CKSubscriptionOptions.FiresOnRecordDeletion: optionTypeString = "Deleted"
        default:
            NSLog("Error: Unsupported CKSubscriptionOption (\(optionType))used for Item.")
            return
        }
        
        let predicate = NSPredicate(value: true)
        let desiredKeys = [Item.nameKey, Item.quantityKey, Item.notesKey, Item.storeKey]
        
        cloudKitManager.subscribe(cloudKitManager.privateDatabase, type: Item.type, predicate: predicate, subscriptionID: "all\(optionTypeString)Items", contentAvailable: true, desiredKeys: desiredKeys, options: optionType) { (subscription, error) in
            
            if error != nil {
                
                NSLog("Error: There was a problem creating the \(optionTypeString.lowercaseString) Item subscription.  \(error!.localizedDescription)")
            }
            
            if let completion = completion {
                
                let success = subscription != nil
                completion(success: success, error: error)
            }
        }
    }
}





















