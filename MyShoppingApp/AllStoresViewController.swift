//
//  AllStoresViewController.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/26/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import UIKit

class AllStoresViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    @IBOutlet weak var tableView: UITableView!
    
    //==================================================
    // MARK: - General
    //==================================================

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    //==================================================
    // MARK: - UITableViewDataSource
    //==================================================
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return StoreModelController.sharedController.getStores()?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("allStoresCell", forIndexPath: indexPath)
        
        guard let store = StoreModelController.sharedController.getStores()?[indexPath.row] else { return UITableViewCell() }
        
        cell.textLabel?.text = store.name
        cell.imageView?.image = UIImage(data: store.image)
        
        return cell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            
            guard let store = StoreModelController.sharedController.getStores()?[indexPath.row] else {
                
                print("Error: Store could not be identified when attempting to delete it.")
                return
            }
            
            StoreModelController.sharedController.deleteStore(store, completion: { 
                
                dispatch_async(dispatch_get_main_queue(), {
                    
                    self.tableView.reloadData()
                })
            })
        }
    }
    
    //==================================================
    // MARK: - Navigation
    //==================================================
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // How are we getting there?
        if segue.identifier == "storeInAllStoresToItemsListSegue" {
            
            // Where are we going?
            if let itemsTableViewController = segue.destinationViewController as? ItemsTableViewController {
                
                // What do we need to pack?
                guard let index = tableView.indexPathForSelectedRow?.row
                    , stores = StoreModelController.sharedController.getStores()
                    else { return }
                
                // Are we done packing?
                itemsTableViewController.store = stores[index]
            }
        }
    }
}
