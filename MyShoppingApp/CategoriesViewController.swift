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
    let defaultStoreCategoryIndex = 4
    
    @IBOutlet weak var storesCollectionView: UICollectionView!
    @IBOutlet weak var storesCollectionViewFlowLayout: UICollectionViewFlowLayout!
    
    var collectionViewSelectedBorderWidth: CGFloat = 1.0
    var collectionViewUnselectedBorderWidth: CGFloat = 0.0
    var collectionViewSelectedBackgroundColor: UIColor = .orangeColor()
    var collectionViewUnselectedBackgroundColor: UIColor = .whiteColor()
    
    //==================================================
    // MARK: - General
    //==================================================

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupCollectionViews()
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        requestFullSync {
            
            dispatch_async(dispatch_get_main_queue(), {
                
                self.refreshCollectionViewsAfterSyncing()
                
                guard let storeCategories = StoreCategoryModelController.sharedController.getStoreCategories() else { return }
                self.selectedStoreCategory = storeCategories[self.defaultStoreCategoryIndex]
                
                // Select "Grocery" as the default Store Category
                self.storeCategoriesCollectionView.selectItemAtIndexPath(NSIndexPath(forItem: self.defaultStoreCategoryIndex, inSection: 0), animated: false, scrollPosition: .CenteredHorizontally)
            })
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        requestFullSync { 
            
            dispatch_async(dispatch_get_main_queue(), {
                
                self.refreshCollectionViewsAfterSyncing()
                
            })
        }
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
                else { return UICollectionViewCell() }
            
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
                    else { return UICollectionViewCell() }
                
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
                else { return }
            
            guard let cell = collectionView.cellForItemAtIndexPath(indexPath) else { return }
            
            handleSelectionFormattingForCell(cell, indexPathForCell: indexPath, borderWidth: self.collectionViewSelectedBorderWidth, backgroundColor: self.collectionViewSelectedBackgroundColor)
            
            self.selectedStoreCategory = storeCategories[indexPath.row]
            self.storesCollectionView.reloadData()
            
        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        
        if collectionView == storeCategoriesCollectionView {
            
            guard let cell = collectionView.cellForItemAtIndexPath(indexPath) else { return }
            
            handleSelectionFormattingForCell(cell, indexPathForCell: indexPath, borderWidth: self.collectionViewUnselectedBorderWidth, backgroundColor: self.collectionViewUnselectedBackgroundColor)
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
    
    func refreshCollectionViewsAfterSyncing() {
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
        self.storeCategoriesCollectionView.reloadData()
        self.storesCollectionView.reloadData()
    }
    
    func requestFullSync(completion: (() -> Void)? = nil) {
        
        PersistenceController.sharedController.performFullSync {
            
            if let completion = completion {
                completion()
            }
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
                    
                    NSLog("Error: The index or the Store Categories could not be found.")
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
                    
                    NSLog("Error: The index or the Store Categories could not be found.")
                    return
            }
            
            guard let stores = StoreCategoryModelController.sharedController.getStoresForStoreCategory(selectedStoreCategory)
                else { return }
            
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
                    
                    NSLog("Error: Problem identifying the selected store for the upcoming items list")
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
