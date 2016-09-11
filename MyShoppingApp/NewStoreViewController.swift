//
//  NewStoreViewController.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/24/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import UIKit
import SafariServices

class NewStoreViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var selectImageButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var storeCategoriesTableView: UITableView!
    
    var store: Store?
    var allStoreCategories: [StoreCategory]?
    var selectedStoreCategory: StoreCategory?
    
    //==================================================
    // MARK: - General
    //==================================================

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.tabBar.hidden = true
        
        setupAppearance()
        
//        self.hideKeyboardWhenTappedAround()
        
//        StoreCategoryModelController.sharedController.fetchStoreCategoriesWithCompletion({ (categories) in
//            
//            if let categories = categories {
//            
//                self.allStoreCategories = categories
//            }
//        })
        
        allStoreCategories = StoreCategoryModelController.sharedController.fetchStoreCategories()
        
        if let store = store {
            
            updateWithStore(store)
            
        } else {
            
            imageView.image = UIImage(named: "default-image_store")
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
    // MARK: - UITableviewDataSource
    //==================================================
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.allStoreCategories?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCellWithIdentifier("newStoreCategoryCell", forIndexPath: indexPath) as? NewStoreCategoryTableViewCell
            , allStoreCategories = self.allStoreCategories  // #3
            else {
                
                NSLog("Error: Could not either cast the UITableViewCell to a NewStoreCategoryTableViewCell or identify the StoreCategory for the selected cell.")
                return UITableViewCell()
            }
        
        let storeCategory = allStoreCategories[indexPath.row]  // #3
        
        if self.store != nil {
        
            if store!.categories.containsObject(storeCategory) {
                
                storeCategoriesTableView.selectRowAtIndexPath(NSIndexPath(forItem: indexPath.row, inSection: 0), animated: true, scrollPosition: .None)
                cell.contentView.backgroundColor = .basicGrayColor()
                cell.isSelected(true)
            } else {
                cell.isSelected(false)
            }
            
        } else if storeCategory == selectedStoreCategory {
            
            storeCategoriesTableView.selectRowAtIndexPath(NSIndexPath(forItem: indexPath.row, inSection: 0), animated: true, scrollPosition: .None)
            cell.contentView.backgroundColor = .basicGrayColor()
            cell.isSelected(true)
            
        }
        
        cell.updateWithStoreCategory(storeCategory)
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) as? NewStoreCategoryTableViewCell else {
            
            NSLog("Error: Selected Store Category Cell in New Store view could not be identified.")
            return
        }
        
        cell.contentView.backgroundColor = .basicGrayColor()
        cell.isSelected(true)
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) as? NewStoreCategoryTableViewCell else {
            
            NSLog("Error: Selected Store Category Cell in New Store view could not be identified.")
            return
        }
        
        cell.contentView.backgroundColor = .whiteColor()
        cell.isSelected(false)
    }
    
    func setupAppearance() {
        
        nameTextField.backgroundColor = .basicBlueColor()
        nameTextField.attributedPlaceholder = NSAttributedString(string: "Name...", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
    }
    
    //==================================================
    // MARK: - Actions
    //==================================================
    
    @IBAction func cancelButtonTapped(sender: UIButton) {
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func saveButtonTapped(sender: UIButton) {
        
        // Gather all of the Store's data
        guard let name = nameTextField.text where name.characters.count > 0
            , let indexPaths = storeCategoriesTableView.indexPathsForSelectedRows
            , image = imageView.image
            , imageData = UIImagePNGRepresentation(image)
            else {
                
                NSLog("Error: Could not collect the required values for name, image, or index paths for store categories.")
                return
        }
        
        var storeCategories = [StoreCategory]()
        for indexPath in indexPaths {
            
            if let allStoreCategories = allStoreCategories {
                
                let storeCategory = allStoreCategories[indexPath.row]
                storeCategories.append(storeCategory)
            }
        }
        
        // Update an existing Store
        if let store = store {
            
            store.name = name
            store.image = imageData
            store.categories = NSOrderedSet(array: storeCategories)
            
            StoreModelController.sharedController.updateStore(store)
            
        // Create a new Store
        } else {
        
            StoreModelController.sharedController.createStore(name, image: image, categories: storeCategories)
        }
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func selectImageButtonTapped(sender: UIButton) {
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        let imageActionSheet = UIAlertController(title: "Choose an image source", message: nil, preferredStyle: .ActionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .Default) { (_) in
            
            imagePicker.sourceType = .PhotoLibrary
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
        
        let savedPhotosAction = UIAlertAction(title: "Saved Photos", style: .Default) { (_) in
            
            imagePicker.sourceType = .SavedPhotosAlbum
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
        
        let cameraAction = UIAlertAction(title: "Camera", style: .Default) { (_) in
            
            imagePicker.sourceType = .Camera
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
        
        let browserAction = UIAlertAction(title: "Browser", style: .Default) { (_) in
            
            guard let googleImagesUrl = NSURL(string: "https://www.google.com/imghp?gws_rd=ssl") else {
                
                NSLog("Error: Could not create the Google Images URL.")
                return
            }
            
            let safariViewController = SFSafariViewController(URL: googleImagesUrl)
            
            self.presentViewController(safariViewController, animated: true, completion: nil)
        }
        
        imageActionSheet.addAction(cancelAction)
        imageActionSheet.addAction(browserAction)
        
        if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) {
            
            imageActionSheet.addAction(photoLibraryAction)
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.SavedPhotosAlbum) {
            
            imageActionSheet.addAction(savedPhotosAction)
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            
            imageActionSheet.addAction(cameraAction)
        }
        
        imageActionSheet.popoverPresentationController?.sourceView = sender
        imageActionSheet.popoverPresentationController?.sourceRect = sender.bounds
        
        self.presentViewController(imageActionSheet, animated: true, completion: nil)
    }
    
    //==================================================
    // MARK: - Method(s)
    //==================================================

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            
            NSLog("Error: Could not get the ImagePicker's original image.")
            return
        }
        
        selectImageButton.setTitle("", forState: .Normal)
        imageView.image = image
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func updateWithStore(store: Store) {
        
        nameTextField.text = store.name
        imageView.image = UIImage(data: store.image)
        
        guard let defaultStoreImage = UIImage(named: "default-image_store")
            , defaultStoreImageData = UIImagePNGRepresentation(defaultStoreImage)
            else {
                
                NSLog("Error: Could not access the default image or its data.")
                return
            }
        
        if store.image != defaultStoreImageData {
            
            selectImageButton.setTitle("", forState: .Normal)
        }
        
        storeCategoriesTableView.reloadData()
    }
}






















