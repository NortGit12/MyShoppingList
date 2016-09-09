//
//  StoreCategoryModelController.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/23/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import UIKit
import CoreData

class StoreCategoryModelController {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    static let sharedController = StoreCategoryModelController()
    let cloudKitManager = CloudKitManager()
    var storeCategories = [StoreCategory]()
    static let defaultStoreCategoryName = "Grocery"
    
    //==================================================
    // MARK: - Initializer(s)
    //==================================================
    
    init() {
        
        // Run createMockData() to populate the StoreCategories
//        createMockData()
    }
    
    //==================================================
    // MARK: - Method(s)
    //==================================================
    
    func createStoreCategory(name: String, image: UIImage, completion: (() -> Void)? = nil) {
        
        guard let imageData = UIImagePNGRepresentation(image)
            , storeCategory = StoreCategory(name: name, image: imageData, stores: nil)
            else {
                
                NSLog("Error: Could not either access the image data or create a new StoreCategory.")
                return
            }
        
        PersistenceController.sharedController.saveContext()
        
        if let completion = completion {
            completion()
        }
        
        if let storeCategoryCloudKitRecord = storeCategory.cloudKitRecord {
            
            cloudKitManager.saveRecord(cloudKitManager.publicDatabase, record: storeCategoryCloudKitRecord, completion: { (record, error) in
                
                if error != nil {
                    
                    NSLog("Error: New Store Category could not be saved to CloudKit: \(error)")
                    return
                }
                
                if let record = record {
                    
                    let moc = PersistenceController.sharedController.moc
                    
                    /*
                     The "...AndWait" makes the subsequent work wait for the performBlock to finish.  By default, the moc.performBlock(...) is asynchronous, so the work in there would be done asynchronously on another thread and the subsequent lines would run immediately.
                     */
                    
                    moc.performBlockAndWait({ storeCategory.updateRecordIDData(record) })
                }
            })
        }
    }
    
    func fetchStoreCategoryByIdName(idName: String) -> StoreCategory? {
        
        if idName.isEmpty { return nil }
        
        let request = NSFetchRequest(entityName: StoreCategory.type)
        let predicate = NSPredicate(format: "recordName == %@", argumentArray: [idName])
        request.predicate = predicate
        
        let resultsArray = (try? PersistenceController.sharedController.moc.executeFetchRequest(request)) as? [StoreCategory] ?? nil
        
        return resultsArray?.first
    }
    
    func fetchStoreCategoryByName(name: String) -> StoreCategory? {
        
        if name.isEmpty { return nil }
        
        let request = NSFetchRequest(entityName: StoreCategory.type)
        let predicate = NSPredicate(format: "name == %@", argumentArray: [name])
        request.predicate = predicate
        
        let resultsArray = (try? PersistenceController.sharedController.moc.executeFetchRequest(request)) as? [StoreCategory] ?? nil
        
        return resultsArray?.first
    }
    
//    func getStoreCategoriesWithCompletion(completion: ((categories: [StoreCategory]?) -> Void)? = nil) {
    func fetchStoreCategories() -> [StoreCategory]? {
    
        let request = NSFetchRequest(entityName: StoreCategory.type)
        let predicate = NSPredicate(value: true)
        request.predicate = predicate
        
//        var resultsArray = (try? PersistenceController.sharedController.moc.executeFetchRequest(request)) as? [StoreCategory]
        
        var resultsArray = [StoreCategory]()
        do {
            if let tempResultsArray = try PersistenceController.sharedController.moc.executeFetchRequest(request) as? [StoreCategory] {
                resultsArray = tempResultsArray
            }
        } catch let error as NSError {
            NSLog("Error: Troublems.  \(error.localizedDescription)")
        }
        
//        resultsArray?.sortInPlace({ $0.0.name < $0.1.name })
        resultsArray.sortInPlace({ $0.0.name < $0.1.name })
        
//        if let completion = completion {
//            completion(categories: resultsArray)
//        }
        
        return resultsArray
    }
    
    func getStoresForStoreCategory(storeCategory: StoreCategory) -> [Store]? {
        
        guard let storesSet = storeCategory.stores
            , storesArray = Array(storesSet) as? [Store]
            else {
            
                NSLog("Error: Could not either unwrap the set of Stores or convert it to an Array of Stores.")
                return nil
            }
        
        let sortedStoresArray = storesArray.sort({ $0.0.name < $0.1.name })
        
        return sortedStoresArray
    }
    
    func createMockData() {
        
        createStoreCategory("Cars", image: UIImage(named: "cars")!)
        createStoreCategory("Clothing", image: UIImage(named: "clothing")!)
        createStoreCategory("Department", image: UIImage(named: "department-store")!)
        createStoreCategory("Electronics", image: UIImage(named: "electronics")!)
        createStoreCategory("Grocery", image: UIImage(named: "groceries")!)
        createStoreCategory("Health & Beauty", image: UIImage(named: "health-and-beauty")!)
        createStoreCategory("Home Improvement", image: UIImage(named: "home-improvement")!)
        createStoreCategory("Misc", image: UIImage(named: "misc")!)
        createStoreCategory("Office Supply", image: UIImage(named: "office-supply")!)
        createStoreCategory("Pet", image: UIImage(named: "pet")!)
    }
}