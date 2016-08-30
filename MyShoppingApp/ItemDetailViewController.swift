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
