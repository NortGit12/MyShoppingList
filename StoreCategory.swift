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
    static let imageKey = "categoryImage"
    static let imageFlatKey = "categoryImageFlat"
    static let storesKey = "stores"
    
    var recordType: String { return StoreCategory.type }
    
    lazy var temporaryImageURL: NSURL = {
        
        // Must write to temporary directory to be able to pass image file path URL to CKAsset
        
        let temporaryDirectory = NSTemporaryDirectory()
        let temporaryDirectoryURL = NSURL(fileURLWithPath: temporaryDirectory)
        let fileURL = temporaryDirectoryURL.URLByAppendingPathComponent(self.recordName).URLByAppendingPathExtension("jpg")
        
        self.image.writeToURL(fileURL, atomically: true)
        
        return fileURL
    }()
    
    lazy var temporaryFlatImageURL: NSURL = {
        
        // Must write to temporary directory to be able to pass image file path URL to CKAsset
        
        let temporaryDirectory = NSTemporaryDirectory()
        let temporaryDirectoryURL = NSURL(fileURLWithPath: temporaryDirectory)
        let fileURL = temporaryDirectoryURL.URLByAppendingPathComponent(self.recordName).URLByAppendingPathExtension("jpg")
        
        self.image_flat.writeToURL(fileURL, atomically: true)
        
        return fileURL
    }()
    
    var cloudKitRecord: CKRecord? {
        
        let recordID = CKRecordID(recordName: self.recordName)
        let record = CKRecord(recordType: StoreCategory.type, recordID: recordID)
        
        record[StoreCategory.nameKey] = self.name
        record[StoreCategory.imageKey] = CKAsset(fileURL: self.temporaryImageURL)
        record[StoreCategory.imageFlatKey] = CKAsset(fileURL: self.temporaryFlatImageURL)
        
        var storesReferencesArray = [CKReference]()
        if self.stores?.count > 0 {
            
            if let stores = self.stores {
                
                for store in stores {
                    
                    guard let recordIDData = store.recordIDData
                        , recordID = NSKeyedUnarchiver.unarchiveObjectWithData(recordIDData!) as? CKRecordID
                        else { continue }
                    
                    let storeReference = CKReference(recordID: recordID, action: .DeleteSelf)
                    storesReferencesArray.append(storeReference)
                }
                
                record[StoreCategory.storesKey] = [storesReferencesArray]
            }
        }
        
        return record
    }
    
    //==================================================
    // MARK: - Initializer(s)
    //==================================================
    
    convenience init?(name: String, image: NSData, imageFlat: NSData, stores: [Store]?, context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {      // stores: [Store] = [Store](),
        
        guard let storeCategoryEntity = NSEntityDescription.entityForName(StoreCategory.type, inManagedObjectContext: context) else {
        
            NSLog("Error: Could not create the entity description for a \(StoreCategory.type).")
            return nil
        }
        
        self.init(entity: storeCategoryEntity, insertIntoManagedObjectContext: context)
        
        self.recordName = nameForManagedObject()
        self.name = name
        self.image = image
        self.image_flat = imageFlat
    }
    
    convenience required init?(record: CKRecord, context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        
        guard let name = record[StoreCategory.nameKey] as? String
            , imageAssetData = record[StoreCategory.imageKey] as? CKAsset
            , imageData = NSData(contentsOfURL: imageAssetData.fileURL)
            , imageFlatAssetData = record[StoreCategory.imageFlatKey] as? CKAsset
            , imageFlatData = NSData(contentsOfURL: imageFlatAssetData.fileURL)
            else {
        
                NSLog("Error: Could not create the Store Category from the CloudKit record.")
                return nil
        }
        
        guard let storeCategoryEntity = NSEntityDescription.entityForName(StoreCategory.type, inManagedObjectContext: context) else { return nil }
        
        self.init(entity: storeCategoryEntity, insertIntoManagedObjectContext: context)
        
        self.recordName = record.recordID.recordName
        self.recordIDData = NSKeyedArchiver.archivedDataWithRootObject(record.recordID)
        self.name = name
        self.image = imageData
        self.image_flat = imageFlatData
    }
}
