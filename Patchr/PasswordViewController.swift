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
    var inputInviteLink: [AnyHashable: Any]!
    
    var message = AirLabelTitle()
    var userNameField = FloatTextField(frame: CGRect.zero)
    var passwordField = FloatTextField(frame: CGRect.zero)
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
        if self.branch == .signup {
            let _ = self.userNameField.becomeFirstResponder()
        }
        else {
            let _ = self.passwordField.becomeFirstResponder()
        }
    }

    override func viewWillLayoutSubviews() {

        let messageSize = self.message.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        
        self.message.anchorTopCenter(withTopPadding: 0, width: 288, height: messageSize.height)
        
        if self.branch == .signup {
            self.userNameField.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 288, height: 48)
            self.passwordField.alignUnder(self.userNameField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        }
        else {
            self.passwordField.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 288, height: 48)
            self.forgotPasswordButton.alignUnder(self.passwordField, matchingCenterWithTopPadding: 36, width: 288, height: 48)
        }

        super.viewWillLayoutSubviews()
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    func doneAction(sender: AnyObject) {
        if isValid() {
            let _ = self.passwordField.resignFirstResponder()
            
            if self.mode == .reauth {
                reauthenticate()
            }
            else {
                self.progress = AirProgress.showAdded(to: self.view.window!, animated: true)
                self.progress?.mode = MBProgressHUDMode.indeterminate
                self.progress?.styleAs(progressStyle: .activityWithText)
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
                self.alert(title: "A password reset email has been sent to your email address.")
            }
        }
    }

    func cancelAction(sender: AnyObject) {
        close()
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
        
        self.userNameField.placeholder = "Username"
        self.userNameField.title = "Username (lower case)"
        self.userNameField.setDelegate(delegate: self)
        self.userNameField.keyboardType = .default
        self.userNameField.autocapitalizationType = .none
        self.userNameField.autocorrectionType = .no
        self.userNameField.returnKeyType = UIReturnKeyType.next

        self.passwordField.placeholder = "Password"
        self.passwordField.title = "Password (6+ characters)"
        self.passwordField.setDelegate(delegate: self)
        self.passwordField.isSecureTextEntry = true
        self.passwordField.autocapitalizationType = .none
        self.passwordField.keyboardType = UIKeyboardType.default
        self.passwordField.returnKeyType = UIReturnKeyType.next
        self.passwordField.rightView = self.hideShowButton
        self.passwordField.rightViewMode = .always

        self.hideShowButton.bounds.size = CGSize(width:48, height:48)
        self.hideShowButton.imageEdgeInsets = UIEdgeInsetsMake(8, 10, 8, 10)
        self.hideShowButton.addTarget(self, action: #selector(hideShowPasswordAction(sender:)), for: .touchUpInside)
        
        if self.mode == .reauth || self.branch == .signup {
            self.forgotPasswordButton.isHidden = true
        }
        else {
            self.forgotPasswordButton.setTitle("Forgot password?", for: .normal)
            self.forgotPasswordButton.addTarget(self, action: #selector(passwordResetAction(sender:)), for: .touchUpInside)
            self.contentHolder.addSubview(self.forgotPasswordButton)
        }
        
        self.contentHolder.addSubview(self.message)
        self.contentHolder.addSubview(self.passwordField)
        
        if self.branch == .signup {
            self.contentHolder.addSubview(self.userNameField)
        }

        /* Navigation bar buttons */
        let nextButton = UIBarButtonItem(title: "Next", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
        self.navigationItem.rightBarButtonItems = [nextButton]
    }

    func authenticate() {

        guard !self.processing else { return }
        self.processing = true
        
        let password = self.passwordField.text!
        let email = self.inputEmail!
        
        if self.branch == .login {
            FIRAuth.auth()?.signIn(withEmail: email, password: password) { user, error in
                self.authenticated(user: user, error: error)
            }
        }
        else {  // Only happens if creating group
            
            FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { user, error in
                
                self.processing = false
                self.progress?.hide(true)

                if error == nil, let user = user {
                    let username = self.userNameField.text!
                    let email = user.email!
                    FireController.instance.addUser(userId: user.uid, username: username, email: email, then: { success in
                        if success {
                            user.sendEmailVerification()
                            Reporting.track("Account Created")
                            UserController.instance.setUserId(userId: user.uid) { result in
                                if self.flow == .onboardCreate {
                                    let controller = GroupCreateController()
                                    controller.flow = self.flow
                                    self.navigationController?.pushViewController(controller, animated: true)
                                }
                                else if self.flow == .onboardInvite {
                                    let controller = EmptyViewController()
                                    self.navigationController?.setViewControllers([controller], animated: true)
                                    MainController.instance.routeDeepLink(link: self.inputInviteLink, error: nil)
                                }
                            }
                        }
                    })
                }
                else {
                    self.passwordField.errorMessage = error?.localizedDescription
                }
            })
        }
    }
    
    func authenticated(user: FIRUser?, error: Error?) {
        self.processing = false
        self.progress?.hide(true)
        
        if error == nil {
            Reporting.track("Logged In")
            UserController.instance.setUserId(userId: (user?.uid)!) { [weak self] result in
                if self != nil {
                    if self!.flow == .onboardLogin {
                        let controller = GroupSwitcherController()
                        self!.navigationController?.pushViewController(controller, animated: true)
                    }
                    else if self!.flow == .onboardCreate {
                        let controller = GroupCreateController()
                        controller.flow = self!.flow
                        self!.navigationController?.pushViewController(controller, animated: true)
                    }
                    else if self!.flow == .onboardInvite {
                        let controller = EmptyViewController()
                        self!.navigationController?.setViewControllers([controller], animated: true)
                        MainController.instance.routeDeepLink(link: self!.inputInviteLink, error: nil)
                    }
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
            self.passwordField.errorMessage = errorMessage
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
        
        if self.branch == .signup {
            
            if self.userNameField.isEmpty {
                self.userNameField.errorMessage = "Choose your username"
                return false
            }
            
            let username = userNameField.text!
            let characterSet: NSCharacterSet = NSCharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_-")
            if username.rangeOfCharacter(from: characterSet.inverted) != nil {
                self.userNameField.errorMessage = "Username must be lower case and cannot contain spaces or periods."
                return false
            }
            
            if (userNameField.text!.utf16.count > 21) {
                self.userNameField.errorMessage = "Username must be 21 characters or less."
                return false
            }
            
            if (userNameField.text!.utf16.count < 3) {
                self.userNameField.errorMessage = "Username must be at least 3 characters."
                return false
            }
        }

        return true
    }

    override func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        if textField == self.userNameField {
            let _ = passwordField.becomeFirstResponder()
        }
        else if textField == self.passwordField {
            self.doneAction(sender: textField)
            return false
        }
        return true
    }
}
