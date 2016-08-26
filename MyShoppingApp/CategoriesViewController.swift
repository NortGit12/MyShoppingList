//
//  CategoriesViewController.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/23/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import UIKit

class CategoriesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    @IBOutlet weak var categoriesCollectionView: UICollectionView!
    @IBOutlet weak var categoriesCollectionViewFlowLayout: UICollectionViewFlowLayout!
    var selectedStoreCategory: StoreCategory?
    @IBOutlet weak var storeCollectionView: UICollectionView!
    @IBOutlet weak var storeCollectionViewFlowLayout: UICollectionViewFlowLayout!
    
    //==================================================
    // MARK: - General
    //==================================================

    override func viewDidLoad() {
        super.viewDidLoad()
        
        categoriesCollectionView.allowsMultipleSelection = false
        categoriesCollectionViewFlowLayout.scrollDirection = .Horizontal
        
        storeCollectionView.allowsMultipleSelection = false
        storeCollectionViewFlowLayout.scrollDirection = .Vertical
        
        // Select "Grocery" as the default Store Category
        categoriesCollectionView.selectItemAtIndexPath(NSIndexPath(forItem: 4, inSection: 0), animated: false, scrollPosition: .CenteredHorizontally)
    }
    
    //==================================================
    // MARK: - UICollectionViewDataSource
    //==================================================
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        var numberOfItemsInSection = 0
        
        if collectionView == categoriesCollectionView {
            
            numberOfItemsInSection = StoreCategoryModelController.sharedController.getStoreCategories()?.count ?? 0
            
        } else if collectionView == storeCollectionView {
            
            if let selectedStoreCategory = self.selectedStoreCategory {
                
                numberOfItemsInSection = StoreCategoryModelController.sharedController.getStoresForStoreCategory(selectedStoreCategory)?.count ?? 0
            }
        }
        
        return numberOfItemsInSection
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        var returningCell = UICollectionViewCell()
        
        if collectionView == categoriesCollectionView {
            
            guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("storeCategoryCollectionViewCell", forIndexPath: indexPath) as? StoreCategoryCollectionViewCell
                , storeCategory = StoreCategoryModelController.sharedController.getStoreCategories()?[indexPath.row]
                else { return UICollectionViewCell() }
            
            cell.updateWithStoreCategory(storeCategory)
            
            if cell.selected == true {
                cell.layer.borderWidth = 1.0
                cell.backgroundColor = UIColor.orangeColor()
            } else {
                cell.layer.borderWidth = 0.0
                cell.backgroundColor = UIColor.whiteColor()
            }
            
            returningCell = cell
            
        } else if collectionView == storeCollectionView {
        
            guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("storeCollectionViewCell", forIndexPath: indexPath) as? StoreCollectionViewCell
                , store = StoreModelController.sharedController.getStores()?[indexPath.row]
                else { return UICollectionViewCell() }
            
            cell.updateWithStore(store)
            
            if cell.selected == true {
                cell.layer.borderWidth = 1.0
                cell.backgroundColor = UIColor.orangeColor()
            } else {
                cell.layer.borderWidth = 0.0
                cell.backgroundColor = UIColor.whiteColor()
            }
            
            returningCell = cell
        }
        
        return returningCell
    }
    
    //==================================================
    // MARK: - UICollectionViewDelegate
    //==================================================
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if collectionView == categoriesCollectionView {
            
            guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? StoreCategoryCollectionViewCell
                else { return }
            
            if cell.selected == true {
                cell.layer.borderWidth = 1.0
                cell.backgroundColor = UIColor.blueColor()
            } else {
                cell.layer.borderWidth = 0.0
                cell.backgroundColor = UIColor.greenColor()
            }
            
        } else if collectionView == storeCollectionView {
            
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
        
        if collectionView == categoriesCollectionView {
            
            guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? StoreCategoryCollectionViewCell else { return }
            
            if cell.selected == true {
                cell.layer.borderWidth = 1.0
                cell.backgroundColor = UIColor.purpleColor()
            } else {
                cell.layer.borderWidth = 0.0
                cell.backgroundColor = UIColor.darkGrayColor()
            }
            
        } else if collectionView == storeCollectionView {
            
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
                guard let index = categoriesCollectionView.indexPathsForSelectedItems()?.first?.row
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
    }
    

}
