//
//  NewItemViewController.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/31/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import UIKit

class NewItemViewController: UIViewController {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var quantityTextField: UITextField!
    @IBOutlet weak var notesTextView: UITextView!
    
    var store: Store?
    
    //==================================================
    // MARK: - General
    //==================================================

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    //==================================================
    // MARK: - Action(s)
    //==================================================
    
    @IBAction func saveButtonTapped(sender: UIBarButtonItem) {
        
        guard let store = self.store
            , name = nameTextField.text where name.characters.count > 0
            , let quantity = quantityTextField.text where quantity.characters.count > 0
            else {
                
                NSLog("Error: Not all required values could be retrieved from the view elements.")
                return
        }
        
        let notes: String?
        if notesTextView.text.characters.count > 0 {
            notes = notesTextView.text
        } else {
            notes = nil
        }
        
        ItemModelController.sharedController.createItem(name, quantity: quantity, notes: notes, store: store)
        
        dismissViewControllerAnimated(true, completion: nil)
    }
}
