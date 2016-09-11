//
//  ItemDetailViewController.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/30/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import UIKit

class ItemDetailViewController: UIViewController, UITextFieldDelegate {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var quantityTextField: UITextField!
    @IBOutlet weak var notesTextView: UITextView!
    
    var store: Store?
    var item: Item?
    
    //==================================================
    // MARK: - General
    //==================================================

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAppearance()
        
        self.hideKeyboardWhenTappedAround()

        if let item = item {
            
            updateWithItem(item)
        }
        
        nameTextField.becomeFirstResponder()
    }
    
    //==================================================
    // MARK: - UITextFieldDelegate
    //==================================================
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        return textField.endEditing(true)
    }
    
    //==================================================
    // MARK: - Methods
    //==================================================
    
    func setupAppearance() {
        
        nameTextField.backgroundColor = .basicBlueColor()
        nameTextField.attributedPlaceholder = NSAttributedString(string: "Name...", attributes: [NSForegroundColorAttributeName: UIColor.basicGrayColor()])
        
        quantityTextField.backgroundColor = .basicBlueColor()
        quantityTextField.attributedPlaceholder = NSAttributedString(string: "Quantity... (2, 1-3pk, etc.)", attributes: [NSForegroundColorAttributeName: UIColor.basicGrayColor()])
        
        notesTextView.backgroundColor = .basicBlueColor()
        notesTextView.attributedText = NSAttributedString(string: "", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
    }
    
    func updateWithItem(item: Item) {
        
        nameTextField.textColor = .whiteColor()
        quantityTextField.textColor = .whiteColor()
        notesTextView.textColor = .whiteColor()
        
        nameTextField.text = item.name
        quantityTextField.text = item.quantity
        notesTextView.text = item.notes
    }
    
    //==================================================
    // MARK: - Action(s)
    //==================================================
    
    @IBAction func cancelButtonTapped(sender: UIBarButtonItem) {
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func saveButtonTapped(sender: UIBarButtonItem) {
        
        guard let store = store
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
        
        // Update an existing Item
        if let item = item {
            
            item.name = name
            item.quantity = quantity
            item.notes = notes
            
            ItemModelController.sharedController.updateItem(item, store: store)
            
        // Save a new Item
        } else {
            
            ItemModelController.sharedController.createItem(name, quantity: quantity, notes: notes, store: store)
        }
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func clearButtonTapped(sender: UIButton) {
        
        nameTextField.text = ""
        quantityTextField.text = ""
        notesTextView.text = ""
        
        nameTextField.becomeFirstResponder()
    }
}
