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
    
    //==================================================
    // MARK: - General
    //==================================================

    override func viewDidLoad() {
        super.viewDidLoad()
        
        categoriesCollectionView.allowsMultipleSelection = false
        categoriesCollectionViewFlowLayout.scrollDirection = .Horizontal
    }
    
    //==================================================
    // MARK: - UICollectionViewDataSource
    //==================================================
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return StoreCategoryModelController.sharedController.getStoreCategories()?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("storeCategoryCollectionViewCell", forIndexPath: indexPath) as? StoreCategoryCollectionViewCell
            , storeCategory = StoreCategoryModelController.sharedController.getStoreCategories()?[indexPath.row]
            else { return UICollectionViewCell() }
        
        cell.updateWithStoreCategory(storeCategory)
        
        if cell.selected == true {
            cell.layer.borderWidth = 2.0
            cell.backgroundColor = UIColor.orangeColor()
        } else {
            cell.layer.borderWidth = 0.0
            cell.backgroundColor = UIColor.whiteColor()
        }
        
        return cell
    }
    
    //==================================================
    // MARK: - UICollectionViewDelegate
    //==================================================
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? StoreCategoryCollectionViewCell else {
            
            print("Exiting in the else of didSelectItemAtIndexPath")
            return
        }
        
        if cell.selected == true {
            cell.layer.borderWidth = 2.0
            cell.backgroundColor = UIColor.blueColor()
        } else {
            cell.layer.borderWidth = 0.0
            cell.backgroundColor = UIColor.whiteColor()
        }
        
//        cell.layer.borderWidth = 2.0
//        cell.layer.backgroundColor = UIColor.blueColor().CGColor
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        
        guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? StoreCategoryCollectionViewCell else { return }
        
        if cell.selected == true {
            cell.layer.borderWidth = 2.0
            cell.backgroundColor = UIColor.blueColor()
        } else {
            cell.layer.borderWidth = 0.0
            cell.backgroundColor = UIColor.whiteColor()
        }
        
        //        cell.layer.borderWidth = 2.0
        //        cell.layer.backgroundColor = UIColor.blueColor().CGColor
    }
    
    //==================================================
    // MARK: - Navigation
    //==================================================
    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
