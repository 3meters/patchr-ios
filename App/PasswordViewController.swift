//
//  SignInViewController.swift
//  Teeny
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
    * MARK: - Lifecycle
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

        let messageSize = self.message.sizeThatFits(CGSize(width: Config.contentWidth, height:CGFloat.greatestFiniteMagnitude))
        self.message.anchorTopCenter(withTopPadding: 0, width: Config.contentWidth, height: messageSize.height)
        if self.branch == .signup {
            self.userNameField.alignUnder(self.message, matchingCenterWithTopPadding: 16, width: Config.contentWidth, height: 48)
            self.passwordField.alignUnder(self.userNameField, matchingCenterWithTopPadding: 8, width: Config.contentWidth, height: 48)
        }
        else {
            self.passwordField.alignUnder(self.message, matchingCenterWithTopPadding: 16, width: Config.contentWidth, height: 48)
            self.forgotPasswordButton.alignUnder(self.passwordField, matchingCenterWithTopPadding: 36, width: Config.contentWidth, height: 48)
        }

        super.viewWillLayoutSubviews()
    }

    /*--------------------------------------------------------------------------------------------
    * MARK: - Events
    *--------------------------------------------------------------------------------------------*/

    func doneAction(sender: AnyObject) {
        if isValid() {
            let _ = self.passwordField.resignFirstResponder()
            Reporting.track("submit_password")
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
        else {
            Reporting.track("password_validation_error")
        }
    }

    func hideShowPasswordAction(sender: AnyObject?) {
        if let button = sender as? AirHideShowButton {
            Reporting.track(button.toggledOn ? "hide_password" : "show_password")
            button.toggle(on: !button.toggledOn)
            self.passwordField.isSecureTextEntry = !button.toggledOn
        }
    }

    func passwordResetAction(sender: AnyObject) {
        Auth.auth().sendPasswordReset(withEmail: self.inputEmail) { error in
            if error == nil {
                Reporting.track("request_password_reset")
                self.alert(title: "A password reset email has been sent to your email address.")
            }
        }
    }

    func cancelAction(sender: AnyObject) {
        close()
    }
    
    /*--------------------------------------------------------------------------------------------
    * MARK: - Methods
    *--------------------------------------------------------------------------------------------*/

    override func initialize() {
        super.initialize()
        
        self.message.text = (self.mode == .reauth)
            ? "Password confirmation"
            : "Almost to the good stuff."
        
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
        self.passwordField.keyboardType = .default
        self.passwordField.returnKeyType = .next
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
            Auth.auth().signIn(withEmail: email, password: password) { authUser, error in
                if error == nil {
                    UserDefaults.standard.set(email, forKey: Prefs.lastUserEmail)
                }
                self.authenticated(user: authUser, email: email, error: error)
            }
        }
        else if self.branch == .signup {
            
            Auth.auth().createUser(withEmail: email, password: password, completion: { authUser, error in
                
                self.processing = false
                self.progress?.hide(true)

                if error == nil, let authUser = authUser {
                    let username = self.userNameField.text!
                    let email = authUser.email!
                    Reporting.track("create_user_account", properties:["uid": authUser.uid])
                    UserDefaults.standard.set(email, forKey: Prefs.lastUserEmail)
                    
                    FireController.instance.addUser(userId: authUser.uid, username: username) { [weak self] error, result in
                        guard let this = self else { return }
                        if error == nil {
                            authUser.sendEmailVerification()
                            this.authenticated(user: authUser, email: email, error: error)
                        }
                    }
                }
                else {
                    self.passwordField.errorMessage = error?.localizedDescription
                }
            })
        }
    }
    
    func authenticated(user: User?, email: String?, error: Error?) {
        self.processing = false
        self.progress?.hide(true)
        
        if error == nil {
            Reporting.track("login", properties:["uid": user!.uid])
            UserController.instance.setUserId(userId: (user?.uid)!) { [weak self] result in
                guard let this = self else { return }
                if this.flow == .onboardLogin || this.flow == .onboardSignup {
                    Reporting.track("view_channels")
                    MainController.instance.showChannelsGrid()
                }
                else if this.flow == .onboardInvite {
                    Reporting.track("resume_invite")
                    MainController.instance.routeDeepLink(link: this.inputInviteLink, flow: this.flow, error: nil)
                }
            }
        }
        else {
            var errorMessage = error?.localizedDescription
            if error!._code == AuthErrorCode.emailAlreadyInUse.rawValue {
                Reporting.track("login_error", properties:["message": "email_already_used", "email": email!])
                errorMessage = "Email already used"
            }
            else if error!._code == AuthErrorCode.invalidEmail.rawValue {
                Reporting.track("login_error", properties:["message": "email_address_not_valid", "email": email!])
                errorMessage = "Email address is not valid"
            }
            else if error!._code == AuthErrorCode.wrongPassword.rawValue {
                Reporting.track("login_error", properties:["message": "wrong_password"])
                errorMessage = "Wrong email and password combination"
            }
            self.passwordField.errorMessage = errorMessage
        }
    }
    
    func reauthenticate() {
        
        guard !self.processing else { return }
        
        if let user = Auth.auth().currentUser, let email = user.email {
            self.processing = true
            let password = self.passwordField.text!
            let credentials = EmailAuthProvider.credential(withEmail: email, password: password)
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
