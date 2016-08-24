//
//  Store.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/22/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

@objc
class Store: SyncableObject, CloudKitManagedObject {

    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    static let type = "Store"
    static let nameKey = "name"
    static let imageKey = "image"
    static let categoriesKey = "categories"
    static let itemsKey = "items"
    
    var recordType: String { return Store.type }
    
    var cloudKitRecord: CKRecord? {
        
        let recordID = CKRecordID(recordName: self.recordName)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        
        record[Store.nameKey] = self.name
        record[Store.imageKey] = self.image
        
        var categoriesReferencesArray = [CKReference]()
        for category in self.categories {
            
            guard let recordIDData = category.recordIDData
                , recordID = NSKeyedUnarchiver.unarchiveObjectWithData(recordIDData!) as? CKRecordID
                else { continue }
            
            let categoryReference = CKReference(recordID: recordID, action: .DeleteSelf)
            categoriesReferencesArray.append(categoryReference)
        }
        
        record[Store.categoriesKey] = categoriesReferencesArray
        
        var itemsReferencesArray = [CKReference]()
        if let items = self.items {
            
            for item in items {
                
                guard let recordIDData = item.recordIDData
                    , recordID = NSKeyedUnarchiver.unarchiveObjectWithData(recordIDData!) as? CKRecordID
                    else { continue }
                
                let itemReference = CKReference(recordID: recordID, action: .DeleteSelf)
                itemsReferencesArray.append(itemReference)
            }
        }
        
        record[Store.itemsKey] = itemsReferencesArray
        
        return record
    }
    
    //==================================================
    // MARK: - Initializers
    //==================================================

    convenience init?(name: String, image: NSData, categories: [StoreCategory], items: [Item], context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        
        guard let storeEntity = NSEntityDescription.entityForName(Store.type, inManagedObjectContext: context) else { return nil }
        
        self.init(entity: storeEntity, insertIntoManagedObjectContext: context)
        
        self.recordName = nameForManagedObject()
        self.name = name
        self.image = image
        
        let categoriesMutableOrderedSet = NSMutableOrderedSet()
        for category in categories {
            
            categoriesMutableOrderedSet.addObject(category)
        }
        
        self.categories = categoriesMutableOrderedSet.copy() as! NSOrderedSet
        
        let itemsMutableOrderedSet = NSMutableOrderedSet()
        for item in items {
            
            itemsMutableOrderedSet.addObject(item)
        }
        
        self.items = itemsMutableOrderedSet.copy() as? NSOrderedSet
    }
    
    convenience required init?(record: CKRecord, context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        
        guard let name = record[Store.nameKey] as? String
            , image = record[Store.imageKey] as? NSData
            else {
                
                NSLog("Error: Could not create the Store from the CloudKit record.")
                return nil
        }
        
        guard let storeEntity = NSEntityDescription.entityForName(Store.type, inManagedObjectContext: context) else { return nil }
        
        self.init(entity: storeEntity, insertIntoManagedObjectContext: context)
        
        self.name = name
        self.image = image
        
        if let storeCategoriesReferencesArray = record[Store.categoriesKey] as? [CKReference] {
            
            var storeCategoriesArray = [StoreCategory]()
            for storeCategoryReference in storeCategoriesReferencesArray {
                
                let storeCategoryIDName = storeCategoryReference.recordID.recordName
                if let storeCategory = StoreCategoryModelController.sharedController.getStoreCategoryByIdName(storeCategoryIDName) {
                    
                    storeCategoriesArray.append(storeCategory)
                }
            }
            
            self.categories = NSOrderedSet(array: storeCategoriesArray)
        }
        
        if let itemsReferencesArray = record[Store.itemsKey] as? [CKReference] {
            
            var itemsArray = [Item]()
            for itemReference in itemsReferencesArray {
                
                let itemIDName = itemReference.recordID.recordName
                if let item = ItemController.sharedController.getItemByIdName(itemIDName) {
                    
                    itemsArray.append(item)
                }
            }
            
            self.items = NSOrderedSet(array: itemsArray)
        }
    }
}


















