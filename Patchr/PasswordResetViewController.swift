//
//  SignInViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class PasswordResetViewController: UITableViewController, UITextFieldDelegate {

    var processing: Bool = false
    var emailConfirmed: Bool = false
    var userId: String?
    var sessionKey: String?
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.passwordField.text = nil
        self.emailField.delegate = self
        self.passwordField.delegate = self
    }
    
    @IBAction func doneAction(sender: NSObject) {
        
        if processing { return }
        if !isValid() { return }
        processing = true
        
        if !emailConfirmed {
            requestReset()
        }
        else {
            reset()
        }
    }
    
    @IBAction func cancelAction(sender: AnyObject){
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func requestReset() {
        
        let progress = MBProgressHUD.showHUDAddedTo(self.view.window, animated: true)
        progress.mode = MBProgressHUDMode.Indeterminate
        progress.labelText = "Verifying..."
        progress.show(true)
        
        DataController.proxibase.requestPasswordReset(emailField.text) {
            response, error in
            
            self.processing = false
            
            if let serverError = ServerError(error) {
                progress.hide(true)
                self.emailConfirmed = false
                var message = serverError.message
                if serverError.code == .UNAUTHORIZED {
                    message = "This email address has not been used with this installation. Please contact support to reset your password."
                }
                else if serverError.code == .NOT_FOUND {
                    message = "The email address could not be found."
                }
                self.Alert(message)
            }
            else {
                if let serviceData = DataController.instance.dataWrapperForResponse(response!) {
                    if let userMap = serviceData.user as? [NSObject:AnyObject] {
                        self.userId = userMap["_id"] as? String
                    }
                    if let sessionMap = serviceData.session as? [NSObject:AnyObject] {
                        self.sessionKey = sessionMap["key"] as? String
                    }
                }
                
                progress.hide(true, afterDelay: 1.0)
                self.emailConfirmed = true
                self.messageLabel.text = "Email address confirmed, enter a new password:"
                self.emailField.fadeOut()
                self.passwordField.hidden = false
                self.passwordField.fadeIn()
                self.passwordField.becomeFirstResponder()
            }
        }
    }
    
    func reset() {
        
        let progress = MBProgressHUD.showHUDAddedTo(self.view.window, animated: true)
        progress.mode = MBProgressHUDMode.Indeterminate
        progress.labelText = "Resetting password for: \(self.emailField.text)"
        progress.show(true)
        
        DataController.proxibase.resetPassword(passwordField!.text, userId: self.userId!, sessionKey: self.sessionKey!) {
            response, error in
            
            self.processing = false
            
            if let serverError = ServerError(error) {
                progress.hide(true)
                self.Alert(serverError.message)
            }
            else {
                progress.hide(true, afterDelay: 1.0)
                self.navigationController?.popViewControllerAnimated(true)
            }
        }
    }

    func isValid() -> Bool {
        
        if !emailConfirmed {
            if emailField.isEmpty {
                Alert("Enter an email address.")
                return false
            }
        }
        else {
            if (count(passwordField.text.utf16) < 6) {
                Alert("Enter a new password with six characters or more.")
                return false
            }
        }
        return true
    }
}