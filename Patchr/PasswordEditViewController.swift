//
//  SignInViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class PasswordEditViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var passwordNewField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.errorLabel.text = nil
        self.passwordField.delegate = self
        self.passwordNewField.delegate = self
    }
    
    @IBAction func doneAction(sender: NSObject) {
        
        errorLabel.text = ""

		let progress = MBProgressHUD.showHUDAddedTo(self.view.window, animated: true)
		progress.mode = MBProgressHUDMode.Indeterminate
		progress.labelText = "Updating..."
		progress.show(true)
        
        DataController.proxibase.updatePassword(UserController.instance.currentUser.id_,
            password: passwordField.text,
            passwordNew: passwordNewField.text) { (response, error) -> Void in
                
			progress.hide(true, afterDelay: 1.0)
            if (error != nil) {
                NSLog("Login error \(error!)")
                if let loginErrorMessage: AnyObject = (response!["error"] as! NSDictionary)["message"] {
                    self.errorLabel.text = loginErrorMessage as? String
                }
            } else {
                /* Return to profile editing */
            }
        }
    }
}

extension PasswordEditViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == self.passwordField {
            self.passwordNewField.becomeFirstResponder()
            return false
        } else if textField == self.passwordNewField {
            self.doneAction(textField)
            textField.resignFirstResponder()
            return false
        }
        return true
    }
}