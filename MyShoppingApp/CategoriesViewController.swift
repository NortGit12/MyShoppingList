//
//  CategoriesViewController.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/23/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import UIKit

class CategoriesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, StoreCollectionViewCellDelegate {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    @IBOutlet weak var storeCategoriesCollectionView: UICollectionView!
    var selectedStoreCategory: StoreCategory?
    let defaultStoreCategoryName = "Grocery"
    
    @IBOutlet weak var storesCollectionView: UICollectionView!
    @IBOutlet weak var storesCollectionViewFlowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var collectionViewSelectedBorderWidth: CGFloat = 1.0
    var collectionViewUnselectedBorderWidth: CGFloat = 0.0
    var collectionViewSelectedBackgroundColor: UIColor = .orangeColor()
    var collectionViewUnselectedBackgroundColor: UIColor = .whiteColor()
    
    //==================================================
    // MARK: - General
    //==================================================

    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicatorView.hidesWhenStopped = true
        
        UserController.sharedController.getLoggedInUser { (_, _) in
            
            self.setupCollectionViews()
            
            dispatch_async(dispatch_get_main_queue(), {
                
                self.refreshCollectionViews()
                self.setupSelectedStoreCategory()
            })
            
            self.requestFullSync()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        self.refreshCollectionViews()
    }
    
    //==================================================
    // MARK: - UICollectionViewDataSource
    //==================================================
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        var numberOfItemsInSection = 0
        
        if collectionView == storeCategoriesCollectionView {
            
            numberOfItemsInSection = StoreCategoryModelController.sharedController.getStoreCategories()?.count ?? 0
            
        } else if collectionView == storesCollectionView {
            
            if let selectedStoreCategory = self.selectedStoreCategory {
                
                numberOfItemsInSection = StoreCategoryModelController.sharedController.getStoresForStoreCategory(selectedStoreCategory)?.count ?? 0
            }
        }
        
        return numberOfItemsInSection
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        var returningCell = UICollectionViewCell()
        
        if collectionView == storeCategoriesCollectionView {
            
            guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("storeCategoryCollectionViewCell", forIndexPath: indexPath) as? StoreCategoryCollectionViewCell
                , storeCategory = StoreCategoryModelController.sharedController.getStoreCategories()?[indexPath.row]
                else {
                    
                    NSLog("Error: Could not either cast the UITableViewCell as a StoreCategoryCollectionViewCell or identify the selected StoreCategory.")
                    return UICollectionViewCell()
            }
            
            cell.updateWithStoreCategory(storeCategory)
            
            // This handles the shading of the selected and unselected cells on load (as opposed to changing them when they're selected)
            if storeCategory == selectedStoreCategory {
            
                handleSelectionFormattingForCell(cell, indexPathForCell: indexPath, borderWidth: self.collectionViewSelectedBorderWidth, backgroundColor: self.collectionViewSelectedBackgroundColor)
                
                self.selectedStoreCategory = storeCategory
                
            } else {
                
                handleSelectionFormattingForCell(cell, indexPathForCell: indexPath, borderWidth: self.collectionViewUnselectedBorderWidth, backgroundColor: self.collectionViewUnselectedBackgroundColor)
            }
            
            returningCell = cell
            
        } else if collectionView == storesCollectionView {
            
            if let selectedStoreCategory = self.selectedStoreCategory {
                
                guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("storeCollectionViewCell", forIndexPath: indexPath) as? StoreCollectionViewCell
                    , store = StoreCategoryModelController.sharedController.getStoresForStoreCategory(selectedStoreCategory)?[indexPath.row]
                    else {
                        
                        NSLog("Error: Could not either cast the UITableViewCell as a StoreCollectionViewCell or get all of the stores for the selected StoreCategory.")
                        return UICollectionViewCell()
                }
                
                cell.delegate = self
                cell.updateWithStore(store)
                
                returningCell = cell
            }
        }
        
