//
//  SignInViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MBProgressHUD
import Firebase
import FirebaseAuth

class PasswordEditViewController: BaseEditViewController {

    var message	= AirLabelTitle()
    var passwordField = FloatTextField()
	var hideShowButton = AirHideShowButton()
	
	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		super.loadView()
		initialize()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		let _ = self.passwordField.becomeFirstResponder()
	}

	override func viewWillLayoutSubviews() {
        let messageSize = self.message.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
		self.message.anchorTopCenter(withTopPadding: 0, width: 288, height: messageSize.height)
		self.passwordField.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        super.viewWillLayoutSubviews()
	}

	/*--------------------------------------------------------------------------------------------
	* Events
	*--------------------------------------------------------------------------------------------*/
	
	func doneAction(sender: AnyObject) {
		if isValid() {
            let _ = self.passwordField.resignFirstResponder()
            
            self.progress = AirProgress.addedTo(view: self.view.window!)
            self.progress?.mode = MBProgressHUDMode.indeterminate
            self.progress?.styleAs(progressStyle: .activityWithText)
            self.progress?.minShowTime = 0.5
            self.progress?.labelText = "Updating..."
            self.progress?.removeFromSuperViewOnHide = true
            self.progress?.show(true)

            Reporting.track("update_password")
			updatePassword()
		}
	}
	
	func hideShowPasswordAction(sender: AnyObject?) {
		if let button = sender as? AirHideShowButton {
            Reporting.track(button.toggledOn ? "hide_password" : "show_password")
			button.toggle(on: !button.toggledOn)
			self.passwordField.isSecureTextEntry = !button.toggledOn
		}
	}
    
    override func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.passwordField {
            self.doneAction(sender: textField)
            textField.resignFirstResponder()
            return false
        }
        return true
    }

	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
		self.message.text = "Change password"
		self.message.numberOfLines = 0
		self.message.textAlignment = .center
		
		self.passwordField.placeholder = "New password"
		self.passwordField.setDelegate(delegate: self)
		self.passwordField.isSecureTextEntry = true
        self.passwordField.autocapitalizationType = .none
		self.passwordField.keyboardType = .default
		self.passwordField.returnKeyType = .next
		self.passwordField.rightView = self.hideShowButton
		self.passwordField.rightViewMode = .always

        self.hideShowButton.bounds.size = CGSize(width:48, height:48)
        self.hideShowButton.imageEdgeInsets = UIEdgeInsets(top:8, left:10, bottom:8, right:10)
		self.hideShowButton.addTarget(self, action: #selector(PasswordEditViewController.hideShowPasswordAction(sender:)), for: .touchUpInside)

        self.contentHolder.addSubview(self.message)
        self.contentHolder.addSubview(self.passwordField)

		/* Navigation bar buttons */
		let doneButton   = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
		self.navigationItem.rightBarButtonItems = [doneButton]
	}
	
    func updatePassword() {
        
        if processing { return }
        processing = true
		
        if let authUser = FIRAuth.auth()?.currentUser {
            let password = self.passwordField.text!
            authUser.updatePassword(password, completion: { error in
                self.progress?.hide(true)
                if error == nil {
                    let _ = self.navigationController?.popToRootViewController(animated: true)
                }
                else {
					self.passwordField.errorMessage = error?.localizedDescription
                }
            })
        }
    }
    
    func isValid() -> Bool {
		
        if (passwordField.text!.utf16.count < 6) {
			self.passwordField.errorMessage = "Enter a password with six characters or more."
            return false
        }
        return true
    }
}
