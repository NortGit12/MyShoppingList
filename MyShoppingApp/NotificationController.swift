//
//  NotificationController.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 9/16/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import Foundation
import CloudKit

class NotificationController {
    
    //==================================================
    // MARK: - Methods
    //==================================================
    
    static func processRemoteNotification(notification: CKNotification) {
        
        if notification.notificationType == .Query {
            
            let queryNotification = notification as! CKQueryNotification
            
            var managedObjectType = String()
            var notificationType = String()
            if queryNotification.queryNotificationReason == .RecordDeleted {
                
                guard let recordID = queryNotification.recordID else {
                    
                    NSLog("Error: Could not identify the record ID associated with the record deleted notification.")
                    return
                }
                
                managedObjectType = PersistenceController.sharedController.identifyManagedObjectType(recordID)
                notificationType = "Deleted"
                
                switch managedObjectType {
                    
                    // Not adding delete functionality for Store Categories yet
                    
                case Store.type:
                    
                    guard let store = StoreModelController.sharedController.fetchStoreByIdName(recordID.recordName) else {
                        
                        NSLog("Error: Could not identify the store associated with the record deleted notification.")
                        return
                    }
                    
                    StoreModelController.sharedController.deleteStore(store, sourceIsRemoteNotification: true)
                    NSNotificationCenter.defaultCenter().postNotificationName("storesUpdated", object: self)
                    NSLog("Info: \(notificationType) \(managedObjectType) record, received from remote notification, successfully processed.")
                    
                case Item.type:
                    
                    guard let item = ItemModelController.sharedController.fetchItemByIdName(recordID.recordName) else {
                        
                        NSLog("Error: Could not identify the item associated with the record deleted notification.")
                        return
                    }
                    
                    ItemModelController.sharedController.deleteItem(item, sourceIsRemoteNotification: true)
                    NSNotificationCenter.defaultCenter().postNotificationName("itemsUpdated", object: self)
                    NSLog("Info: \(notificationType) \(managedObjectType) record, received from remote notification, successfully processed.")
                    
                default:
                    
                    NSLog("Info: Unknown managed object type \"\(managedObjectType)\" for deleted record.")
                }
                
            } else {
                
                let cloudKitManager = CloudKitManager()
                let database: CKDatabase
                if queryNotification.isPublicDatabase {
                    database = CKContainer.defaultContainer().publicCloudDatabase
                } else {
                    database = CKContainer.defaultContainer().privateCloudDatabase
                }
                
                cloudKitManager.fetchRecordWithID(database, recordID: queryNotification.recordID!, completion: { (record, error) in
                    
                    if error != nil {
                        NSLog("Error: Record identified in remote notification could not be fetched.  \(error?.localizedDescription)")
                    }
                    
                    if let record = record {
                        
                        managedObjectType = PersistenceController.sharedController.identifyManagedObjectType(record.recordID)
                        
                        if queryNotification.queryNotificationReason == .RecordUpdated {
                            
                            notificationType = "Updated"
                            
                            switch managedObjectType {
                            case StoreCategory.type:
                                
                                cloudKitManager.fetchRecordWithID(cloudKitManager.privateDatabase, recordID: record.recordID, completion: { (record, error) in
                                    
                                    if error != nil {
                                        
                                        NSLog("Error: Could not fetch store category from the push notification.  \(error).")
                                        return
                                    }
                                    
                                    if let record = record {
                                        
                                        StoreCategoryModelController.sharedController.updateStoreCategory(record, sourceIsRemoteNotification: true)
                                        NSNotificationCenter.defaultCenter().postNotificationName("storeCategoriesUpdated", object: self)
                                        NSLog("Info: \(notificationType) \(managedObjectType) record, received from remote notification, successfully processed.")
                                    }
                                })
                                
                            case Store.type:
                                
                                cloudKitManager.fetchRecordWithID(cloudKitManager.privateDatabase, recordID: record.recordID, completion: { (record, error) in
                                    
                                    if error != nil {
                                        
                                        NSLog("Error: Could not fetch store from the push notification.  \(error).")
                                        return
                                    }
                                    
                                    if let record = record {
                                        
                                        StoreModelController.sharedController.updateStore(record, sourceIsRemoteNotification: true)
                                        NSNotificationCenter.defaultCenter().postNotificationName("storesUpdated", object: self)
                                        NSLog("Info: \(notificationType) \(managedObjectType) record, received from remote notification, successfully processed.")
                                    }
                                })
                                
                            case Item.type:
                                
                                cloudKitManager.fetchRecordWithID(cloudKitManager.privateDatabase, recordID: record.recordID, completion: { (record, error) in
                                    
                                    if error != nil {
                                        
                                        NSLog("Error: Could not fetch item from the push notification.  \(error).")
                                        return
                                    }
                                    
                                    if let record = record {
                                        
                                        ItemModelController.sharedController.updateItem(record, sourceIsRemoteNotification: true)
                                        NSNotificationCenter.defaultCenter().postNotificationName("itemsUpdated", object: self)
                                        NSLog("Info: \(notificationType) \(managedObjectType) record, received from remote notification, successfully processed.")
                                    }
                                })
                                
                            default:
                                
                                NSLog("Info: Unknown managed object type \"\(managedObjectType)\" for updated record.")
                            }
                            
                        } else {
                            
                            /*
                             New records don't yet exist in Core Data, so I can't use PersistenceController.sharedController.identifyManagedObjectType(record.recordID) because all instances inside of it will be nil.
                             */
                            managedObjectType = record.recordType
                            notificationType = "New"
                            
                            switch managedObjectType {
                            case StoreCategory.type:
                                let _ = StoreCategory(record: record)
                                NSNotificationCenter.defaultCenter().postNotificationName("storesUpdated", object: self)
                            case Store.type:
                                let _ = Store(record: record)
                                NSNotificationCenter.defaultCenter().postNotificationName("storesUpdated", object: self)
                            case Item.type:
                                let _ = Item(record: record)
                                NSNotificationCenter.defaultCenter().postNotificationName("itemsUpdated", object: self)
                            default: NSLog("Info: Unknown managed object type \"\(managedObjectType)\" for new record.")
                            }
                            
                            PersistenceController.sharedController.saveContext()
                            NSLog("Info: \(notificationType) \(managedObjectType) record, received from remote notification, successfully processed.")
                        }
                    }
                })
            }
        }
    }
    
