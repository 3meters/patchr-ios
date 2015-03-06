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

    lazy var photoChooserUI: PhotoChooserUI = { PhotoChooserUI(hostViewController: self) }()
    
    @IBAction func avatarSetButtonAction(sender: AnyObject) {
        photoChooserUI.choosePhoto() { uiImage in
            self.avatarImageView.image = uiImage
        }
    }
    
    @IBAction func joinButtonAction(sender: AnyObject) {
    
        let parameters = NSMutableDictionary()
        let proxibase = ProxibaseClient.sharedInstance
        let queue = dispatch_queue_create("join-queue", DISPATCH_QUEUE_SERIAL)
        let semaphore = dispatch_semaphore_create(0)
        
        proxibase.createUser(fullNameTextField.text, email: emailTextField.text, password: passwordTextField.text, parameters: parameters) { (response, error) in
            
            if let error = ServerError(error)
            {
                var errorMessage = error.message

                if error.code == .FORBIDDEN_DUPLICATE {
                    errorMessage = LocalizedString("Email address already in use.")
                }
                
                let alert = UIAlertController(title: LocalizedString("Registration Failure"), message: errorMessage, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: { _ in }))
                self.presentViewController(alert, animated: true) {}
            }
            else
            {
                var userInfo = NSMutableDictionary()
                
                if let image = self.avatarImageView.image
                {
                    userInfo["photo"] = image
                }
                
                proxibase.updateUser(userInfo) { response, error in
                
                    if let error = error {
                        println("Error Updating User Info: \(error)")
                    }
                    dispatch_semaphore_signal(semaphore)
                }
            
                dispatch_async(queue) {
                    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
                    
                    // Successful registration and sign-in. Move to the main scene.
                    dispatch_async(dispatch_get_main_queue())
                    {
                        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
                        let viewController = UIStoryboard(name:"Main", bundle:NSBundle.mainBundle()).instantiateInitialViewController() as UIViewController;
                        appDelegate.window!.setRootViewController(viewController, animated: true)
                    }
                }
            }
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
