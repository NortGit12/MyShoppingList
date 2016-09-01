//
//  ItemsTableViewController.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/30/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import UIKit

class ItemsTableViewController: UITableViewController {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    var store: Store?
    
    //==================================================
    // MARK: - General
    //==================================================

    override func viewDidLoad() {
        super.viewDidLoad()

        if let store = store {
            
            self.title = "\(store.name) List"
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.reloadData()
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var numRows = 0
        if let store = store, storeItems = ItemModelController.sharedController.getItemsForStore(store) {
            
            numRows = storeItems.count
        }
        
        return numRows
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCellWithIdentifier("itemsListCell", forIndexPath: indexPath) as? ItemsListTableViewCell
            , store = store
            , storeItems = ItemModelController.sharedController.getItemsForStore(store)
            else { return UITableViewCell() }
        
        let item = storeItems[indexPath.row]
        
        cell.updateWithItem(item)

        return cell
    }
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            
            guard let store = store
                , storeItems = ItemModelController.sharedController.getItemsForStore(store)
                else {
                    
                    print("Error: Item could not be identified when attempting to delete it.")
                    return
            }
            
            let item = storeItems[indexPath.row]
            
            ItemModelController.sharedController.deleteItem(item, store: store, completion: {
                
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
        
        // How am I getting there?
        if segue.identifier == "itemsListAddToItemDetailSegue" {
            
            // Where am I going?
            if let itemDetailViewController = segue.destinationViewController as? ItemDetailViewController
                , store = store {
                
                // Am I done packing?
                itemDetailViewController.store = store
            }
            
        } else if segue.identifier == "itemsListCellToItemDetailSegue" {
            
            // Where am I going?
            if let itemDetailViewController = segue.destinationViewController as? ItemDetailViewController
                , store = store
                , index = tableView.indexPathForSelectedRow?.row
                , storeItems = ItemModelController.sharedController.getItemsForStore(store) {
                
                // Am I done packing?
                let item = storeItems[index]
                
                itemDetailViewController.store = store
                itemDetailViewController.item = item
            }
        }
    }
 

}
