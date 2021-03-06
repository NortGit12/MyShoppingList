//
//  CategoriesViewController.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/23/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import UIKit

class CategoriesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    @IBOutlet weak var storeCategoriesCollectionView: UICollectionView!
    @IBOutlet weak var storeCategoriesCollectionViewFlowLayout: UICollectionViewFlowLayout!
    private let storeCategorySectionInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    var selectedStoreCategory: StoreCategory?
    let defaultStoreCategoryIndex = 4
    
    @IBOutlet weak var storesCollectionView: UICollectionView!
    @IBOutlet weak var storesCollectionViewFlowLayout: UICollectionViewFlowLayout!
    private let storeSectionInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    
    //==================================================
    // MARK: - General
    //==================================================

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.storeCategoriesCollectionView.allowsMultipleSelection = false
        self.storeCategoriesCollectionViewFlowLayout.scrollDirection = .Horizontal
        self.storeCategoriesCollectionViewFlowLayout.sectionInset = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        self.storeCategoriesCollectionViewFlowLayout.itemSize = CGSize(width: 70, height: 74)
        
        self.storesCollectionView.allowsMultipleSelection = false
        self.storesCollectionViewFlowLayout.scrollDirection = .Vertical
        
        requestFullSync {
            
            dispatch_async(dispatch_get_main_queue(), {
                
                self.storeCategoriesCollectionView.reloadData()
                self.storesCollectionView.reloadData()
                
                // Select "Grocery" as the default Store Category
                self.storeCategoriesCollectionView.selectItemAtIndexPath(NSIndexPath(forItem: self.defaultStoreCategoryIndex, inSection: 0), animated: false, scrollPosition: .CenteredHorizontally)
                
                guard let storeCategories = StoreCategoryModelController.sharedController.getStoreCategories() else { return }
                self.selectedStoreCategory = storeCategories[self.defaultStoreCategoryIndex]
            })
        }
    }
    
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        requestFullSync { 
            
            dispatch_async(dispatch_get_main_queue(), {
                
                self.storeCategoriesCollectionView.reloadData()
                self.storesCollectionView.reloadData()
                
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
            
            if cell.selected == true {
                cell.layer.borderWidth = 1.0
                cell.backgroundColor = UIColor.orangeColor()
                
                self.selectedStoreCategory = storeCategory
                
            } else {
                cell.layer.borderWidth = 0.0
                cell.backgroundColor = UIColor.whiteColor()
            }
            
            returningCell = cell
            
        } else if collectionView == storesCollectionView {
            
            if let selectedStoreCategory = self.selectedStoreCategory {
                
                guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("storeCollectionViewCell", forIndexPath: indexPath) as? StoreCollectionViewCell
                    , store = StoreCategoryModelController.sharedController.getStoresForStoreCategory(selectedStoreCategory)?[indexPath.row]
                    else { return UICollectionViewCell() }
                
                cell.updateWithStore(store)
                
                if cell.selected == true {
                    cell.layer.borderWidth = 1.0
                    cell.backgroundColor = UIColor.brownColor()
                } else {
                    cell.layer.borderWidth = 0.0
                    cell.backgroundColor = UIColor.purpleColor()
                }
                
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
            
            guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? StoreCategoryCollectionViewCell
                else { return }
            
            if cell.selected == true {
                cell.layer.borderWidth = 1.0
                cell.backgroundColor = UIColor.blueColor()
            } else {
                cell.layer.borderWidth = 0.0
                cell.backgroundColor = UIColor.greenColor()
            }
            
            guard let storeCategories = StoreCategoryModelController.sharedController.getStoreCategories()
                else { return }
            
            self.selectedStoreCategory = storeCategories[indexPath.row]
            self.storesCollectionView.reloadData()
            
        } else if collectionView == storesCollectionView {
            
            guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? StoreCollectionViewCell
                else { return }
            
            if cell.selected == true {
                
                cell.layer.borderWidth = 1.0
                cell.backgroundColor = UIColor.blueColor()
                
            } else {
                
                cell.layer.borderWidth = 0.0
                cell.backgroundColor = UIColor.greenColor()
            }
            
        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        
        if collectionView == storeCategoriesCollectionView {
            
            guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? StoreCategoryCollectionViewCell else { return }
            
            if cell.selected == true {
                cell.layer.borderWidth = 1.0
                cell.backgroundColor = UIColor.purpleColor()
            } else {
                cell.layer.borderWidth = 0.0
                cell.backgroundColor = UIColor.darkGrayColor()
            }
            
        } else if collectionView == storesCollectionView {
            
            guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? StoreCollectionViewCell else { return }
            
            if cell.selected == true {
                cell.layer.borderWidth = 1.0
                cell.backgroundColor = UIColor.purpleColor()
            } else {
                cell.layer.borderWidth = 0.0
                cell.backgroundColor = UIColor.darkGrayColor()
            }
            
        }
    }
    
    //==================================================
    // MARK: - UICollectionViewDelegateFlowLayout
    //==================================================
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        var cellWidth: CGFloat = 0
        var cellHeight: CGFloat = 0
        
        if collectionView == storeCategoriesCollectionView {
            
            cellWidth = 70
            cellHeight = 74
            
        } else if collectionView == storesCollectionView {

            cellWidth = self.view.frame.size.width / 2.0 - 20
            cellHeight = cellWidth

        } else {
            
            cellWidth = 50
            cellHeight = 54
        }
        
        return CGSizeMake(cellWidth, cellHeight)
    }
    
    //==================================================
    // MARK: - Methods
    //==================================================
    
    func requestFullSync(completion: (() -> Void)? = nil) {
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        PersistenceController.sharedController.performFullSync {
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            if let completion = completion {
                completion()
            }
        }
    }
    
    //==================================================
    // MARK: - Actions
    //==================================================
    
//    "storeCategoriesToNewStoreSegue"
    
    //==================================================
    // MARK: - Navigation
    //==================================================
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // How are we getting there?
        if segue.identifier == "storeCategoriesToNewStoreSegue" {
            
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
            
        } else if segue.identifier == "storeInStoreCategoryToItemListSegue" {
            
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
                
                // Are we done packing?
                itemsTableViewController.store = stores[index]
            }
        }
    }
    

}
