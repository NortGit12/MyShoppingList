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
            
            var notificationType = String()
            if queryNotification.queryNotificationReason == .RecordDeleted {
                
                guard let recordID = queryNotification.recordID else {
                    
                    NSLog("Error: Could not identify the record ID associated with the record deleted notification.")
                    return
                }
                
                notificationType = "Deleted"
                let managedObjectType = PersistenceController.sharedController.identifyManagedObjectType(recordID)
                
                switch managedObjectType {
                    
                    // Not adding delete functionality for Store Categories yet
                    
                case Store.type:
                    
                    guard let store = StoreModelController.sharedController.fetchStoreByIdName(recordID.recordName) else {
                        
                        NSLog("Error: Could not identify the store associated with the record deleted notification.")
                        return
                    }
                    
                    StoreModelController.sharedController.deleteStore(store, sourceIsRemoteNotification: true)
                    
                default:
                    
                    guard let item = ItemModelController.sharedController.fetchItemByIdName(recordID.recordName) else {
                        
                        NSLog("Error: Could not identify the item associated with the record deleted notification.")
                        return
                    }
                    
                    ItemModelController.sharedController.deleteItem(item, sourceIsRemoteNotification: true)
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
                        
                        let managedObjectType = PersistenceController.sharedController.identifyManagedObjectType(record.recordID)
                        
                        if queryNotification.queryNotificationReason == .RecordUpdated {
                            
                            notificationType = "Updated"
                            
                            switch managedObjectType {
                            case StoreCategory.type:
                                
                                guard let updatedStoreCategoryFromCloudKit = StoreCategory(record: record)
                                    else {
                                        
                                        NSLog("Error: Could not fetch store category with record name \"\(record.recordID.recordName)\".")
                                        return
                                }
                                
                                StoreCategoryModelController.sharedController.updateStoreCategory(updatedStoreCategoryFromCloudKit, sourceIsRemoteNotification: true)
                                
                            case Store.type:
                                
                                guard let updatedStoreFromCloudKit = Store(record: record)
                                    else {
                                        
                                        NSLog("Error: Could not fetch store with record name \"\(record.recordID.recordName)\".")
                                        return
                                }
                                
                                StoreModelController.sharedController.updateStore(updatedStoreFromCloudKit, sourceIsRemoteNotification: true)
                                
                            default:
                                
                                guard let updatedItemFromCloudKit = Item(record: record)
                                    else {
                                        
                                        NSLog("Error: Could not fetch item with record name \"\(record.recordID.recordName)\".")
                                        return
                                }
                                
                                ItemModelController.sharedController.updateItem(updatedItemFromCloudKit, sourceIsRemoteNotification: true)
                            }
                            
                            PersistenceController.sharedController.saveContext()
                            NSLog("Info: New record received from remote notification saved.")
                            
                        } else {
                            
                            notificationType = "New"
                            switch managedObjectType {
                            case StoreCategory.type: let _ = StoreCategory(record: record)
                            case Store.type: let _ = Store(record: record)
                            default: let _ = Item(record: record)
                            }
                            
                            PersistenceController.sharedController.saveContext()
                            NSLog("Info: \(notificationType) record received from remote notification successfully processed.")
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
                let reason = queryNotification.queryNotificationReason
                let recordID = queryNotification.recordID
                
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



























