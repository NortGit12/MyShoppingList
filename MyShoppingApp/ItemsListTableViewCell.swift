//
//  ItemsListTableViewCell.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/31/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import UIKit

class ItemsListTableViewCell: UITableViewCell {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    @IBOutlet weak var checkBoxImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    
    //==================================================
    // MARK: - General
    //==================================================

//    override func awakeFromNib() {
//        super.awakeFromNib()
//        // Initialization code
//    }
//
//    override func setSelected(selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        // Configure the view for the selected state
//    }
    
    //==================================================
    // MARK: - Method(s)
    //==================================================
    
    func updateWithItem(item: Item) {
        
        nameLabel.text = item.name
        quantityLabel.text = item.quantity
    }

}
