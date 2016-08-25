//
//  StoreCollectionViewCell.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/25/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import UIKit

class StoreCollectionViewCell: UICollectionViewCell {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    //==================================================
    // MARK: - Method(s)
    //==================================================
    
    func updateWithStore(store: Store) {
        
        imageView.image = UIImage(data: store.image)
        nameLabel.text = store.name
    }
}
