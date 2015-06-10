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
    
	@IBOutlet weak var userPhotoImage:   	UIImageView!
    @IBOutlet weak var userNameLabel:       UILabel!
	@IBOutlet weak var toName:              UILabel!
    @IBOutlet weak var descriptionHeight:   NSLayoutConstraint!
    @IBOutlet weak var photoHeight:         NSLayoutConstraint!

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collection = "messages"
        self.photoGroup!.alpha = 0
        self.setPhotoButton.alpha = 0

        if editMode {
            self.progressStartLabel = "Updating"
            self.progressFinishLabel = "Updated!"
            navigationItem.title = LocalizedString("Edit patch")
            self.descriptionField!.placeholder = "Message"
            
            /* Navigation bar buttons */
            var deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: "deleteAction:")
            var doneButton   = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.Plain, target: self, action: "doneAction:")
            self.navigationItem.rightBarButtonItems = [doneButton, spacer, deleteButton]
            
            /* Pull state from patch we are editing */
            bind()
        }
        else {
            self.progressStartLabel = "Posting"
            self.progressFinishLabel = "Posted!"
            
            self.descriptionField!.placeholder = "Message"
            
            if let toString = toString {
                toName.text = toString
            }
            
            if let user = UserController.instance.currentUser {
                self.userPhotoImage.setImageWithPhoto(user.getPhotoManaged())
            }
            
            self.setPhotoButton!.fadeIn()
            
            /* Navigation bar buttons */
            var doneButton   = UIBarButtonItem(title: "Post", style: UIBarButtonItemStyle.Plain, target: self, action: "doneAction:")
            self.navigationItem.rightBarButtonItems = [doneButton]
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    @IBAction override func clearPhotoAction(sender: AnyObject) {
        
        photo = nil
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
        photoChooser.choosePhoto() {
            [unowned self] image in
            
            self.photo = image
            self.usingPhotoDefault = false
            
            if !self.editMode {
                self.photoDirty = (self.photo != nil)
            }
            else {
                self.photoDirty = (self.entity!.photo != self.photo)
            }
            
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
        if entity!.photo != nil {
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
        
        if self.description_!.isEmpty {
            UIAlertView(title: "Enter a message.", message: nil, delegate: nil, cancelButtonTitle: "OK").show()
            return false
        }
        
        return true
    }
    
    /*--------------------------------------------------------------------------------------------
    * Properties
    *--------------------------------------------------------------------------------------------*/

	// Note: did(Appear\Disappear) are called the first time the view appears as well as when the photo
	// chooser view is closed, so it's not a one-time-only call like didLoad

}

