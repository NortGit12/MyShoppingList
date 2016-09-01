//
//  AllStoresTableViewCell.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 9/1/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import UIKit

class AllStoresTableViewCell: UITableViewCell {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    //==================================================
    // MARK: - Method(s)
    //==================================================
    
    func updateWithStore(store: Store) {
        
        iconImageView.image = UIImage(data: store.image)
        nameLabel.text = store.name
    }
    
    //==================================================
    // MARK: - Action(s)
    //==================================================
    
    @IBAction func editButtonTapped(sender: UIButton) {
        
        
    }
}
