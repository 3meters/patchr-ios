//
//  SignInViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MBProgressHUD

class PasswordEditViewController: BaseEditViewController {

    var processing: Bool = false

    var message				= AirLabelTitle()
    var passwordField		= AirTextField()
    var passwordNewField	= AirTextField()
	var hideShowButton		= AirHideShowButton()
	var hideShowNewButton	= AirHideShowButton()
    var submitButton		= AirButton()
	
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
		self.passwordField.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 288, height: 48)
		self.passwordNewField.alignUnder(self.passwordField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
		self.submitButton.alignUnder(self.passwordNewField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
		
		self.contentHolder.resizeToFitSubviews()
		self.scrollView.contentSize = CGSizeMake(self.contentHolder.frame.size.width, self.contentHolder.frame.size.height + CGFloat(32))
		self.contentHolder.anchorTopCenterFillingWidthWithLeftAndRightPadding(16, topPadding: 16, height: self.contentHolder.frame.size.height)
	}
	
    override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
        self.passwordField.becomeFirstResponder()
    }
	
	/*--------------------------------------------------------------------------------------------
	* Events
	*--------------------------------------------------------------------------------------------*/
	
	func submitAction(sender: AnyObject) {
		if processing { return }
		if isValid() {
			change()
		}
	}
	
	func hideShowPasswordAction(sender: AnyObject?) {
		if let button = sender as? AirHideShowButton {
			button.toggleOn(!button.toggledOn)
			self.passwordField.secureTextEntry = !button.toggledOn
		}
	}

	func hideShowNewPasswordAction(sender: AnyObject?) {
		if let button = sender as? AirHideShowButton {
			button.toggleOn(!button.toggledOn)
			self.passwordNewField.secureTextEntry = !button.toggledOn
		}
	}

	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
		Reporting.screen("PasswordEdit")
		self.view.accessibilityIdentifier = View.PasswordEdit
		
		self.message.text = "Change password"
		self.message.numberOfLines = 0
		self.message.textAlignment = .Center
		self.contentHolder.addSubview(self.message)
		
		self.passwordField.placeholder = "Current password"
		self.passwordField.accessibilityIdentifier = Field.Password
		self.passwordField.delegate = self
		self.passwordField.secureTextEntry = true
		self.passwordField.keyboardType = UIKeyboardType.Default
		self.passwordField.returnKeyType = UIReturnKeyType.Next
		self.passwordField.rightView = self.hideShowButton
		self.passwordField.rightViewMode = .Always
		self.contentHolder.addSubview(self.passwordField)

		self.passwordNewField.placeholder = "New password"
		self.passwordNewField.accessibilityIdentifier = Field.NewPassword
		self.passwordNewField.delegate = self
		self.passwordNewField.secureTextEntry = true
		self.passwordNewField.keyboardType = UIKeyboardType.Default
		self.passwordNewField.returnKeyType = UIReturnKeyType.Done
		self.passwordNewField.rightView = self.hideShowNewButton
		self.passwordNewField.rightViewMode = .Always
		self.contentHolder.addSubview(self.passwordNewField)
		
		self.hideShowButton.bounds.size = CGSizeMake(48, 48)
		self.hideShowButton.imageEdgeInsets = UIEdgeInsetsMake(8, 10, 8, 10)
		self.hideShowButton.addTarget(self, action: #selector(PasswordEditViewController.hideShowPasswordAction(_:)), forControlEvents: .TouchUpInside)
		
		self.hideShowNewButton.bounds.size = CGSizeMake(48, 48)
		self.hideShowNewButton.imageEdgeInsets = UIEdgeInsetsMake(8, 10, 8, 10)
		self.hideShowNewButton.addTarget(self, action: #selector(PasswordEditViewController.hideShowNewPasswordAction(_:)), forControlEvents: .TouchUpInside)
		
		self.submitButton.setTitle("CHANGE", forState: .Normal)
		self.submitButton.accessibilityIdentifier = Button.Submit
		self.submitButton.addTarget(self, action: #selector(PasswordEditViewController.submitAction(_:)), forControlEvents: .TouchUpInside)
		self.contentHolder.addSubview(self.submitButton)
		
		/* Navigation bar buttons */
		let submitBarButton   = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(PasswordEditViewController.submitAction(_:)))
		let cancelBarButton   = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(PasswordEditViewController.cancelAction(_:)))
		
		submitBarButton.accessibilityIdentifier = Nav.Submit
		cancelBarButton.accessibilityIdentifier = Nav.Cancel
		
		self.navigationItem.rightBarButtonItems = [submitBarButton]
		self.navigationItem.leftBarButtonItems = [cancelBarButton]
	}
	
    func change() {
        
        if processing { return }
        
        if !isValid() { return }
        
        processing = true
		
		let progress = AirProgress.addedTo(self.view.window!)
		progress.mode = MBProgressHUDMode.Indeterminate
		progress.styleAs(.ActivityWithText)
		progress.label.text = "Updating..."
		progress.graceTime = 2.0
		progress.minShowTime = 1.0
		progress.showAnimated(true)
		progress.userInteractionEnabled = true
		
        DataController.proxibase.updatePassword(UserController.instance.currentUser.id_,
            password: passwordField.text!,
            passwordNew: passwordNewField.text!) { response, error in
                
			NSOperationQueue.mainQueue().addOperationWithBlock {
				self.processing = false
				
				progress.hideAnimated(true)
				if var error = ServerError(error) {	// Doesn't show in debugger correctly but is getting set
					if error.code == .UNAUTHORIZED_CREDENTIALS {
						error.message = "The old password is not correct."
						self.handleError(error, errorActionType: .ALERT)
					}
					else if error.code == .FORBIDDEN_USER_PASSWORD_WEAK {
						error.message = "The password is not strong enough."
						self.handleError(error, errorActionType: .ALERT)
					}
					else {
						self.handleError(error)	// Could log user out if looks like credential problem.
					}
				}
				else {
					/* Password change has already been handled with UserController */
					self.navigationController?.popViewControllerAnimated(true)	// Back to profile edit
					Reporting.track("Changed Password")
					UIShared.Toast("Password changed")
				}
			}
        }
    }
    
    func cancelAction(sender: AnyObject){
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func isValid() -> Bool {
		
		if (self.passwordField.text!.isEmpty) {
			Alert("Enter your current password.")
			return false
		}
		
        if (passwordNewField.text!.utf16.count < 6) {
            Alert("Enter a new password with six characters or more.")
            return false
        }
        return true
    }
	
	override func textFieldShouldReturn(textField: UITextField) -> Bool {
		if textField == self.passwordField {
			self.passwordNewField.becomeFirstResponder()
			return false
		} else if textField == self.passwordNewField {
			self.submitAction(textField)
			textField.resignFirstResponder()
			return false
		}
		return true
	}
}