        return returningCell
    }
    
    //==================================================
    // MARK: - UICollectionViewDelegate
    //==================================================
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if collectionView == storeCategoriesCollectionView {
            
            guard let storeCategories = StoreCategoryModelController.sharedController.getStoreCategories()
                else {
                
                    NSLog("Error: Could not get all of the StoreCategories.")
                    return
                }
            
            guard let cell = collectionView.cellForItemAtIndexPath(indexPath) else { return }
            
            handleSelectionFormattingForCell(cell, indexPathForCell: indexPath, borderWidth: self.collectionViewSelectedBorderWidth, backgroundColor: self.collectionViewSelectedBackgroundColor)
            
            self.selectedStoreCategory = storeCategories[indexPath.row]
            self.storeCategoriesCollectionView.reloadData()
            self.storesCollectionView.reloadData()
        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        
        if collectionView == storeCategoriesCollectionView {
            
            guard let cell = collectionView.cellForItemAtIndexPath(indexPath) else {
                
                NSLog("Error: Could not identify the selected StoreCategory cell.")
                return
            }
            
            handleSelectionFormattingForCell(cell, indexPathForCell: indexPath, borderWidth: self.collectionViewUnselectedBorderWidth, backgroundColor: self.collectionViewUnselectedBackgroundColor)
            
            self.storeCategoriesCollectionView.reloadData()
        }
    }
    
    //==================================================
    // MARK: - StoreCollectionViewCellDelegate
    //==================================================
    
    func editStoreButtonTapped(cell: StoreCollectionViewCell) {
                
        self.performSegueWithIdentifier("storeCategoriesToExistingStoreSegue", sender: cell)
    }
    
    //==================================================
    // MARK: - Methods
    //==================================================
    
    func setupCollectionViews() {
        
        self.automaticallyAdjustsScrollViewInsets = false
        self.storeCategoriesCollectionView.allowsMultipleSelection = false
        self.storesCollectionView.allowsMultipleSelection = false
    }
    
    func setupSelectedStoreCategory() {
        
        StoreCategoryModelController.sharedController.getStoreCategoriesWithCompletion({ (categories) in
            
            guard let defaultStoreCategory = StoreCategoryModelController.sharedController.getStoreCategoryByName(self.defaultStoreCategoryName)
                , storeCategories = categories
                , defaultStoreCategoryIndex = storeCategories.indexOf(defaultStoreCategory)
                else {
                    
                    NSLog("Error: Could not either unwrap the Store Categories or identify the Store Category's index.")
                    return
            }
            
            self.selectedStoreCategory = defaultStoreCategory
            
            // Select "Grocery" as the default Store Category
            self.storeCategoriesCollectionView.selectItemAtIndexPath(NSIndexPath(forItem: defaultStoreCategoryIndex, inSection: 0), animated: false, scrollPosition: .CenteredHorizontally)
            
            self.storeCategoriesCollectionView.reloadData()
            
            self.activityIndicatorView.stopAnimating()
        })
    }
    
    func refreshCollectionViews() {
        
        self.storeCategoriesCollectionView.reloadData()
        self.storesCollectionView.reloadData()
    }
    
    func requestFullSync() {
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        self.activityIndicatorView.startAnimating()
        
        PersistenceController.sharedController.performFullSync {
            
            dispatch_async(dispatch_get_main_queue(), {
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                self.activityIndicatorView.stopAnimating()
                self.refreshCollectionViews()
            })
        }
    }
    
    func handleSelectionFormattingForCell(cell: UICollectionViewCell, indexPathForCell indexPath: NSIndexPath, borderWidth: CGFloat, backgroundColor: UIColor) {
    
        cell.layer.borderWidth = borderWidth
        cell.backgroundColor = backgroundColor
    }
    
    //==================================================
    // MARK: - Navigation
    //==================================================
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // How are we getting there?
        if segue.identifier == "storeCategoriesToNewStoreSegue" {
            
            self.segueToNewStore(segue)
            
        } else if segue.identifier == "storeCategoriesToExistingStoreSegue" {
            
            self.segueToExistingStore(segue, sender: sender)
            
        } else if segue.identifier == "storeInStoreCategoryToItemListSegue" {
            
            self.segueToStoreItemsList(segue)
        }
    }
    
    func segueToNewStore(segue: UIStoryboardSegue) {
        
        // Where are we going?
        if let newStoreViewController = segue.destinationViewController as? NewStoreViewController {
            
            // What do we need to pack?
            guard let index = storeCategoriesCollectionView.indexPathsForSelectedItems()?.first?.row
                , let storeCategories = StoreCategoryModelController.sharedController.getStoreCategories()
                else {
                    
                    NSLog("Error: The index or the Store Categories could not be found when attempting to segue to a new store.")
                    return
            }
            
            let selectedStoreCategory = storeCategories[index]
            
            // Are we done packing?
            newStoreViewController.selectedStoreCategory = selectedStoreCategory
        }
    }
    
    func segueToExistingStore(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // Where are we going?
        if let newStoreViewController = segue.destinationViewController as? NewStoreViewController {
            
            // What do we need to pack?
            guard let cell = sender as? StoreCollectionViewCell
                , storeIndexPath = storesCollectionView.indexPathForCell(cell)
                , selectedStoreCategory = self.selectedStoreCategory
                else {
                    
                    NSLog("Error: The index or the Store Categories could not be found when attempting to segue to an existing store.")
                    return
            }
            
            guard let stores = StoreCategoryModelController.sharedController.getStoresForStoreCategory(selectedStoreCategory)
                else {
                
                    NSLog("Error: Could not get all the stores for the the selected StoreCategory when attempting to segue to an existing store.")
                    return
                }
            
            let store = stores[storeIndexPath.row]
            
            // Are we done packing?
            newStoreViewController.selectedStoreCategory = selectedStoreCategory
            newStoreViewController.store = store
        }
    }
    
    func segueToStoreItemsList(segue: UIStoryboardSegue) {
        
        // Where are we going?
        if let itemsTableViewController = segue.destinationViewController as? ItemsTableViewController {
            
            // What do we need to pack?
            guard let index = storesCollectionView.indexPathsForSelectedItems()?.first?.row
                , selectedStoreCategory = self.selectedStoreCategory
                , stores = StoreCategoryModelController.sharedController.getStoresForStoreCategory(selectedStoreCategory)
                else {
                    
                    NSLog("Error: Problem identifying the selected store for the upcoming items list when attempting to segue to the items list.")
                    return
            }
            
            let backBarButtonItem = UIBarButtonItem()
            backBarButtonItem.title = "Stores"
            
            // Are we done packing?
            itemsTableViewController.store = stores[index]
            self.navigationController?.navigationBar.topItem?.backBarButtonItem = backBarButtonItem
        }
    }

}
