//
//  SignInViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MBProgressHUD
import PBWebViewController
import Firebase
import FirebaseAuth

class AccountEditViewController: BaseEditViewController {

    var inputUser: FireUser!

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
		
        let messageSize = self.message.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
		self.message.anchorTopCenter(withTopPadding: 0, width: 288, height: messageSize.height)
		self.passwordField.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 288, height: 48)
		self.passwordNewField.alignUnder(self.passwordField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
		self.submitButton.alignUnder(self.passwordNewField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
		
		self.contentHolder.resizeToFitSubviews()
        self.scrollView.contentSize = CGSize(width:self.contentHolder.frame.size.width, height:self.contentHolder.frame.size.height + CGFloat(32))
		self.contentHolder.anchorTopCenterFillingWidth(withLeftAndRightPadding: 16, topPadding: 16, height: self.contentHolder.frame.size.height)
	}
	
    override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
        self.passwordField.becomeFirstResponder()
    }
	
	/*--------------------------------------------------------------------------------------------
	* Events
	*--------------------------------------------------------------------------------------------*/

    func changePasswordAction(sender: AnyObject) {
        let controller = PasswordEditViewController()
        self.navigationController?.pushViewController(controller, animated: true)
    }

    func termsAction(sender: AnyObject) {
        let webViewController = PBWebViewController()
        webViewController.url = NSURL(string: "http://patchr.com/terms")! as URL
        webViewController.showsNavigationToolbar = false
        self.navigationController?.pushViewController(webViewController, animated: true)
    }

    func submitAction(sender: AnyObject) {
		if isValid() {
			change()
		}
	}
	
	func hideShowPasswordAction(sender: AnyObject?) {
		if let button = sender as? AirHideShowButton {
			button.toggleOn(on: !button.toggledOn)
			self.passwordField.isSecureTextEntry = !button.toggledOn
		}
	}

	func hideShowNewPasswordAction(sender: AnyObject?) {
		if let button = sender as? AirHideShowButton {
			button.toggleOn(on: !button.toggledOn)
			self.passwordNewField.isSecureTextEntry = !button.toggledOn
		}
	}

	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
		Reporting.screen("PasswordEdit")
		
		self.message.text = "Change password"
		self.message.numberOfLines = 0
		self.message.textAlignment = .center
		self.contentHolder.addSubview(self.message)
		
		self.passwordField.placeholder = "Current password"
		self.passwordField.delegate = self
		self.passwordField.isSecureTextEntry = true
		self.passwordField.keyboardType = UIKeyboardType.default
		self.passwordField.returnKeyType = UIReturnKeyType.next
		self.passwordField.rightView = self.hideShowButton
		self.passwordField.rightViewMode = .always
		self.contentHolder.addSubview(self.passwordField)

		self.passwordNewField.placeholder = "New password"
		self.passwordNewField.delegate = self
		self.passwordNewField.isSecureTextEntry = true
		self.passwordNewField.keyboardType = UIKeyboardType.default
		self.passwordNewField.returnKeyType = UIReturnKeyType.done
		self.passwordNewField.rightView = self.hideShowNewButton
		self.passwordNewField.rightViewMode = .always
		self.contentHolder.addSubview(self.passwordNewField)
		
        self.hideShowButton.bounds.size = CGSize(width:48, height:48)
        self.hideShowButton.imageEdgeInsets = UIEdgeInsets(top:8, left:10, bottom:8, right:10)
		self.hideShowButton.addTarget(self, action: #selector(PasswordEditViewController.hideShowPasswordAction(sender:)), for: .touchUpInside)
		
        self.hideShowNewButton.bounds.size = CGSize(width:48, height:48)
        self.hideShowNewButton.imageEdgeInsets = UIEdgeInsetsMake(8, 10, 8, 10)
		self.hideShowNewButton.addTarget(self, action: #selector(PasswordEditViewController.hideShowNewPasswordAction(sender:)), for: .touchUpInside)
		
		self.submitButton.setTitle("CHANGE", for: .normal)
		self.submitButton.addTarget(self, action: #selector(PasswordEditViewController.submitAction(sender:)), for: .touchUpInside)
		self.contentHolder.addSubview(self.submitButton)
		
		/* Navigation bar buttons */
		let submitBarButton   = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(PasswordEditViewController.submitAction(sender:)))
		let cancelBarButton   = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(PasswordEditViewController.cancelAction(sender:)))
		
		self.navigationItem.rightBarButtonItems = [submitBarButton]
		self.navigationItem.leftBarButtonItems = [cancelBarButton]
	}
	
    func change() {
        
        if !isValid() { return }
		
		let progress = AirProgress.addedTo(view: self.view.window!)
		progress.mode = MBProgressHUDMode.indeterminate
		progress.styleAs(progressStyle: .ActivityWithText)
		progress.labelText = "Updating..."
		progress.graceTime = 2.0
		progress.minShowTime = 1.0
		progress.show(true)
		progress.isUserInteractionEnabled = true
		
        DataController.proxibase.updatePassword(userId: ZUserController.instance.currentUser.id_,
            password: passwordField.text!,
            passwordNew: passwordNewField.text!) { response, error in
                
			OperationQueue.main.addOperation {
				
				progress.hide(true)
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
					let _ = self.navigationController?.popViewController(animated: true)	// Back to profile edit
					Reporting.track("Changed Password")
					UIShared.Toast(message: "Password changed")
				}
			}
        }
    }
    
    func cancelAction(sender: AnyObject){
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    func isValid() -> Bool {
		
		if (self.passwordField.text!.isEmpty) {
			Alert(title: "Enter your current password.")
			return false
		}
		
        if (passwordNewField.text!.utf16.count < 6) {
            Alert(title: "Enter a new password with six characters or more.")
            return false
        }
        return true
    }
	
	override func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if textField == self.passwordField {
			self.passwordNewField.becomeFirstResponder()
			return false
		} else if textField == self.passwordNewField {
			self.submitAction(sender: textField)
			textField.resignFirstResponder()
			return false
		}
		return true
	}
}
