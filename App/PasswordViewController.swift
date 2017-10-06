//
//  SignInViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import FirebaseAuth
import Firebase
import Localize_Swift
import MBProgressHUD
import PopupDialog
import UIKit

class PasswordViewController: BaseEditViewController {
    
    var inputEmail: String!
    var inputInviteLink: [AnyHashable: Any]!
    
    var message = AirLabelTitle()
    var userNameField = FloatTextField(frame: CGRect.zero)
    var passwordField = FloatTextField(frame: CGRect.zero)
    var hideShowButton = AirHideShowButton()
    var forgotPasswordButton = AirLinkButton()
    var nextButton: UIBarButtonItem!

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

    @objc func doneAction(sender: AnyObject) {
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
                self.progress?.labelText = self.branch == .login ? "\("progress_logging_in".localized())..." : "\("progress_signing_up".localized())..."
                authenticate()
            }
        }
        else {
            Reporting.track("password_validation_error")
        }
    }

    @objc func hideShowPasswordAction(sender: AnyObject?) {
        if let button = sender as? AirHideShowButton {
            Reporting.track(button.toggledOn ? "hide_password" : "show_password")
            button.toggle(on: !button.toggledOn)
            self.passwordField.isSecureTextEntry = !button.toggledOn
        }
    }

    @objc func passwordResetAction(sender: AnyObject) {
        Auth.auth().sendPasswordReset(withEmail: self.inputEmail) { error in
            if error == nil {
                Reporting.track("request_password_reset")
                self.alert(title: "password_reset_email_sent".localized())
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
        
        self.message.textColor = Theme.colorTextTitle
        self.message.numberOfLines = 0
        self.message.textAlignment = .center
        
        self.userNameField.setDelegate(delegate: self)
        self.userNameField.keyboardType = .default
        self.userNameField.autocapitalizationType = .none
        self.userNameField.autocorrectionType = .no
        self.userNameField.returnKeyType = UIReturnKeyType.next

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
            self.forgotPasswordButton.addTarget(self, action: #selector(passwordResetAction(sender:)), for: .touchUpInside)
            self.contentHolder.addSubview(self.forgotPasswordButton)
        }
        
        self.contentHolder.addSubview(self.message)
        self.contentHolder.addSubview(self.passwordField)
        
        if self.branch == .signup {
            self.contentHolder.addSubview(self.userNameField)
        }

        /* Navigation bar buttons */
        self.nextButton = UIBarButtonItem(title: nil, style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
        self.navigationItem.rightBarButtonItems = [nextButton]
        bindLanguage()
    }
    
    func bindLanguage() {
        self.message.text = (self.mode == .reauth)
            ? "password_confirmation".localized()
            : "password_view_title".localized()
        self.userNameField.placeholder = "username".localized()
        self.userNameField.title = "username_title".localized()
        self.passwordField.placeholder = "password".localized()
        self.passwordField.title = "password_title".localized()
        self.forgotPasswordButton.setTitle("password_forgot".localized(), for: .normal)
        self.nextButton.title = "next".localized()
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
                self.processing = false
                self.progress?.hide(true)
                self.authenticated(user: authUser, email: email, error: error)
            }
        }
        else if self.branch == .signup {
            
            Auth.auth().createUser(withEmail: email, password: password, completion: { authUser, error in
                
                if error == nil, let authUser = authUser {
                    let username = self.userNameField.text!
                    let email = authUser.email!
                    Reporting.track("create_user_account", properties:["uid": authUser.uid])
                    UserDefaults.standard.set(email, forKey: Prefs.lastUserEmail)
                    
                    FireController.instance.addUser(userId: authUser.uid, username: username) { [weak self] error, channelId in
                        guard let this = self else { return }
                        this.processing = false
                        this.progress?.hide(true)
                        if error == nil {
                            authUser.sendEmailVerification()
                        }
                        this.authenticated(user: authUser, email: email, channelId: channelId, error: error)
                    }
                }
                else {
                    self.processing = false
                    self.progress?.hide(true)
                    self.passwordField.errorMessage = error?.localizedDescription
                }
            })
        }
    }
    
    func authenticated(user: User?, email: String?, channelId: String? = nil, error: Error?) {
        
        if error == nil {
            Reporting.track("login", properties:["uid": user!.uid])
            UserController.instance.setUserId(userId: (user?.uid)!) { [weak self] result in
                guard let this = self else { return }
                if this.flow == .onboardSignup, let channelId = channelId {
                    Reporting.track("view_channel")
                    StateController.instance.setChannelId(channelId: channelId)
                    MainController.instance.showChannel(channelId: channelId) { // User permissions are in place
                        Utils.delay(0.5) {
                            if let topController = UIViewController.topController {
                                let popup = PopupDialog(title: "\("channel_welcome_title".localized()) \(Strings.appName)!"
                                    , message: "channel_welcome_message".localized())
                                let button = DefaultButton(title: "ok".localized().uppercased(), height: 48) {
                                    Reporting.track("sign_up_carry_on")
                                }
                                popup.addButton(button)
                                topController.present(popup, animated: true)
                            }
                        }
                    }
                }
                else if this.flow == .onboardInvite {
                    Reporting.track("resume_invite")
                    MainController.instance.routeDeepLink(link: this.inputInviteLink, flow: this.flow, error: nil)
                }
                else {
                    Reporting.track("view_channels")
                    MainController.instance.showChannelsGrid()
                }
            }
        }
        else {
            var errorMessage = error?.localizedDescription
            if error!._code == AuthErrorCode.emailAlreadyInUse.rawValue {
                Reporting.track("login_error", properties:["message": "email_already_used", "email": email!])
                errorMessage = "email_used".localized()
            }
            else if error!._code == AuthErrorCode.invalidEmail.rawValue {
                Reporting.track("login_error", properties:["message": "email_address_not_valid", "email": email!])
                errorMessage = "email_invalid".localized()
            }
            else if error!._code == AuthErrorCode.wrongPassword.rawValue {
                Reporting.track("login_error", properties:["message": "wrong_password"])
                errorMessage = "email_auth_fail".localized()
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
                    self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "back".localized(), style: .plain, target: nil, action: nil)
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
            self.passwordField.errorMessage = "password_too_short".localized()
            return false
        }
        
        if self.branch == .signup {
            
            if self.userNameField.isEmpty {
                self.userNameField.errorMessage = "username_empty".localized()
                return false
            }
            
            let username = userNameField.text!
            let characterSet: NSCharacterSet = NSCharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_-")
            if username.rangeOfCharacter(from: characterSet.inverted) != nil {
                self.userNameField.errorMessage = "username_invalid_chars".localized()
                return false
            }
            
            if (userNameField.text!.utf16.count > 21) {
                self.userNameField.errorMessage = "username_too_long".localized()
                return false
            }
            
            if (userNameField.text!.utf16.count < 3) {
                self.userNameField.errorMessage = "username_too_short".localized()
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
