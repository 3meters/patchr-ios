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

    @IBOutlet weak var dummyField: UITextField!
    private var defaultProfileImage: UIImage?
    
    lazy var photoChooserUI: PhotoChooserUI = { PhotoChooserUI(hostViewController: self) }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        defaultProfileImage = avatarImageView.image
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.configureSignInButtons()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.fullNameTextField.becomeFirstResponder()
    }
    
    @IBAction func avatarSetButtonAction(sender: AnyObject) {
        photoChooserUI.choosePhoto() { uiImage in
            self.avatarImageView.image = uiImage
        }
    }
    
    @IBAction func joinButtonAction(sender: AnyObject) {
    
        let parameters = NSMutableDictionary()
        let proxibase = ProxibaseClient.sharedInstance
        
        if let image = self.avatarImageView.image {
            if defaultProfileImage != image {
                parameters["photo"] = image
            }
        }
        
        proxibase.createUser(fullNameTextField.text, email: emailTextField.text, password: passwordTextField.text, parameters: parameters) { (_, error) in
            
            dispatch_async(dispatch_get_main_queue()) {
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
                    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
                    let viewController = UIStoryboard(name:"Main", bundle:NSBundle.mainBundle()).instantiateInitialViewController() as UIViewController;
                    appDelegate.window!.setRootViewController(viewController, animated: true)
                }
            }   
        }
    }
    
    @IBAction func termsOfServiceButtonAction(sender: AnyObject) {
        let webViewController = PBWebViewController()
        webViewController.URL = NSURL(string: "http://patchr.com/terms")!
        webViewController.showsNavigationToolbar = false
        self.navigationController?.pushViewController(webViewController, animated: true)
    }
    
    @IBAction func textFieldEditingChangedAction(sender: AnyObject) {
        self.configureSignInButtons()
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        if textField == self.fullNameTextField {
            self.emailTextField.becomeFirstResponder()
            return false
        } else if textField == self.emailTextField {
            self.passwordTextField.becomeFirstResponder()
            return false
        } else if textField == self.passwordTextField {
            
            // Kind of lame. Rely on bar button as the signal
            if self.doneBarButtonItem.enabled {
                self.joinButtonAction(textField)
                textField.resignFirstResponder()
            }
            return false
        }
        
        return true
    }

    
    // MARK: Private Internal
    
    func configureSignInButtons() {
        var enableSignIn = false
        if !self.fullNameTextField.isEmpty &&
            !self.emailTextField.isEmpty &&
            self.passwordTextField.text.utf16Count >= 6 {
            enableSignIn = true
        }
        self.joinButton.enabled = enableSignIn
        self.joinButton.alpha = enableSignIn ? 1.0 : 0.4
        self.doneBarButtonItem.enabled = enableSignIn        
    }
}
