//
//  SignInViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MBProgressHUD

class PasswordResetViewController: BaseViewController, UITextFieldDelegate {

    var processing: Bool = false
    var emailConfirmed: Bool = false
    var userId: String?
    var sessionKey: String?
    
    var emailField = AirTextField()
    var passwordField = AirTextField()
    var message = AirLabelDisplay()
	var resetButton = AirButton()
	
	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		super.loadView()
		initialize()
	}
	
	/*--------------------------------------------------------------------------------------------
	* Events
	*--------------------------------------------------------------------------------------------*/
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.message.anchorTopCenterWithTopPadding(88, width: 288, height: 48)
		self.emailField.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 288, height: 48)
		self.passwordField.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 288, height: 48)
		self.resetButton.alignUnder(self.emailField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
	}
	
    func doneAction(sender: NSObject) {
        
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
    
    func cancelAction(sender: AnyObject){
        self.navigationController?.popViewControllerAnimated(true)
    }
    
	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
		setScreenName("PasswordReset")
		
		self.message.text = "Forgot your password? Enter your email address:"
		self.message.numberOfLines = 2
		self.message.textAlignment = .Left
		self.view.addSubview(self.message)
		
		self.emailField.placeholder = "Email"
		self.emailField.accessibilityIdentifier = "email_field"
		self.emailField.delegate = self
		self.emailField.autocapitalizationType = .None
		self.emailField.autocorrectionType = .No
		self.emailField.keyboardType = UIKeyboardType.EmailAddress
		self.emailField.returnKeyType = UIReturnKeyType.Next
		self.view.addSubview(self.emailField)
		
		self.passwordField.placeholder = "Password (6 characters or more)"
		self.passwordField.accessibilityIdentifier = "password_field"
		self.passwordField.hidden = true
		self.passwordField.delegate = self
		self.passwordField.secureTextEntry = true
		self.passwordField.keyboardType = UIKeyboardType.Default
		self.passwordField.returnKeyType = UIReturnKeyType.Done
		self.view.addSubview(self.passwordField)
		
		self.resetButton.setTitle("SUBMIT", forState: .Normal)
		self.resetButton.accessibilityIdentifier = "submit_button"
		self.view.addSubview(self.resetButton)

		self.resetButton.addTarget(self, action: Selector("doneAction:"), forControlEvents: .TouchUpInside)
	}
	
    func requestReset() {
        
		let progress = AirProgress.addedTo(self.view.window)
        progress.mode = MBProgressHUDMode.Indeterminate
        progress.styleAs(.ActivityWithText)
		progress.labelText = "Verifying..."
		progress.graceTime = 2.0
		progress.minShowTime = 1.0
        progress.show(true)
		progress.taskInProgress = true
		progress.userInteractionEnabled = true
		
        DataController.proxibase.requestPasswordReset(emailField.text!) {
            response, error in
            
			NSOperationQueue.mainQueue().addOperationWithBlock {
				self.processing = false
				progress.taskInProgress = false
				
				progress.hide(true)
				if var error = ServerError(error) {
					self.emailConfirmed = false
					if error.code == .UNAUTHORIZED {
						error.message = "This email address has not been used with this installation. Please contact support to reset your password."
						self.handleError(error, errorActionType: .ALERT)
					}
					else if error.code == .NOT_FOUND {
						error.message = "The email address could not be found."
						self.handleError(error, errorActionType: .ALERT)
					}
					else {
						self.handleError(error)
					}
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
					
					self.emailConfirmed = true
					self.message.text = "Email address confirmed, enter a new password:"
					self.emailField.fadeOut()
					self.passwordField.hidden = false
					self.passwordField.fadeIn()
					self.passwordField.becomeFirstResponder()
					UIShared.Toast("Email verified")
				}
			}
        }
    }
    
    func reset() {
		
		let progress = AirProgress.addedTo(self.view.window)
        progress.mode = MBProgressHUDMode.Indeterminate
        progress.styleAs(.ActivityWithText)
        progress.labelText = "Resetting..."
		progress.graceTime = 2.0
		progress.minShowTime = 1.0
        progress.show(true)
		progress.taskInProgress = true
		
        DataController.proxibase.resetPassword(passwordField.text!, userId: self.userId!, sessionKey: self.sessionKey!) {
            response, error in
            
			NSOperationQueue.mainQueue().addOperationWithBlock {
				self.processing = false
				progress.taskInProgress = false
				
				progress.hide(true)
				if let error = ServerError(error) {
					self.handleError(error)
				}
				else {
					UIShared.Toast("Password reset")
					self.navigationController?.popViewControllerAnimated(true)	// Back to login
				}
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
            if (passwordField.text!.utf16.count < 6) {
                Alert("Enter a new password with six characters or more.")
                return false
            }
        }
        return true
    }
}