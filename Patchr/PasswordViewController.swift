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
    var inputInviteParams: [AnyHashable: Any]?
    
    var message = AirLabelTitle()
    var passwordField = AirTextField()
    var errorLabel = AirLabelDisplay()
    var hideShowButton = AirHideShowButton()
    var forgotPasswordButton = AirLinkButton()

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func loadView() {
        super.loadView()
        initialize()
    }

    override func viewDidAppear(_ animated: Bool) {
        self.passwordField.becomeFirstResponder()
    }

    override func viewWillLayoutSubviews() {

        let messageSize = self.message.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        let errorSize = self.errorLabel.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        
        self.message.anchorTopCenter(withTopPadding: 0, width: 288, height: messageSize.height)
        self.passwordField.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        self.errorLabel.alignUnder(self.passwordField, matchingCenterWithTopPadding: 0, width: 288, height: errorSize.height)
        self.forgotPasswordButton.alignUnder(self.passwordField, matchingCenterWithTopPadding: 36, width: 288, height: 48)

        super.viewWillLayoutSubviews()
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    func doneAction(sender: AnyObject) {
        if isValid() {
            self.passwordField.resignFirstResponder()
            
            if self.mode == .reauth {
                reauthenticate()
            }
            else {
                self.progress = AirProgress.showAdded(to: self.view.window!, animated: true)
                self.progress?.mode = MBProgressHUDMode.indeterminate
                self.progress?.styleAs(progressStyle: .ActivityWithText)
                self.progress?.minShowTime = 0.5
                self.progress?.removeFromSuperViewOnHide = true
                self.progress?.show(true)
                self.progress?.labelText = "Logging in..."
                
                authenticate()
            }
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
        close()
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

        self.message.text = (self.mode == .reauth)
            ? "Password confirmation"
            : "Almost to the good stuff."
        
        if self.flow == .onboardCreate {
            self.navigationItem.title = "Step 2 of 3"
        }

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
        
        if self.mode == .reauth || (self.flow == .onboardCreate && !self.inputEmailExists) {
            self.forgotPasswordButton.isHidden = true
        }
        else {
            self.forgotPasswordButton.setTitle("Forgot password?", for: .normal)
            self.forgotPasswordButton.addTarget(self, action: #selector(passwordResetAction(sender:)), for: .touchUpInside)
            self.contentHolder.addSubview(self.forgotPasswordButton)
        }
        
        self.contentHolder.addSubview(self.message)
        self.contentHolder.addSubview(self.passwordField)
        self.contentHolder.addSubview(self.errorLabel)

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
                    UserController.instance.setUserId(userId: (user?.uid)!) { result in
                        if self.flow == .onboardLogin {
                            let controller = GroupPickerController()
                            self.navigationController?.pushViewController(controller, animated: true)
                        }
                        else if self.flow == .onboardCreate {
                            let controller = GroupCreateController()
                            controller.flow = .onboardCreate
                            self.navigationController?.pushViewController(controller, animated: true)
                        }
                        else if self.flow == .onboardInvite {
                            let controller = GroupPickerController()
                            self.navigationController?.pushViewController(controller, animated: true)
                            MainController.instance.routeDeepLink(params: self.inputInviteParams, error: nil)
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
                    self.view.setNeedsLayout()
                    self.errorLabel.fadeIn()
                }
            }
        }
        else {  // Only happens if creating group
            
            FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { user, error in
                
                self.processing = false
                self.progress?.hide(true)

                if error == nil, let user = user {
                    /*
                     * - send verification email
                     */
                    var profileMap: [String: Any] = ["email": user.email!]
                    FireController.instance.addUser(userId: user.uid, profileMap: &profileMap, then: { success in
                        if success {
                            user.sendEmailVerification()
                            Reporting.track("Account Created")
                            UserController.instance.setUserId(userId: user.uid) { result in
                                let controller = GroupCreateController()
                                controller.flow = .onboardCreate
                                self.navigationController?.pushViewController(controller, animated: true)
                            }
                        }
                    })
                }
                else {
                    self.errorLabel.text = error?.localizedDescription
                    self.view.setNeedsLayout()
                    self.errorLabel.fadeIn()
                }
            })
        }
    }
    
    func reauthenticate() {
        
        guard !self.processing else { return }
        
        if let user = FIRAuth.auth()?.currentUser, let email = user.email {
            self.processing = true
            let password = self.passwordField.text!
            let credentials = FIREmailPasswordAuthProvider.credential(withEmail: email, password: password)
            user.reauthenticate(with: credentials, completion: { error in
                
                self.processing = false

                if error == nil {
                    let controller = AccountEditViewController()
                    self.navigationController?.pushViewController(controller, animated: true)
                }
                else {
                    self.errorLabel.text = error?.localizedDescription
                    self.view.setNeedsLayout()
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
