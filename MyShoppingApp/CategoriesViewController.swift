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
    
    @IBOutlet weak var addNewStoreBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var storeCategoriesCollectionView: UICollectionView!
    @IBOutlet weak var storeCategoriesCollectionViewFlowLayout: UICollectionViewFlowLayout!
    var selectedStoreCategory: StoreCategory?
    var selectedStoreCategoryIndex = -1
    let defaultStoreCategoryName = "Grocery"
    
    @IBOutlet weak var storesCollectionView: UICollectionView!
    @IBOutlet weak var storesCollectionViewFlowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var collectionViewSelectedBorderWidth: CGFloat = 1.0
    var collectionViewUnselectedBorderWidth: CGFloat = 0.0
    var collectionViewSelectedBackgroundColor: UIColor = .basicGrayColor()
    var collectionViewUnselectedBackgroundColor: UIColor = .whiteColor()
    
    //==================================================
    // MARK: - General
    //==================================================

    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicatorView.hidesWhenStopped = true
        
        self.setupCollectionViews()
        
        UserController.sharedController.getLoggedInUser { (_, _) in
            
            dispatch_async(dispatch_get_main_queue(), {
                
                if self.fetchStoreCategories().count == 0 {
                    
                    self.activityIndicatorView.startAnimating()
                    
                    self.requestFullSync({
                        
                        self.activityIndicatorView.stopAnimating()
                        self.refreshCollectionViews()
                        self.setupSelectedStoreCategory()
                    })
                } else {
                    self.refreshCollectionViews()
                    self.setupSelectedStoreCategory()
                    self.requestFullSync()
                }
                
            })
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        self.tabBarController?.tabBar.hidden = false
        
        self.refreshCollectionViews()
    }
    
    //==================================================
    // MARK: - UICollectionViewDataSource
    //==================================================
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        var numberOfItemsInSection = 0
        
        if collectionView == storeCategoriesCollectionView {
            
            numberOfItemsInSection = fetchStoreCategories().count
            
        } else if collectionView == storesCollectionView {
            
            if let selectedStoreCategory = self.selectedStoreCategory {
                
                numberOfItemsInSection = StoreCategoryModelController.sharedController.fetchStoresForStoreCategory(selectedStoreCategory)?.count ?? 0
            }
        }
        
        return numberOfItemsInSection
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        var returningCell = UICollectionViewCell()
        
        if collectionView == storeCategoriesCollectionView {
            
            guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("storeCategoryCollectionViewCell", forIndexPath: indexPath) as? StoreCategoryCollectionViewCell
                else {
                    
                    NSLog("Error: Could not either cast the UITableViewCell as a StoreCategoryCollectionViewCell or identify the selected StoreCategory.")
                    return UICollectionViewCell()
            }
            
            let storeCategory = fetchStoreCategories()[indexPath.row]
            
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
                    , store = StoreCategoryModelController.sharedController.fetchStoresForStoreCategory(selectedStoreCategory)?[indexPath.row]
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
            
            let selectedStoreCategory = fetchStoreCategories()[indexPath.row]
            
            guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? StoreCategoryCollectionViewCell
                 , selectedStoreCategoryIndex = fetchStoreCategories().indexOf(selectedStoreCategory)
                else {
                
                    NSLog("Error: Could not either unwrap the cell or identify the Store Category index.")
                    return
                }
            
            self.selectedStoreCategoryIndex = selectedStoreCategoryIndex
            
            self.handleSelectionFormattingForCell(cell, indexPathForCell: indexPath, borderWidth: self.collectionViewSelectedBorderWidth, backgroundColor: self.collectionViewSelectedBackgroundColor)
            
            self.selectedStoreCategory = selectedStoreCategory
            
            self.storeCategoriesCollectionView.selectItemAtIndexPath(NSIndexPath(forItem: selectedStoreCategoryIndex, inSection: 0), animated: false, scrollPosition: .CenteredHorizontally)
            
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
    
    func fetchStoreCategories() -> [StoreCategory] {
        
        guard let currentStoreCategories = StoreCategoryModelController.sharedController.fetchStoreCategories() else {
            
            NSLog("Error: Could not get current set of Store Categories.")
            return [StoreCategory]()
        }
        
        return currentStoreCategories
    }
    
    func refreshCollectionViews() {
        
        self.storeCategoriesCollectionView.reloadData()
        self.storesCollectionView.reloadData()
    }
    
    func requestFullSync(completion: (() -> Void)? = nil) {
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        PersistenceController.sharedController.performFullSync {
            
            dispatch_async(dispatch_get_main_queue(), {
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                
                if let completion = completion {
                    completion()
                }
            })
        }
    }
    
    func handleSelectionFormattingForCell(cell: UICollectionViewCell, indexPathForCell indexPath: NSIndexPath, borderWidth: CGFloat, backgroundColor: UIColor) {
    
        cell.layer.borderWidth = borderWidth
        cell.backgroundColor = backgroundColor
    }
    
    func setupCollectionViews() {
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.storeCategoriesCollectionView.allowsMultipleSelection = false
        storeCategoriesCollectionViewFlowLayout.itemSize = CGSize(width: 70.0, height: 70.0)
        storeCategoriesCollectionViewFlowLayout.minimumInteritemSpacing = 2.0
        storeCategoriesCollectionViewFlowLayout.minimumLineSpacing = 2.0
        
        let screenSize = UIScreen.mainScreen().bounds
        let screenWidth = screenSize.width
        
        self.storesCollectionView.allowsMultipleSelection = false
        storesCollectionViewFlowLayout.itemSize = CGSize(width: ((screenWidth / 2) - 2), height: ((screenWidth / 2) - 2))
        storesCollectionViewFlowLayout.minimumInteritemSpacing = 2.0
        storesCollectionViewFlowLayout.minimumLineSpacing = 2.0
    }
    
    func setupSelectedStoreCategory() {
        
        guard let defaultStoreCategory = StoreCategoryModelController.sharedController.fetchStoreCategoryByName(self.defaultStoreCategoryName)
            , defaultStoreCategoryIndex = fetchStoreCategories().indexOf(defaultStoreCategory)
            else {
                
                NSLog("Error: Could not identify the Store Category's index.")
                return
        }
        
        self.selectedStoreCategory = defaultStoreCategory
        self.selectedStoreCategoryIndex = defaultStoreCategoryIndex
        
        // Select "Grocery" as the default Store Category
        self.storeCategoriesCollectionView.selectItemAtIndexPath(NSIndexPath(forItem: defaultStoreCategoryIndex, inSection: 0), animated: true, scrollPosition: .CenteredHorizontally)
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
            let selectedStoreCategory = fetchStoreCategories()[self.selectedStoreCategoryIndex]
            
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
            
            guard let stores = StoreCategoryModelController.sharedController.fetchStoresForStoreCategory(selectedStoreCategory)
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
                , stores = StoreCategoryModelController.sharedController.fetchStoresForStoreCategory(selectedStoreCategory)
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
