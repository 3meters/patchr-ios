//
//  SignInViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MBProgressHUD
import FirebaseAuth
import Firebase

class PasswordViewController: BaseEditViewController {

    var inputEmail: String!
    var inputEmailExists = false
    
    var passwordField = AirTextField()
    var errorLabel = AirLabelDisplay()
    var hideShowButton = AirHideShowButton()
    var forgotPasswordButton = AirLinkButton()
    var message = AirLabelTitle()

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
        let errorSize = self.errorLabel.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        
        self.message.anchorTopCenter(withTopPadding: 0, width: 288, height: messageSize.height)
        self.passwordField.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        self.errorLabel.alignUnder(self.passwordField, matchingCenterWithTopPadding: 0, width: 288, height: errorSize.height)
        self.forgotPasswordButton.alignUnder(self.passwordField, matchingCenterWithTopPadding: 36, width: 288, height: 48)

        self.contentHolder.resizeToFitSubviews()
        self.scrollView.contentSize = CGSize(width:self.contentHolder.frame.size.width, height:self.contentHolder.frame.size.height + CGFloat(32))
        self.contentHolder.anchorTopCenterFillingWidth(withLeftAndRightPadding: 16, topPadding: 16, height: self.contentHolder.frame.size.height)
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    func doneAction(sender: AnyObject) {
        if isValid() {
            self.passwordField.resignFirstResponder()
            authenticate()
        }
    }

    func hideShowPasswordAction(sender: AnyObject?) {
        if let button = sender as? AirHideShowButton {
            button.toggle(on: !button.toggledOn)
            self.passwordField.isSecureTextEntry = !button.toggledOn
        }
    }

    func passwordResetAction(sender: AnyObject) {
        FIRAuth.auth()?.sendPasswordReset(withEmail: self.inputEmail) { error in
            if error == nil {
                self.Alert(title: "A password reset email has been sent to your email address.")
            }
        }
    }

    func cancelAction(sender: AnyObject) {
        if self.isModal {
            self.dismiss(animated: true, completion: nil)
        }
        else {
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }

    override func textFieldDidBeginEditing(_ textField: UITextField) {
        super.textFieldDidBeginEditing(textField)
        self.errorLabel.fadeOut()
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    override func initialize() {
        super.initialize()

        self.message.text = "Almost to the good stuff."

        self.message.textColor = Theme.colorTextTitle
        self.message.numberOfLines = 0
        self.message.textAlignment = .center

        self.passwordField.placeholder = "Password (6+ characters)"
        self.passwordField.delegate = self
        self.passwordField.isSecureTextEntry = true
        self.passwordField.autocapitalizationType = .none
        self.passwordField.keyboardType = UIKeyboardType.default
        self.passwordField.returnKeyType = UIReturnKeyType.next
        self.passwordField.rightView = self.hideShowButton
        self.passwordField.rightViewMode = .always

        self.hideShowButton.bounds.size = CGSize(width:48, height:48)
        self.hideShowButton.imageEdgeInsets = UIEdgeInsetsMake(8, 10, 8, 10)
        self.hideShowButton.addTarget(self, action: #selector(hideShowPasswordAction(sender:)), for: .touchUpInside)
        
        self.errorLabel.textColor = Theme.colorTextValidationError
        self.errorLabel.alpha = 0.0
        self.errorLabel.numberOfLines = 0
        self.errorLabel.font = Theme.fontValidationError

        self.forgotPasswordButton.setTitle("Forgot password?", for: .normal)
        self.forgotPasswordButton.addTarget(self, action: #selector(passwordResetAction(sender:)), for: .touchUpInside)
        
        self.contentHolder.addSubview(self.message)
        self.contentHolder.addSubview(self.passwordField)
        self.contentHolder.addSubview(self.errorLabel)
        self.contentHolder.addSubview(self.forgotPasswordButton)

        /* Navigation bar buttons */
        let nextButton = UIBarButtonItem(title: "Next", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
        self.navigationItem.rightBarButtonItems = [nextButton]
    }

    func authenticate() {

        guard !self.processing else { return }
        self.processing = true
        
        let password = self.passwordField.text!
        let email = self.inputEmail!
        
        if self.inputEmailExists {
            FIRAuth.auth()?.signIn(withEmail: email, password: password) { (user, error) in
                
                self.processing = false
                self.progress?.hide(true)
                
                if error == nil {
                    Reporting.track("Logged In")
                    /* Remember email address for easy data entry */
                    UserDefaults.standard.set(email, forKey: PatchrUserDefaultKey(subKey: "userEmail"))
                    UserController.instance.setUserId(userId: (user?.uid)!) { result in
                        if self.mode == .login {
                            let controller = GroupPickerController()
                            self.navigationController?.pushViewController(controller, animated: true)
                        }
                        else if self.mode == .create {
                            let controller = GroupCreateController()
                            self.navigationController?.pushViewController(controller, animated: true)
                        }
                    }
                }
                else {
                    var errorMessage = error?.localizedDescription
                    if error!._code == FIRAuthErrorCode.errorCodeEmailAlreadyInUse.rawValue {
                        errorMessage = "Email already used"
                    }
                    else if error!._code == FIRAuthErrorCode.errorCodeInvalidEmail.rawValue {
                        errorMessage = "Email address is not valid"
                    }
                    else if error!._code == FIRAuthErrorCode.errorCodeWrongPassword.rawValue {
                        errorMessage = "Wrong email and password combination"
                    }
                    self.errorLabel.text = errorMessage
                    self.errorLabel.fadeIn()
                }
            }
        }
        else {
            FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { user, error in
                
                self.processing = false
                self.progress?.hide(true)

                if error == nil {
                    Reporting.track("Logged In")
                    /* Remember email address for easy data entry */
                    UserDefaults.standard.set(email, forKey: PatchrUserDefaultKey(subKey: "userEmail"))
                    UserController.instance.setUserId(userId: (user?.uid)!) { result in
                        let controller = GroupPickerController()
                        self.navigationController?.pushViewController(controller, animated: true)
                    }
                }
                else {
                    self.errorLabel.text = error?.localizedDescription
                    self.errorLabel.fadeIn()
                }
            })
        }
    }

    func isValid() -> Bool {

        if (passwordField.text!.utf16.count < 6) {
            self.errorLabel.text = "Enter a password with six characters or more."
            self.view.setNeedsLayout()
            self.errorLabel.fadeIn()
            return false
        }

        return true
    }

    override func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        if textField == self.passwordField {
            self.doneAction(sender: textField)
            return false
        }

        return true
    }
}
