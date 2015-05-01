//
//  SignInViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class SignInTableViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInErrorMessage: UILabel!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signInBarButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.signInErrorMessage.text = nil
        self.emailTextField.delegate = self
        self.passwordTextField.delegate = self
        self.emailTextField.text = NSUserDefaults.standardUserDefaults().objectForKey(PatchrUserDefaultKey("userEmail")) as? String
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.configureSignInButtons()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if self.emailTextField.isEmpty {
            self.emailTextField.becomeFirstResponder()
        } else {
            self.passwordTextField.becomeFirstResponder()
        }
    }
    
    @IBAction func signInButtonAction(sender: NSObject) {
        
        signInErrorMessage.text = ""
        
        let hud = MBProgressHUD(window: self.view.window)
        hud.graceTime = 0.5
        hud.show(true)
        
        ProxibaseClient.sharedInstance.signIn(self.emailTextField.text, password: self.passwordTextField.text) { (response, error) -> Void in
            if (error != nil) {
                NSLog("Login error \(error!)")
                if let loginErrorMessage: AnyObject = (response!["error"] as! NSDictionary)["message"] {
                    self.signInErrorMessage.text = loginErrorMessage as? String
                }
                hud.hide(true)
            } else {
                hud.hide(true)
                
                // Store email address
                NSUserDefaults.standardUserDefaults().setObject(self.emailTextField.text, forKey: PatchrUserDefaultKey("userEmail"))
                NSUserDefaults.standardUserDefaults().synchronize()
                self.passwordTextField.text = nil
                
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                let destinationViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateInitialViewController() as! UIViewController
                appDelegate.window!.setRootViewController(destinationViewController, animated: true)
            }
        }
    }
    
    @IBAction func emailEditingChangedAction(sender: AnyObject) {
        self.configureSignInButtons()
    }
    
    @IBAction func passwordEditingChangedAction(sender: AnyObject) {
        self.configureSignInButtons()
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        if textField == self.emailTextField {
            self.passwordTextField.becomeFirstResponder()
            return false
        } else if textField == self.passwordTextField {
            self.signInButtonAction(textField)
            textField.resignFirstResponder()
            return false
        }
        
        return true
    }

    
    // MARK: Private Internal
    
    func configureSignInButtons() {
        var enableSignIn = false
        if !self.emailTextField.isEmpty && !self.passwordTextField.isEmpty {
            enableSignIn = true
        }
        self.signInButton.enabled = enableSignIn
        self.signInButton.alpha = enableSignIn ? 1.0 : 0.4
        self.signInBarButtonItem.enabled = enableSignIn
    }
}

extension UITextField {
    
     var isEmpty: Bool {
        return self.text == nil || self.text.isEmpty
    }
}
