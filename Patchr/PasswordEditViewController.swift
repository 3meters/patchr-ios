//
//  SignInViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class PasswordEditViewController: BaseViewController {

    var processing: Bool = false

    var passwordField = AirTextField()
    var passwordNewField = AirTextField()
	
	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		super.loadView()
		initialize()
	}
	
    override func viewDidAppear(animated: Bool) {
        self.passwordField.becomeFirstResponder()
    }
	
	/*--------------------------------------------------------------------------------------------
	* Events
	*--------------------------------------------------------------------------------------------*/
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.passwordField.anchorTopCenterWithTopPadding(88, width: 288, height: 48)
		self.passwordNewField.alignUnder(self.passwordField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
	}

	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
		setScreenName("PasswordEdit")
		
		self.passwordField.placeholder = "Old password"
		self.passwordField.delegate = self
		self.passwordField.secureTextEntry = true
		self.passwordField.keyboardType = UIKeyboardType.Default
		self.passwordField.returnKeyType = UIReturnKeyType.Next
		self.view.addSubview(self.passwordField)

		self.passwordNewField.placeholder = "Password (6 characters or more)"
		self.passwordNewField.delegate = self
		self.passwordNewField.secureTextEntry = true
		self.passwordNewField.keyboardType = UIKeyboardType.Default
		self.passwordNewField.returnKeyType = UIReturnKeyType.Done
		self.view.addSubview(self.passwordNewField)
		
		/* Navigation bar buttons */
		let doneButton   = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: "doneAction:")
		let cancelButton   = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: "cancelAction:")
		self.navigationItem.title = "Change password"
		self.navigationItem.rightBarButtonItems = [doneButton]
		self.navigationItem.leftBarButtonItems = [cancelButton]
	}
	
    func doneAction(sender: NSObject) {
        
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
                
			NSOperationQueue.mainQueue().addOperationWithBlock {
				self.processing = false
					
				progress?.hide(true, afterDelay: 1.0)
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
					self.dismissViewControllerAnimated(true, completion: nil)
					progress?.mode = MBProgressHUDMode.Text
					progress?.labelText = "Password changed"
				}
			}
        }
    }
    
    func cancelAction(sender: AnyObject){
        self.navigationController?.popViewControllerAnimated(true)
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