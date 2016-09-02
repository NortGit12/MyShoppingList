//
//  AllStoresTableViewCell.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 9/1/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import UIKit

protocol AllStoresTableViewCellDelegate {
    
    func editStoreButtonTapped(cell: AllStoresTableViewCell)
}

class AllStoresTableViewCell: UITableViewCell {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    var delegate: AllStoresTableViewCellDelegate?
    
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
    
    @IBAction func editStoreButtonTapped(sender: UIButton) {
        
        if let delegate = delegate {
            
            delegate.editStoreButtonTapped(self)
        }
    }
}
