//
//  NewStoreViewController.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/24/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import UIKit
import SafariServices

class NewStoreViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    //==================================================
    // MARK: - Stored Properties
    //==================================================
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var selectImageButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var storeCategoriesTableView: UITableView!
    
    var store: Store?
    var indexPathRowOfSelectedStoreCategory = -1
    var selectedStoreCategory: StoreCategory?
    
    //==================================================
    // MARK: - General
    //==================================================

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let store = store {
            
            updateWithStore(store)
            
        } else {
            
            imageView.image = UIImage(named: "default-image_store")
        }

        nameTextField.becomeFirstResponder()
    }
    
    //==================================================
    // MARK: - UITableviewDataSource
    //==================================================
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return StoreCategoryModelController.sharedController.getStoreCategories()?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCellWithIdentifier("newStoreCategoryCell", forIndexPath: indexPath) as? NewStoreCategoryTableViewCell
            , storeCategory = StoreCategoryModelController.sharedController.getStoreCategories()?[indexPath.row]
            else { return UITableViewCell() }
        
        if self.store != nil {
        
            if store!.categories.containsObject(storeCategory) {
                
                storeCategoriesTableView.selectRowAtIndexPath(NSIndexPath(forItem: indexPath.row, inSection: 0), animated: true, scrollPosition: .None)
                cell.accessoryType = .Checkmark
            }
            
        } else if storeCategory == selectedStoreCategory {
            
            storeCategoriesTableView.selectRowAtIndexPath(NSIndexPath(forItem: indexPath.row, inSection: 0), animated: true, scrollPosition: .None)
            cell.accessoryType = .Checkmark
            
        }
        
        cell.updateWithStoreCategory(storeCategory)
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = .Checkmark
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = .None
    }
    
    //==================================================
    // MARK: - Actions
    //==================================================
    
    @IBAction func cancelButtonTapped(sender: UIButton) {
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func saveButtonTapped(sender: UIButton) {
        
        // What do we need to pack?
        
        guard let name = nameTextField.text where name.characters.count > 0
            , let indexPaths = storeCategoriesTableView.indexPathsForSelectedRows
            , image = imageView.image
            else {
                
                NSLog("Error: Could not collect the required values for name, image, or index paths for store categories.")
                return
        }
        
        var storeCategories = [StoreCategory]()
        for indexPath in indexPaths {
            
            if let storeCategory = StoreCategoryModelController.sharedController.getStoreCategories()?[indexPath.row] {
                
                storeCategories.append(storeCategory)
            }
        }
        
        StoreModelController.sharedController.createStore(name, image: image, categories: storeCategories)
        
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
            
            guard let googleImagesUrl = NSURL(string: "https://www.google.com/imghp?gws_rd=ssl") else { return }
            
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
        
        self.presentViewController(imageActionSheet, animated: true, completion: nil)
    }
    
    //==================================================
    // MARK: - Method(s)
    //==================================================

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else { return }
        
        selectImageButton.setTitle("", forState: .Normal)
        imageView.image = image
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func updateWithStore(store: Store) {
        
        nameTextField.text = store.name
        imageView.image = UIImage(data: store.image)
        
        storeCategoriesTableView.reloadData()
    }
}






















