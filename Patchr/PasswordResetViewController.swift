//
//  SignInViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MBProgressHUD

class PasswordResetViewController: BaseEditViewController {

    var processing			: Bool = false
    var userId				: String?
    var sessionKey			: String?
	
	var message       = AirLabelTitle()
    var emailField    = AirTextField()
    var passwordField = AirTextField()
	var submitButton  = AirButton()
		
	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		super.loadView()
		initialize()
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		let messageSize = self.message.sizeThatFits(CGSizeMake(288, CGFloat.max))
		self.message.anchorTopCenterWithTopPadding(0, width: 288, height: messageSize.height)
		self.emailField.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 288, height: 48)
		self.passwordField.alignUnder(self.emailField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
		self.submitButton.alignUnder(self.passwordField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
		
		self.contentHolder.resizeToFitSubviews()
		self.scrollView.contentSize = CGSizeMake(self.contentHolder.frame.size.width, self.contentHolder.frame.size.height + CGFloat(32))
		self.contentHolder.anchorTopCenterFillingWidthWithLeftAndRightPadding(16, topPadding: 16, height: self.contentHolder.frame.size.height)
	}
	
	override func viewDidAppear(animated: Bool) {
		self.emailField.becomeFirstResponder()
	}

	/*--------------------------------------------------------------------------------------------
	* Events
	*--------------------------------------------------------------------------------------------*/
	
    func submitAction(sender: AnyObject) {
        if processing { return }
        if isValid() {
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
		self.view.accessibilityIdentifier = View.PasswordReset
		
		self.message.text = "Forgot your password?"
		self.message.numberOfLines = 0
		self.message.textAlignment = .Center
		self.contentHolder.addSubview(self.message)
		
		self.emailField.placeholder = "Email"
		self.emailField.accessibilityIdentifier = Field.ResetEmail
		self.emailField.delegate = self
		self.emailField.autocapitalizationType = .None
		self.emailField.autocorrectionType = .No
		self.emailField.keyboardType = UIKeyboardType.EmailAddress
		self.emailField.returnKeyType = UIReturnKeyType.Next
		self.contentHolder.addSubview(self.emailField)
		
		self.passwordField.placeholder = "New password (6 characters or more)"
		self.passwordField.accessibilityIdentifier = Field.ResetPassword
		self.passwordField.delegate = self
		self.passwordField.secureTextEntry = true
		self.passwordField.keyboardType = UIKeyboardType.Default
		self.passwordField.returnKeyType = UIReturnKeyType.Done
		self.contentHolder.addSubview(self.passwordField)
		
		self.submitButton.setTitle("RESET", forState: .Normal)
		self.submitButton.accessibilityIdentifier = Button.Submit
		self.contentHolder.addSubview(self.submitButton)

		self.submitButton.addTarget(self, action: Selector("submitAction:"), forControlEvents: .TouchUpInside)
	}
	
	func reset() -> TaskQueue {
		
		self.processing = true
		
		let progress = AirProgress.addedTo(self.view.window)
		progress.mode = MBProgressHUDMode.Indeterminate
		progress.styleAs(.ActivityWithText)
		progress.labelText = "Resetting..."
		progress.minShowTime = 1.0
		progress.show(true)
		progress.userInteractionEnabled = true
		
		let queue = TaskQueue()
		
		queue.tasks +=~ { _, next in
			
			DataController.proxibase.requestPasswordReset(self.emailField.text!) {
				response, error in
				
				if var error = ServerError(error) {
					
					NSOperationQueue.mainQueue().addOperationWithBlock {
						progress.hide(true)
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
						self.processing = false
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
					
					next(nil)
				}
			}
		}
		
		queue.tasks +=~ { _, next in
			
			DataController.proxibase.resetPassword(self.passwordField.text!, userId: self.userId!, sessionKey: self.sessionKey!) {
				response, error in
				
				NSOperationQueue.mainQueue().addOperationWithBlock {
					self.processing = false
					
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
		
		queue.run()
		return queue
	}

    func isValid() -> Bool {
        
		if emailField.isEmpty {
			Alert("Enter an email address you have used before on this device.")
			return false
		}
		
		if !emailField.text!.isEmail() {
			Alert("Enter a valid email address.")
			return false
		}
			
		if (passwordField.text!.utf16.count < 6) {
			Alert("Enter a new password with six characters or more.")
			return false
		}
		
        return true
    }
	
	override func textFieldShouldReturn(textField: UITextField) -> Bool {
		
		if textField == self.emailField {
			self.passwordField.becomeFirstResponder()
			return false
		}
		else if textField == self.passwordField {
			self.submitAction(textField)
			self.view.endEditing(true)
			return false
		}
		
		return true
	}
}