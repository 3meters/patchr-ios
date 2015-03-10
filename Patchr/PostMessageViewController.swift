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
    lazy var photoChooser: PhotoChooserUI = PhotoChooserUI(hostViewController:self)
    
    @IBOutlet weak var sendButton: UIBarButtonItem!
    @IBOutlet weak var receiverLabel: UILabel!

    @IBOutlet weak var messageTextView: UITextView!
    
    @IBOutlet weak var addPhotoButton: UIButton!
    @IBOutlet weak var attachedImageView: UIImageView!
    
    @IBAction func sendButtonAction(sender: AnyObject) {
        println("send")
    }
    @IBAction func addPhotoButtonAction(sender: AnyObject) {
        println("add photo")
        photoChooser.choosePhoto() { _ in
            println("chosen")
        }
    }
}

