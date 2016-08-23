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


class StoreCategory: SyncableObject, CloudKitManagedObject {

    //==================================================
    // MARK: - Stored Properties
    //==================================================

    static let type = "StoreCategory"
    static let nameKey = "name"
    static let imageKey = "image"
    static let storesKey = "stores"
    
    let name: String
    let image: NSData
    var stores = [Store]()
    
    var recordName: String { return self.recordName }
    
    var cloudKitRecord: CKRecord? {
        
        let recordID = CKRecordID(recordName: self.recordName)
        let record = CKRecord(recordType: StoreCategory.type, recordID: recordID)
        record[StoreCategory.nameKey] = self.name
        record[StoreCategory.imageKey] = self.image
        record[StoreCategory.storesKey] = []
        
        return record
    }
    
    //==================================================
    // MARK: - Initializer(s)
    //==================================================
    
    convenience init(name: String, image: UIImage, context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        
        guard let storeCategoryEntity = NSEntityDescription.entityForName(StoreCategory.type, inManagedObjectContext: context) else { return }
        
        self.init(entity: storeCategoryEntity, insertIntoManagedObjectContext: context)
        
        self.name = name
        self.image = image
    }
}
