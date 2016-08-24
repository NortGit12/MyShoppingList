//
//  StoreCategory.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/22/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

@objc
class StoreCategory: SyncableObject, CloudKitManagedObject {

    //==================================================
    // MARK: - Stored Properties
    //==================================================

    static let type = "StoreCategory"
    static let nameKey = "name"
    static let imageKey = "image"
    static let storesKey = "stores"
    
    var recordType: String { return StoreCategory.type }
    
    var cloudKitRecord: CKRecord? {
        
        let recordID = CKRecordID(recordName: self.recordName)
        let record = CKRecord(recordType: StoreCategory.type, recordID: recordID)
        
        record[StoreCategory.nameKey] = self.name
        record[StoreCategory.imageKey] = self.image
        
        var storesReferencesArray = [CKReference]()
        if let stores = self.stores {
            
            for store in stores {
                
                guard let recordIDData = store.recordIDData
                    , recordID = NSKeyedUnarchiver.unarchiveObjectWithData(recordIDData!) as? CKRecordID
                    else { continue }
                
                let storeReference = CKReference(recordID: recordID, action: .DeleteSelf)
                storesReferencesArray.append(storeReference)
            }
        }
        
        record[StoreCategory.storesKey] = [storesReferencesArray]
        
        return record
    }
    
    //==================================================
    // MARK: - Initializer(s)
    //==================================================
    
    convenience init?(name: String, image: NSData, stores: [Store] = [Store](), context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {      // stores: [Store] = [Store](),
        
        guard let storeCategoryEntity = NSEntityDescription.entityForName(StoreCategory.type, inManagedObjectContext: context) else {
        
            NSLog("Error: Could not initialize the \(StoreCategory.type)")
            return nil
        }
        
        self.init(entity: storeCategoryEntity, insertIntoManagedObjectContext: context)
        
        self.recordName = nameForManagedObject()
        self.name = name
        self.image = image
        
        let storesMutableOrderedSet = NSMutableOrderedSet()
        for store in stores {
            
            storesMutableOrderedSet.addObject(store)
        }
        
        self.stores = storesMutableOrderedSet.copy() as? NSOrderedSet
    }
    
    convenience required init?(record: CKRecord, context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        
        guard let name = record[StoreCategory.nameKey] as? String
            , image = record[StoreCategory.imageKey] as? NSData
            else {
        
                NSLog("Error: Could not create the Store Category from the CloudKit record.")
                return nil
        }
        
        guard let storeCategoryEntity = NSEntityDescription.entityForName(StoreCategory.type, inManagedObjectContext: context) else { return nil }
        
        self.init(entity: storeCategoryEntity, insertIntoManagedObjectContext: context)
        
        self.recordName = record.recordID.recordName
        self.recordIDData = NSKeyedArchiver.archivedDataWithRootObject(record.recordID)
        self.name = name
        self.image = image
        
//        var storesArray = [Store]()
//        if let storesReferencesArray = record[StoreCategory.storesKey] as? [CKReference] {
//            
//            for storeReference in storesReferencesArray {
//                
//                let storeIDName = storeReference.recordID.recordName
//                if let store = StoreController.sharedController.getStoreByIdName(storeIDName) {
//                    
//                    storesArray.append(store)
//                }
//            }
//            
//            self.stores = NSOrderedSet(array: storesArray)
//        }
    }
}
