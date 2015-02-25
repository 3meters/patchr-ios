//
//  RegistrationTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-24.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class RegistrationTableViewController: UITableViewController {

    @IBOutlet weak var doneBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var avatarSetButton: UIButton!
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    @IBAction func avatarSetButtonAction(sender: AnyObject) {
        NSLog("TODO Not implemented")
    }
    
    @IBAction func joinButtonAction(sender: AnyObject) {
        NSLog("TODO Not implemented")
    }
    
    @IBAction func termsOfServiceButtonAction(sender: AnyObject) {
        UIApplication.sharedApplication().openURL(NSURL(string: "http://patchr.com/terms")!)
    }
    
}
