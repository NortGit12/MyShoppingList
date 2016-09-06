//
//  AllStoresViewController.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/26/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import UIKit

class AllStoresViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AllStoresTableViewCellDelegate {
    
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
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 50
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
        
        guard let cell = tableView.dequeueReusableCellWithIdentifier("allStoresListCell", forIndexPath: indexPath) as? AllStoresTableViewCell
            , store = StoreModelController.sharedController.getStores()?[indexPath.row]
            else {
        
                NSLog("Error: Could not cast the UITableViewCell to an AllStoresTableViewCell.")
                return UITableViewCell()
        }
        
        cell.delegate = self
        cell.updateWithStore(store)
        
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
    // MARK: - AllStoresTableViewCellDelegate
    //==================================================
    
    func editStoreButtonTapped(cell: AllStoresTableViewCell) {
        
        self.performSegueWithIdentifier("allStoresToExistinStoreSegue", sender: cell)
    }
    
    //==================================================
    // MARK: - Navigation
    //==================================================
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // How are we getting there?
        if segue.identifier == "storeInAllStoresToItemsListSegue" {
            
            self.segueToItemsList(segue)
            
        } else if segue.identifier == "allStoresToExistinStoreSegue" {
            
            self.segueToExistingStore(segue, sender: sender)
        }
    }
    
    func segueToItemsList(segue: UIStoryboardSegue) {
        
        // Where are we going?
        if let itemsTableViewController = segue.destinationViewController as? ItemsTableViewController {
            
            // What do we need to pack?
            guard let index = tableView.indexPathForSelectedRow?.row
                , stores = StoreModelController.sharedController.getStores()
                else {
            
                    NSLog("Error: Could not either identify the index of the selected row in AllStoresTableView or get all of the stores when attempting to segue to the items list.")
                    return
            }
            
            let backBarButtonItem = UIBarButtonItem()
            backBarButtonItem.title = "Stores"
            
            // Are we done packing?
            itemsTableViewController.store = stores[index]
            self.navigationController?.navigationBar.topItem?.backBarButtonItem = backBarButtonItem
        }
    }
    
    func segueToExistingStore(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // Where are we going?
        if let newStoreViewController = segue.destinationViewController as? NewStoreViewController {
            
            // What do we need to pack?
            guard let cell = sender as? AllStoresTableViewCell
                , index = tableView.indexPathForCell(cell)?.row
                else {
                    
                    NSLog("Error: Could not either cast the UITableViewCell as an AllStoresTableViewCell or could not get the indexPath for the cell when attempting to segue to an existing store.")
                    return
            }
            
            guard let stores = StoreModelController.sharedController.getStores()
                else {
                    
                    NSLog("Error: Could not get all of the stores when attempting to segue to an existing store.")
                    return
            }
            
            let store = stores[index]
            
            // Are we done packing?
            newStoreViewController.store = store
        }
    }
}
