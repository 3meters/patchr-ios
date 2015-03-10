//
//  MessageViewController.swift
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
            "description": messageTextView.text!
        ]

        if attachedImageView.image != nil {
            parameters["photo"] = attachedImageView.image
        }
        
        let proxibase = ProxibaseClient.sharedInstance
        proxibase.createObject("data/messages", parameters: parameters) { response, error in
            if let error = ServerError(error)
            {
                println("## Create Message POST request failed")
                println("Parameters:")
                println(parameters)
                println("Error:")
                println(error)
            }
            else
            {
                println("!! Message create success")
                println(response)
                
                if let messageID = (response?["data"] as NSDictionary?)?["_id"] as? String
                {
                    proxibase.createLink(fromType: .User, fromID: nil, linkType: .Create, toType: .Message, toID: messageID) { response, error in
                        if let error = ServerError(error) {
                            println("Link 1 (Create) Create Error")
                            println(error)
                        }
                    }
                    proxibase.createLink(fromType: .Message, fromID: messageID, linkType: .Content, toType: .Patch, toID: self.patchID) { response, error in
                        if let error = ServerError(error) {
                            println("Link 2 (Content) Create Error")
                            println(error)
                        }
                    }
                    self.performSegueWithIdentifier("CreateMessageUnwindToPatchDetail", sender: nil)
                }
            }
        }
        println("send")
    }
    @IBAction func addPhotoButtonAction(sender: AnyObject) {
        println("add photo")
        photoChooser.choosePhoto() { image in
            
            let heightConstraint = self.attachedImageView.constraints()[0] as NSLayoutConstraint
            heightConstraint.constant = 200
            self.attachedImageView.image = image
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let receiverString = receiverString {
            receiverLabel.text = receiverString
        }
        
        dataStore.withCurrentUser(completion: { user in
            self.userProfileImage.setImageWithURL(user.photo.photoURL())
        })
    }
}

