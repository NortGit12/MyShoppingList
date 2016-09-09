//
//  UserController.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 9/5/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import Foundation
import CloudKit

class UserController {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    static let sharedController = UserController()
    let cloudKitManager = CloudKitManager()
    var loggedInUserRecord: CKRecord?
    
    //==================================================
    // MARK: - Methods
    //==================================================
    
    func getLoggedInUser(completion: ((record: CKRecord?, error: NSError?) -> Void)? = nil) {
        
//        cloudKitManager.fetchLoggedInUserRecord { (record, error) in
        cloudKitManager.fetchLoggedInUserRecord(cloudKitManager.publicDatabase) { (record, error) in
            
            if error != nil {
                
                print("Error: Could not fetch the logged in user record.  \(error)")
                
                if let completion = completion {
                
                    completion(record: nil, error: error)
                }
                
                return
            }
            
            if let record = record {
                
                self.loggedInUserRecord = record
                
                if let completion = completion {
                    
                    completion(record: record, error: nil)
                }
            }
        }
        
        // TODO: Identify parts of the user's name and store them (to make it easier to see on the CloudKit Dashboard what belongs to who)
    }
}