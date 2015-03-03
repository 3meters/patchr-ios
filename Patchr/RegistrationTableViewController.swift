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
    
        let parameters = NSMutableDictionary()
        ProxibaseClient.sharedInstance.createUser(fullNameTextField.text, email: emailTextField.text, password: passwordTextField.text, parameters: parameters) { (response, error) in
            
            if error == nil {
                // Successful registration and sign-in. Move to the main scene.
                let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
                let viewController = UIStoryboard(name:"Main", bundle:NSBundle.mainBundle()).instantiateInitialViewController() as UIViewController;
                appDelegate.window!.setRootViewController(viewController, animated: true)
            }
            // TODO: What could go wrong here?
        }
    }
    
    @IBAction func termsOfServiceButtonAction(sender: AnyObject) {
        UIApplication.sharedApplication().openURL(NSURL(string: "http://patchr.com/terms")!)
    }
    
    var observerObject: NSObjectProtocol? = nil

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        observerObject = notificationCenter.addObserverForName(UITextFieldTextDidChangeNotification, object: nil, queue: nil)
        { _ in
            self.joinButton.enabled = (self.fullNameTextField.text.utf16Count > 0) &&
                                      (self.passwordTextField.text.utf16Count >= 6) &&
                                      (self.emailTextField.text.utf16Count > 0)
                                      // TODO: Better screening for email addresses
        }
    }

    override func viewWillDisappear(animated: Bool) {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        if let observer = observerObject {
            notificationCenter.removeObserver(observer)
        }
    }
}
