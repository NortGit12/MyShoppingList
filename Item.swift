//
//  Item.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/22/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

@objc
class Item: SyncableObject, CloudKitManagedObject {

    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    static let type = "Item"
    static let nameKey = "name"
    static let quantityKey = "quantity"
    static let notesKey = "notes"
    static let storeKey = "store"
    
    var recordType: String { return Item.type }
    
    var cloudKitRecord: CKRecord? {
        
        let recordID = CKRecordID(recordName: self.recordName)
        let record = CKRecord(recordType: Item.type, recordID: recordID)
        
        record[Item.nameKey] = self.name
        record[Item.quantityKey] = self.quantity
        record[Item.notesKey] = self.notes
        
        guard let storeRecordID = NSKeyedUnarchiver.unarchiveObjectWithData(self.store.recordIDData!) as? CKRecordID else { return nil }
        let storeReference = CKReference(recordID: storeRecordID, action: .DeleteSelf)
        record[Item.storeKey] = storeReference
        
        return record
    }

    //==================================================
    // MARK: - Initializers
    //==================================================
    
    convenience init?(name: String, quantity: String, notes: String, store: Store, context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        
        guard let itemEntity = NSEntityDescription.entityForName(Item.type, inManagedObjectContext: context) else { return nil }
        
        self.init(entity: itemEntity, insertIntoManagedObjectContext: context)
        
        self.name = name
        self.quantity = quantity
        self.notes = notes
        self.store = store
    }
    
    convenience required init?(record: CKRecord, context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        
        guard let name = record[Item.nameKey] as? String
            , quantity = record[Item.quantityKey] as? String
            , notes = record[Item.notesKey] as? String
            , storeReference = record[Item.storeKey] as? CKReference
            else {
                
                NSLog("Error: Could not create the Item from the CloudKit record.")
                return nil
        }
        
        guard let itemEntity = NSEntityDescription.entityForName(Item.type, inManagedObjectContext: context) else { return nil }
        
        self.init(entity: itemEntity, insertIntoManagedObjectContext: context)
        
        self.name = name
        self.quantity = quantity
        self.notes = notes
        
        let storeIDName = storeReference.recordID.recordName
        guard let store = StoreModelController.sharedController.getStoreByIdName(storeIDName) else { return nil }
        
        self.store = store
    }
}
