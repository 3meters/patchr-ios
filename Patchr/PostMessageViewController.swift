//
//  PostMessageViewController.swift
//  Patchr
//
//  Created by Brent on 2015-03-09.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation

class PostMessageViewController: UIViewController
{
    // Configured by prior view controller
    var dataStore: DataStore!
    var receiverString: String?
    var patchID: String! // id of patch to post message in
        
    
    lazy var photoChooser: PhotoChooserUI = PhotoChooserUI(hostViewController:self)
    
    @IBOutlet weak var sendButton: UIBarButtonItem!
    @IBOutlet weak var receiverLabel: UILabel!

    @IBOutlet weak var messageTextView: UITextView!
    
    @IBOutlet weak var addPhotoButton: UIButton!
    @IBOutlet weak var attachedImageView: UIImageView!
    @IBOutlet weak var userProfileImage: UIImageView!
    
    @IBAction func sendButtonAction(sender: AnyObject) {
        let parameters: NSMutableDictionary = [
            "description": messageTextView.text!,
            "type": "root",
            "links": [["_to": patchID,
                       "type": "content"]]
        ]

        if attachedImageView.image != nil {
            parameters["photo"] = attachedImageView.image
        }
        
        let proxibase = ProxibaseClient.sharedInstance
        proxibase.createObject("data/messages", parameters: parameters) { _, error in
            if let error = ServerError(error)
            {
                self.ErrorNotificationAlert(LocalizedString("Failed to create message"), message: error.message)
            }
            else
            {
                dispatch_async(dispatch_get_main_queue()) {
                    self.performSegueWithIdentifier("CreateMessageUnwindToPatchDetail", sender: nil)
                }
            }
        }
    }
    
    // Dismiss the keyboard by tapping outside the message view.
    
    @IBAction func tapOutsideMessageView(sender: AnyObject) {
        if messageTextView.isFirstResponder() {
            messageTextView.endEditing(false)
        }
    }
    
    @IBAction func addPhotoButtonAction(sender: AnyObject) {
        let heightConstraint = self.attachedImageView.constraints()[0] as NSLayoutConstraint
        if self.attachedImageView.image == nil {
            photoChooser.choosePhoto() { [unowned self] image in
                self.addPhotoButton.setTitle(LocalizedString("Remove Photo"), forState: .Normal)
                heightConstraint.constant = 200 // or whatever
                self.attachedImageView.image = image
                self.messageTextView.scrollRangeToVisible(self.messageTextView.selectedRange)
                self.updatePostButton()
            }
        }
        else
        {
            addPhotoButton.setTitle(LocalizedString("Add Photo"), forState: .Normal)
            heightConstraint.constant = 46 // or whatever
            attachedImageView.image = nil
            updatePostButton()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let receiverString = receiverString {
            receiverLabel.text = receiverString
        }
        
        dataStore.withCurrentUser(completion: { user in
            if let photoURL = user.photo?.photoURL() {
                self.userProfileImage.pa_setImageWithURL(photoURL)
            }
        })
    }
    
    var observerObject: TextViewChangeObserver! = nil

    private func updatePostButton() {
        let hasContent = (attachedImageView.image != nil) || (messageTextView.text.utf16Count > 0)
        sendButton.enabled = hasContent
    }
    
    // Note: did(Appear\Disappear) are called the first time the view appears as well as when the photo
    // chooser view is closed, so it's not a one-time-only call like didLoad
    
    override func viewDidAppear(animated: Bool) {
        assert(messageTextView.window != nil) // requirement for calling becomeFirstResponder
        messageTextView.becomeFirstResponder()
        
        observerObject = TextViewChangeObserver(messageTextView) { [unowned self] in
            self.updatePostButton()
            
            #if DEBUG
            if self.messageTextView.text == "Here's to the crazy ones." {
                self.messageTextView.text = "Here's to the crazy ones, the misfits, the rebels, the troublemakers, the round pegs in the square holes... the ones who see things differently -- they're not fond of rules... You can quote them, disagree with them, glorify or vilify them, but the only thing you can't do is ignore them because they change things... they push the human race forward, and while some may see them as the crazy ones, we see genius, because the ones who are crazy enough to think that they can change the world, are the ones who do.\n\nHere's to the crazy ones, the misfits, the rebels, the troublemakers, the round pegs in the square holes... the ones who see things differently -- they're not fond of rules... You can quote them, disagree with them, glorify or vilify them, but the only thing you can't do is ignore them because they change things... they push the human race forward, and while some may see them as the crazy ones, we see genius, because the ones who are crazy enough to think that they can change the world, are the ones who do.\n"
            }
            #endif
        }
    }

    
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(observerObject)
    }
}