    static func fetchNotificationChanges() {
        
        let operation = CKFetchNotificationChangesOperation(previousServerChangeToken: nil)
        
        var notificationIDsToMarkRead = [CKNotificationID]()
        
        operation.notificationChangedBlock = { (notification: CKNotification) -> Void in
            
            // Process each notification received
            
            if notification.notificationType == .Query {
                
                let queryNotification = notification as! CKQueryNotification
//                let reason = queryNotification.queryNotificationReason
//                let recordID = queryNotification.recordID
                
                // TODO: Implement what I want done here
                
                // Add the notification ID to the array of processed notifications to mark them as read
                
                notificationIDsToMarkRead.append(queryNotification.notificationID!)
            }
        }
        
        operation.fetchNotificationChangesCompletionBlock = { (serverChangeToken: CKServerChangeToken?, operationError: NSError?) -> Void in
            
            if operationError != nil {
                
                NSLog("Error: There was a problem fetching notification changes from the server.  \(operationError?.localizedDescription)")
                return
            }
            
            // Mark notifications as read to avoid processing them again
            
            let markOperation = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: notificationIDsToMarkRead)
            markOperation.markNotificationsReadCompletionBlock = { (notificationIDsMarkedRead: [CKNotificationID]?, operationError: NSError?) -> Void in
                
                if operationError != nil {
                    
                    NSLog("Error: There was a problem marking notification changes on the server as read.  \(operationError?.localizedDescription)")
                    return
                }
                
                let operationQueue = NSOperationQueue()
                operationQueue.addOperation(markOperation)
            }
            
            let operationQueue = NSOperationQueue()
            operationQueue.addOperation(operation)
        }
    }
}



























