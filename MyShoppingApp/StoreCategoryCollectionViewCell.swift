//
//  StoreCategoryCollectionViewCell.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/23/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import UIKit

class StoreCategoryCollectionViewCell: UICollectionViewCell {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    @IBOutlet weak var roundedCategoryImageView: UIImageView!
    @IBOutlet weak var categoryNameLabel: UILabel!
    
    //==================================================
    // MARK: - Methods
    //==================================================
    
    func updateWithStoreCategory(storeCategory: StoreCategory) {
        
        roundedCategoryImageView.layer.cornerRadius = roundedCategoryImageView.frame.height / 2
        
        roundedCategoryImageView.image = UIImage(data: storeCategory.image)
        categoryNameLabel.text = storeCategory.name
    }
    
}
