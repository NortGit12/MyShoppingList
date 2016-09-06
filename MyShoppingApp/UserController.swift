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
        
        cloudKitManager.fetchLoggedInUserRecord { (record, error) in
            
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
    }
}