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
    static let imageKey = "storeImage"
    static let categoriesKey = "categories"
    static let itemsKey = "items"
    
    var recordType: String { return Store.type }
    
    lazy var temporaryImageURL: NSURL = {
        
        // Must write to temporary directory to be able to pass image file path URL to CKAsset
        
        let temporaryDirectory = NSTemporaryDirectory()
        let temporaryDirectoryURL = NSURL(fileURLWithPath: temporaryDirectory)
        let fileURL = temporaryDirectoryURL.URLByAppendingPathComponent(self.recordName)!.URLByAppendingPathExtension("jpg")
        
        self.image.writeToURL(fileURL!, atomically: true)
        
        return fileURL!
    }()
    
    var cloudKitRecord: CKRecord? {
        
        let recordID = CKRecordID(recordName: self.recordName)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        
        record[Store.nameKey] = self.name
        record[Store.imageKey] = CKAsset(fileURL: self.temporaryImageURL)
        
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
        if self.storeItems?.count > 0 {
            
            if let items = self.storeItems {
                
                for item in items {
                    
                    guard let recordIDData = item.recordIDData
                        , recordID = NSKeyedUnarchiver.unarchiveObjectWithData(recordIDData!) as? CKRecordID
                        else { continue }
                    
                    let itemReference = CKReference(recordID: recordID, action: .DeleteSelf)
                    itemsReferencesArray.append(itemReference)
                }
                
                record[Store.itemsKey] = itemsReferencesArray
            }
        }
        
        return record
    }
    
    //==================================================
    // MARK: - Initializers
    //==================================================

    convenience init?(name: String, image: NSData, categories: [StoreCategory], items: [Item]?, context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        
        guard let storeEntity = NSEntityDescription.entityForName(Store.type, inManagedObjectContext: context) else {
            
            NSLog("Error: Could not create the entity description for a \(Store.type).")
            return nil
        }
        
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
        if let items = items {
            
            for item in items {
                
                itemsMutableOrderedSet.addObject(item)
            }
            
            self.storeItems = itemsMutableOrderedSet.copy() as? NSOrderedSet
        }
    }
    
    convenience required init?(record: CKRecord, context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        
        guard let name = record[Store.nameKey] as? String
            , imageAssetData = record[Store.imageKey] as? CKAsset
            , imageData = NSData(contentsOfURL: imageAssetData.fileURL)
            else {
                
                NSLog("Error: Could not create the Store from the CloudKit record.")
                return nil
        }
        
        guard let storeEntity = NSEntityDescription.entityForName(Store.type, inManagedObjectContext: context) else {
            
            NSLog("Error: Could not create the entity description for an \(Store.type).")
            return nil
        }
        
        self.init(entity: storeEntity, insertIntoManagedObjectContext: context)
        
        self.recordName = record.recordID.recordName
        self.recordIDData = NSKeyedArchiver.archivedDataWithRootObject(record.recordID)
        self.name = name
        self.image = imageData
        
        if let storeCategoriesReferencesArray = record[Store.categoriesKey] as? [CKReference] {
            
            let storeCategoriesArray = setStoreCategories(storeCategoriesReferencesArray)
            
            self.categories = NSOrderedSet(array: storeCategoriesArray)
        }
        
        if let itemsReferencesArray = record[Store.itemsKey] as? [CKReference] {
            
            let itemsArray = setItems(itemsReferencesArray)
            
            self.storeItems = NSOrderedSet(array: itemsArray)
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
    
    func setItems(itemsReferencesArray: [CKReference]) -> [Item] {
        
        var itemsArray = [Item]()
        for itemReference in itemsReferencesArray {
            
            let itemIDName = itemReference.recordID.recordName
            if let item = ItemModelController.sharedController.fetchItemByIdName(itemIDName) {
                
                itemsArray.append(item)
            }
        }
        
        return itemsArray
    }
}


















