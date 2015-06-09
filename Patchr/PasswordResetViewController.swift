//
//  SignInViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class PasswordResetViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.errorLabel.text = nil
        self.emailField.delegate = self
    }
    
    @IBAction func resetAction(sender: NSObject) {
        
        errorLabel.text = ""

		let progress = MBProgressHUD.showHUDAddedTo(self.view.window, animated: true)
		progress.mode = MBProgressHUDMode.Indeterminate
		progress.labelText = "Working..."
		progress.show(true)
        
        DataController.proxibase.requestPasswordReset(emailField.text) { (response, error) -> Void in
                
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