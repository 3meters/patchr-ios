//
//  PostMessageViewController.swift
//  Patchr
//
//  Created by Brent on 2015-03-09.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation

class MessageEditViewController: EntityEditViewController {

	var toString: String?	// name of patch this message links to
    var patchId: String?    // id of patch this message links to
    var photoChosen: Bool = false
    
	@IBOutlet weak var userPhotoImage:   	UIImageView!
    @IBOutlet weak var userNameLabel:       UILabel!
	@IBOutlet weak var toName:              UILabel!
    
    @IBOutlet weak var descriptionCell: UITableViewCell!
    @IBOutlet weak var photoCell: UITableViewCell!

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collection = "messages"
        self.photoGroup!.alpha = 0
        self.setPhotoButton.alpha = 0
        self.descriptionField!.placeholder = "Message"
        
        if editMode {
            
            self.progressStartLabel = "Updating"
            self.progressFinishLabel = "Updated!"
            navigationItem.title = LocalizedString("Edit patch")
            
            /* Navigation bar buttons */
            var deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: "deleteAction:")
            var doneButton   = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.Plain, target: self, action: "doneAction:")
            self.navigationItem.rightBarButtonItems = [doneButton, spacer, deleteButton]
            
            /* Box the description to make edit mode more obvious */
            self.descriptionField!.borderWidth = 0.5
            self.descriptionField!.borderColor = AirUi.windowColor
            self.descriptionField!.cornerRadius = 4
            self.descriptionField!.textContainer.lineFragmentPadding = 0
            self.descriptionField!.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8)
            
            /* Pull state from patch we are editing */
            bind()
        }
        else {
            
            self.progressStartLabel = "Posting"
            self.progressFinishLabel = "Posted!"
            self.descriptionField!.placeholderColor = UIColor.clearColor()
            
            if let toString = toString {
                toName.text = toString
            }
            
            if let user = UserController.instance.currentUser {
                self.userPhotoImage.setImageWithPhoto(user.getPhotoManaged())
                self.userNameLabel.text = user.name
            }
            
            self.setPhotoButton!.fadeIn()
            
            /* Navigation bar buttons */
            var doneButton   = UIBarButtonItem(title: "Post", style: UIBarButtonItemStyle.Plain, target: self, action: "doneAction:")
            self.navigationItem.rightBarButtonItems = [doneButton]
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        if photoChosen {
            photoChosen = false
            var rowFrame = self.tableView.rectForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0))
            var currentOffsetBottom = self.tableView.contentOffset.y + self.tableView.frame.size.height
            var currentRowBottom = rowFrame.origin.y + rowFrame.size.height
            var newOffset = self.tableView.contentOffset.y + (currentRowBottom - currentOffsetBottom)
            if newOffset > 0 {
                self.tableView.setContentOffset(CGPoint(x: 0, y: newOffset), animated: true)
            }
        }
        
        if !editMode && self.firstAppearance {
            self.descriptionField.becomeFirstResponder()
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    @IBAction override func clearPhotoAction(sender: AnyObject) {
        
        photo = nil
        self.photoActive = false
        self.tableView.reloadData() // Triggers row resizing
        self.setPhotoButton!.fadeIn()
        self.photoGroup!.fadeOut()
        
        if editMode {
            self.photoDirty = (entity!.photo != photo)
        }
        else {
            self.photoDirty = false
        }
    }
    
    @IBAction override func setPhotoAction(sender: AnyObject) {
        
        /* This completion block gets called before the controller reappears. */
        photoChooser.choosePhoto() {
            [unowned self] image, imageResult in
            
            if image != nil {
                self.photo = image
            }
            else {
                self.photoImage.setImageWithImageResult(imageResult!, animate: true)
            }
            
            self.photoChosen = true
            self.usingPhotoDefault = false
            self.photoActive = true
            
            if !self.editMode {
                self.photoDirty = (self.photo != nil)
            }
            else {
                self.photoDirty = (self.entity!.photo != self.photo)
            }
            /*
             * We need to make sure heightForRowAtIndexPath gets fired
             * to reset the cell height to accomodate the photo. viewDidAppear
             * has logic to make sure the photo is scrolled into view.
             */
            self.tableView.reloadData()
            
            /* Toggle display */
            self.setPhotoButton!.fadeOut()
            self.photoGroup!.fadeIn()
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    override func bind() {
        super.bind()
        
        /* Only called once when controller is loaded */
        
        let message = entity as! Message
        
        /* User photo */
        self.userPhotoImage.setImageWithPhoto(message.creator.getPhotoManaged())
        self.userNameLabel.text = message.creator.name
        
        /* Primary photo */
        if self.photoActive {
            self.photoGroup!.fadeIn()
        }
        else {
            self.setPhotoButton!.fadeIn()
        }
    }
    
    override func gather(parameters: NSMutableDictionary) -> NSMutableDictionary {
        
        var parameters = super.gather(parameters)
        
        if !editMode {
            parameters["links"] = [["type": "content", "_to": self.patchId!]]
        }
        return parameters
    }
    
    override func isValid() -> Bool {
        
        if ((self.description_ == nil || self.description_!.isEmpty) && self.photo == nil) {
            Alert("Add message or photo", message: nil, cancelButtonTitle: "OK")
            return false
        }
        
        return true
    }
    
    override func performBack(animated: Bool = true) {
        self.performSegueWithIdentifier("UnwindFromMessageEdit", sender: self)
    }
    
    /*--------------------------------------------------------------------------------------------
    * Properties
    *--------------------------------------------------------------------------------------------*/

}

extension MessageEditViewController: UITableViewDelegate{
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if indexPath.row == 1 { // Description
                var height: CGFloat = textViewHeightForRowAtIndexPath(indexPath)
                return height < 48 ? 48 : height
            }
            else if indexPath.row == 2 { // Photo
                /* Size so photo aspect ratio is 4:3 */
                var height: CGFloat = ((UIScreen.mainScreen().bounds.size.width - 32) * 0.75) + 16
                if !self.photoActive {
                    height = 64 // Leave enough room for set photo button
                }
                return height
            }
        }
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }
    
    private func textViewHeightForRowAtIndexPath(indexPath: NSIndexPath) -> CGFloat {
        let textViewWidth: CGFloat = descriptionField!.frame.size.width
        let size: CGSize = descriptionField.sizeThatFits(CGSizeMake(textViewWidth, CGFloat(FLT_MAX)))
        return size.height;
    }
}

extension EntityEditViewController: UITextViewDelegate {
    
    func textViewDidEndEditing(textView: UITextView) {
        self.descriptionField.placeholderColor = UIColor.lightGrayColor()
    }
}


