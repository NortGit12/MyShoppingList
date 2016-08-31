//
//  ItemDetailViewController.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/30/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import UIKit

class ItemDetailViewController: UIViewController {
    
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

        if let item = item {
            
            updateWithItem(item)
        }
        
        nameTextField.becomeFirstResponder()
    }
    
    //==================================================
    // MARK: - Methods
    //==================================================
    
    func updateWithItem(item: Item) {
        
        nameTextField.text = item.name
        quantityTextField.text = item.quantity
        notesTextView.text = item.notes
    }
    
    //==================================================
    // MARK: - Action(s)
    //==================================================
    
    @IBAction func cancelButtonTapped(sender: UIBarButtonItem) {
        
        dismissViewControllerAnimated(true, completion: nil)
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
            
            
            
        // Save a new Item
        } else {
            
            ItemModelController.sharedController.createItem(name, quantity: quantity, notes: notes, store: store)
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func clearButtonTapped(sender: UIButton) {
        
        nameTextField.text = ""
        quantityTextField.text = ""
        notesTextView.text = ""
        
        nameTextField.becomeFirstResponder()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
