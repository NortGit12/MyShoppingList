//
//  AppDelegate.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/22/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        let notificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
        UIApplication.sharedApplication().registerForRemoteNotifications()
        
        subscribeToAllRecordCreations { 
            
            self.subscribeToAllRecordUpdates({
                
                self.subscribeToAllRecordDeletions()
            })
        }
        
        
        UIApplication.sharedApplication().statusBarStyle = .LightContent
        AppearanceController.initializeAppearanceDefaults()
        
        return true
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        
        NSLog("\nInfo: Notification settings = \(notificationSettings)")
        
        let settings = UIApplication.sharedApplication().currentUserNotificationSettings()
        
        NSLog("Info: Current user notification settings = \(settings)")
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        
        NSLog("\nInfo: Received a device token \"\(deviceToken)\"")
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        
        NSLog("Error: Failed to register for remote notifications.  \(error.localizedDescription)")
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
        /*
         Right now this only handles notification related to new records.  Make it so that it also supports update and deletes.
         */
        
        let notification = CKNotification(fromRemoteNotificationDictionary: (userInfo as? [String : NSObject])!)
        
        if notification.notificationType == .Query {
            
            let queryNotification = notification as! CKQueryNotification
            
            if queryNotification.queryNotificationReason == .RecordDeleted {
                
                // TODO: Delete the local record
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
                            
                            switch managedObjectType {
                            case StoreCategory.type: let _ = StoreCategory(record: record)
                            case Store.type: let _ = Store(record: record)
                            default: let _ = Item(record: record)
                            }
                            
                            PersistenceController.sharedController.saveContext()
                            NSLog("Info: New record received from remote notification saved.")
                        }
                    }
                })
            }
        }
        
        
        
        
        completionHandler(UIBackgroundFetchResult.NewData)
    }

    //==================================================
    // MARK: - Core Data stack
    //==================================================

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.jcn.MyShoppingApp" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("MyShoppingApp", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason

            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    //==================================================
    // MARK: - Core Data Saving support
    //==================================================

    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    //==================================================
    // MARK: - Methods
    //==================================================
    
    func subscribeToAllRecordCreations(completion: (() -> Void)? = nil) {
        
        StoreCategoryModelController.sharedController.subscribeToStoreCategoriesForOptionType(.FiresOnRecordCreation) { (success, error) in
            
            if success == true {
                NSLog("Subscribed successfully to all new Store Categories.")
            } else {
                NSLog("Error: Problem subscribing to new Store Categories.")
            }
            
            StoreModelController.sharedController.subscribeToStoresForOptionType(.FiresOnRecordCreation) { (success, error) in
                
                if success == true {
                    NSLog("Subscribed successfully to all new Stores.")
                } else {
                    NSLog("Error: Problem subscribing to new Stores.")
                }
                
                ItemModelController.sharedController.subscribeToItemsForOptionType(.FiresOnRecordCreation) { (success, error) in
                    
                    if success == true {
                        NSLog("Subscribed successfully to all new Items.")
                    } else {
                        NSLog("Error: Problem subscribing to new Items.")
                    }
                    
                    if let completion = completion {
                        completion()
                    }
                }
            }
        }
    }
    
    func subscribeToAllRecordUpdates(completion: (() -> Void)? = nil) {
        
        StoreCategoryModelController.sharedController.subscribeToStoreCategoriesForOptionType(.FiresOnRecordUpdate) { (success, error) in
            
            if success == true {
                NSLog("Subscribed successfully to all new Store Categories.")
            } else {
                NSLog("Error: Problem subscribing to new Store Categories.")
            }
            
            StoreModelController.sharedController.subscribeToStoresForOptionType(.FiresOnRecordUpdate) { (success, error) in
                
                if success == true {
                    NSLog("Subscribed successfully to all new Stores.")
                } else {
                    NSLog("Error: Problem subscribing to new Stores.")
                }
                
                ItemModelController.sharedController.subscribeToItemsForOptionType(.FiresOnRecordUpdate) { (success, error) in
                    
                    if success == true {
                        NSLog("Subscribed successfully to all new Items.")
                    } else {
                        NSLog("Error: Problem subscribing to new Items.")
                    }
                    
                    if let completion = completion {
                        completion()
                    }
                }
            }
        }
    }
    
    func subscribeToAllRecordDeletions(completion: (() -> Void)? = nil) {
        
        StoreCategoryModelController.sharedController.subscribeToStoreCategoriesForOptionType(.FiresOnRecordDeletion) { (success, error) in
            
            if success == true {
                NSLog("Subscribed successfully to all new Store Categories.")
            } else {
                NSLog("Error: Problem subscribing to new Store Categories.")
            }
            
            StoreModelController.sharedController.subscribeToStoresForOptionType(.FiresOnRecordDeletion) { (success, error) in
                
                if success == true {
                    NSLog("Subscribed successfully to all new Stores.")
                } else {
                    NSLog("Error: Problem subscribing to new Stores.")
                }
                
                ItemModelController.sharedController.subscribeToItemsForOptionType(.FiresOnRecordDeletion) { (success, error) in
                    
                    if success == true {
                        NSLog("Subscribed successfully to all new Items.")
                    } else {
                        NSLog("Error: Problem subscribing to new Items.")
                    }
                    
                    if let completion = completion {
                        completion()
                    }
                }
            }
        }
    }

}

