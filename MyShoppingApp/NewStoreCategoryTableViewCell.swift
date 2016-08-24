//
//  NewStoreCategoryTableViewCell.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/24/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import UIKit

class NewStoreCategoryTableViewCell: UITableViewCell {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    @IBOutlet weak var nameLabel: UILabel!
    
    //==================================================
    // MARK: - General
    //==================================================

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    //==================================================
    // MARK: - Method(s)
    //==================================================

    func updateWithStoreCategory(storeCategory: StoreCategory) {
        
        nameLabel.text = storeCategory.name
    }
}
