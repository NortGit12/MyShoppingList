//
//  CloudKitManagedObject.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/22/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

@objc
protocol CloudKitManagedObject {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    // In the Core Data SyncableObject to support syncing, so it's childen get it
    var recordIDData: NSData? { get set }
    var recordName: String { get set }
    
    // In Core Data entities
    /*
     The recordType is not stored in Core Data because it's always the String of the type for all instances of them
    */
    var recordType: String { get }
    
    var cloudKitRecord: CKRecord? { get }
    
    //==================================================
    // MARK: - Initializer(s)
    //==================================================
    
    init?(record: CKRecord, context: NSManagedObjectContext)
    
}

extension CloudKitManagedObject {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    var isSynced: Bool { return recordIDData != nil }
    
    var cloudKitRecordID: CKRecordID? {
        
        guard let recordIDData = recordIDData else { return nil }
        
        return NSKeyedUnarchiver.unarchiveObjectWithData(recordIDData) as? CKRecordID
    }
    
    var cloudKitReference: CKReference? {
        
        guard let cloudKitRecordID = cloudKitRecordID else { return nil }
        
        return CKReference(recordID: cloudKitRecordID, action: .DeleteSelf)
    }
    
    //==================================================
    // MARK: - Method(s)
    //==================================================
    
    func nameForManagedObject() -> String {
        
        return NSUUID().UUIDString
    }
    
    func updateRecordIDData(record: CKRecord) {
        
        self.recordIDData = NSKeyedArchiver.archivedDataWithRootObject(record.recordID)
        
        do {
            try Stack.sharedStack.managedObjectContext.save()
            
        } catch {
            
            print("Unable to save Managed Object Context: \(error)")
        }
    }
    
}