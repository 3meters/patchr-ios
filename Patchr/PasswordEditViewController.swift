//
//  SignInViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class PasswordEditViewController: UITableViewController {

    var processing: Bool = false

    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var passwordNewField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.passwordField.delegate = self
        self.passwordNewField.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setScreenName("PasswordEdit")
    }
    
    override func viewDidAppear(animated: Bool) {
        self.passwordField.becomeFirstResponder()
    }
    
    @IBAction func doneAction(sender: NSObject) {
        
        if processing { return }
        
        if !isValid() { return }
        
        processing = true

		let progress = AirProgress.showHUDAddedTo(self.view.window, animated: true)
		progress.mode = MBProgressHUDMode.Indeterminate
        progress.styleAs(.ActivityLight)
		progress.labelText = "Updating..."
		progress.removeFromSuperViewOnHide = true
		progress.show(true)
        
        DataController.proxibase.updatePassword(UserController.instance.currentUser.id_,
            password: passwordField.text!,
            passwordNew: passwordNewField.text!) {
            response, error in
                
            self.processing = false
                
            progress?.hide(true, afterDelay: 1.0)
            if let error = ServerError(error) {
                self.handleError(error)
            }
            else {
                self.dismissViewControllerAnimated(true, completion: nil)
                progress?.mode = MBProgressHUDMode.Text
                progress?.labelText = "Password changed"
            }
        }
    }
    
    @IBAction func cancelAction(sender: AnyObject){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func isValid() -> Bool {
        if (passwordNewField.text!.utf16.count < 6) {
            Alert("Enter a new password with six characters or more.")
            return false
        }
        return true
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