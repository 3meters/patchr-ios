//
//  SignInViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class SignInEditViewController: UITableViewController, UITextFieldDelegate {

    var processing: Bool = false

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.emailField.delegate = self
        self.passwordField.delegate = self
        
        self.emailField.text = NSUserDefaults.standardUserDefaults().objectForKey(PatchrUserDefaultKey("userEmail")) as? String
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.emailField.isEmpty {
            self.emailField.becomeFirstResponder()
        }
        else {
            self.passwordField.becomeFirstResponder()
        }
    }
    
    @IBAction func doneAction(sender: NSObject) {
        
        if processing { return }
        
        if !isValid() { return }
        
        processing = true
        
        self.passwordField.resignFirstResponder()

		let progress = MBProgressHUD.showHUDAddedTo(self.view.window, animated: true)
		progress.mode = MBProgressHUDMode.Indeterminate
        progress.minShowTime = 0.5
		progress.labelText = "Signing in..."
		progress.show(true)
        
        DataController.proxibase.signIn(self.emailField.text, password: self.passwordField.text) {
            response, error in
            
            self.processing = false
            
            progress.hide(true)
            if let error = ServerError(error) {
                self.handleError(error)
            }
            else {
                
                // Store email address
                NSUserDefaults.standardUserDefaults().setObject(self.emailField.text, forKey: PatchrUserDefaultKey("userEmail"))
                NSUserDefaults.standardUserDefaults().synchronize()
                self.passwordField.text = nil
                /*
                * Register this install with the service particularly to capture the
                * current user so location updates work properly. If install registration 
                * fails the device will not accurately track notifications.
                */
                DataController.proxibase.registerInstallStandard {
                    response, error in
                    
                    if let error = ServerError(error) {
                        Log.w("Error during registerInstall: \(error)")
                    }
                    
                    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                    let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
                    if let controller = storyboard.instantiateViewControllerWithIdentifier("MainTabBarController") as? UIViewController {
                        appDelegate.window?.setRootViewController(controller, animated: true)
                        Shared.Toast("Signed in as \(UserController.instance.userName!)", controller: controller)
                    }
                }
            }
        }
    }
    
    @IBAction func cancelAction(sender: AnyObject){
        self.navigationController?.popViewControllerAnimated(true)
    }

    func isValid() -> Bool {
        
        if emailField.isEmpty {
            Alert("Enter an email address.")
            return false
        }
        
        if (count(passwordField.text.utf16) < 6) {
            Alert("Enter a password with six characters or more.")
            return false
        }
        
        return true
    }
}

extension SignInEditViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        if textField == self.emailField {
            self.passwordField.becomeFirstResponder()
            return false
        } else if textField == self.passwordField {
            self.doneAction(textField)
            textField.resignFirstResponder()
            return false
        }
        
        return true
    }
}
