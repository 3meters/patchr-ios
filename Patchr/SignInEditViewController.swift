//
//  SignInViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class SignInEditViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var emaiField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signInBarButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.errorLabel.text = nil
        self.emaiField.delegate = self
        self.passwordField.delegate = self
        self.emaiField.text = NSUserDefaults.standardUserDefaults().objectForKey(PatchrUserDefaultKey("userEmail")) as? String
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if self.emaiField.isEmpty {
            self.emaiField.becomeFirstResponder()
        } else {
            self.passwordField.becomeFirstResponder()
        }
    }
    
    @IBAction func signInAction(sender: NSObject) {
        
        errorLabel.text = ""

		let progress = MBProgressHUD.showHUDAddedTo(self.view.window, animated: true)
		progress.mode = MBProgressHUDMode.Indeterminate
		progress.labelText = "Signing in"
		progress.show(true)
        
        DataController.proxibase.signIn(self.emaiField.text, password: self.passwordField.text) { (response, error) -> Void in
			progress.hide(true, afterDelay: 1.0)
            if (error != nil) {
                NSLog("Login error \(error!)")
                if let loginErrorMessage: AnyObject = (response!["error"] as! NSDictionary)["message"] {
                    self.errorLabel.text = loginErrorMessage as? String
                }
            } else {
                // Store email address
                NSUserDefaults.standardUserDefaults().setObject(self.emaiField.text, forKey: PatchrUserDefaultKey("userEmail"))
                NSUserDefaults.standardUserDefaults().synchronize()
                self.passwordField.text = nil
                
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                let destinationViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateInitialViewController() as! UIViewController
                appDelegate.window!.setRootViewController(destinationViewController, animated: true)
            }
        }
    }
}

extension SignInEditViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        if textField == self.emaiField {
            self.passwordField.becomeFirstResponder()
            return false
        } else if textField == self.passwordField {
            self.signInAction(textField)
            textField.resignFirstResponder()
            return false
        }
        
        return true
    }
}
