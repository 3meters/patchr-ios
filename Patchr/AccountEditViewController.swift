//
//  SignInViewController.swift
//  Teeny
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MBProgressHUD
import Firebase
import FirebaseAuth

class AccountEditViewController: BaseEditViewController {

    var message = AirLabelTitle()
    var emailField = FloatTextField()
    var userNameField = FloatTextField()
    var passwordButton = AirButton()
    var doneButton: UIBarButtonItem!
    
    /*--------------------------------------------------------------------------------------------
     * Lifecycle
     *--------------------------------------------------------------------------------------------*/
    
    override func loadView() {
        super.loadView()
        initialize()
        bind()
    }
    
    override func viewWillLayoutSubviews() {
        
        let messageSize = self.message.sizeThatFits(CGSize(width: Config.contentWidth, height:CGFloat.greatestFiniteMagnitude))
        
        self.message.anchorTopCenter(withTopPadding: 0, width: Config.contentWidth, height: messageSize.height)
        self.emailField.alignUnder(self.message, matchingCenterWithTopPadding: 16, width: Config.contentWidth, height: 48)
        self.userNameField.alignUnder(self.emailField, matchingCenterWithTopPadding: 8, width: Config.contentWidth, height: 48)
        self.passwordButton.alignUnder(self.userNameField, matchingCenterWithTopPadding: 16, width: Config.contentWidth, height: 48)
        
        super.viewWillLayoutSubviews()
    }
    
    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/
    
    func doneAction(sender: AnyObject) {
        if isValid() {
            if isDirty() {
                let _ = self.emailField.resignFirstResponder()
                
                self.progress = AirProgress.showAdded(to: self.view.window!, animated: true)
                self.progress?.mode = MBProgressHUDMode.indeterminate
                self.progress?.styleAs(progressStyle: .activityWithText)
                self.progress?.minShowTime = 0.5
                self.progress?.labelText = "Updating..."
                self.progress?.removeFromSuperViewOnHide = true
                self.progress?.show(true)
                
                guard !self.processing else { return }
                
                if self.emailField.text != Auth.auth().currentUser?.email {
                    self.processing = true
                    Reporting.track("validate_email")
                    verifyEmail()
                }
                if self.userNameField.text != UserController.instance.user?.username {
                    self.processing = true
                    Reporting.track("validate_username")
                    verifyUsername()
                }
            }
            else {
                close()
            }
        }
    }
    
    func cancelAction(sender: AnyObject) {
        close()
    }
    
    func changePasswordAction(sender: AnyObject) {
        Reporting.track("view_password_edit")
        let controller = PasswordEditViewController()
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        self.doneButton.isEnabled = isDirty()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.view.setNeedsLayout()
        self.doneButton.isEnabled = isDirty()
    }
    
    override func textViewDidEndEditing(_ textView: UITextView) {
        super.textViewDidEndEditing(textView)
        self.doneButton.isEnabled = isDirty()
    }
    
    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/
    
    override func initialize() {
        super.initialize()
        
        self.message.text = "Account"
        
        self.message.textColor = Theme.colorTextTitle
        self.message.numberOfLines = 0
        self.message.textAlignment = .center
        
        self.emailField.placeholder = "Email"
        self.emailField.setDelegate(delegate: self)
        self.emailField.autocapitalizationType = .none
        self.emailField.autocorrectionType = .no
        self.emailField.keyboardType = .emailAddress
        self.emailField.returnKeyType = .next
        
        self.userNameField.placeholder = "Username"
        self.userNameField.title = "Username (lower case)"
        self.userNameField.setDelegate(delegate: self)
        self.userNameField.autocapitalizationType = .none
        self.userNameField.autocorrectionType = .no
        self.userNameField.keyboardType = .default
        self.userNameField.returnKeyType = .next
        
        self.passwordButton.setTitle("Change password".uppercased(), for: .normal)
        self.passwordButton.addTarget(self, action: #selector(changePasswordAction(sender:)), for: .touchUpInside)
        
        self.contentHolder.addSubview(self.message)
        self.contentHolder.addSubview(self.emailField)
        self.contentHolder.addSubview(self.userNameField)
        self.contentHolder.addSubview(self.passwordButton)
        
        /* Navigation bar buttons */
        self.doneButton = UIBarButtonItem(title: "Update", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
        self.doneButton.isEnabled = false
        self.navigationItem.rightBarButtonItems = [self.doneButton]
        
        self.emailField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.userNameField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    func bind() {
        if let email = Auth.auth().currentUser?.email {
            self.emailField.text = email
        }
        if let username = UserController.instance.user?.username {
            self.userNameField.text = username
        }
    }
    
    func verifyEmail() {
        
        let email = self.emailField.text!
        
        FireController.instance.emailProviderExists(email: email, next: { [weak self] error, exists in
            guard let this = self else { return }
            if error != nil {
                this.progress?.hide(true)
                this.processing = false
                this.emailField.errorMessage = error!.localizedDescription
            }
            if exists {
                this.progress?.hide(true)
                this.processing = false
                Reporting.track("error_email_used", properties: ["email": email])
                this.emailField.errorMessage = "Email is already being used"
            }
            else {
                this.updateEmail()
            }
        })
    }
    
    func updateEmail() {
        
        if let authUser = Auth.auth().currentUser,
            let email = self.emailField.text {
            
            /* Update in firebase auth account */
            authUser.updateEmail(to: email, completion: { [weak self] error in
                guard let this = self else { return }
                if error == nil {
                    authUser.sendEmailVerification()
                }
                else {
                    this.progress?.hide(true)
                    this.processing = false
                    this.emailField.errorMessage = error!.localizedDescription
                }
            })
        }
    }
    
    func verifyUsername() {
        
        let username = self.userNameField.text!
        let userId = UserController.instance.userId!
        
        FireController.instance.usernameExists(username: username, next: { [weak self] error, exists in
            guard let this = self else { return }
            this.progress?.hide(true)
            this.processing = false
            if error != nil {
                this.userNameField.errorMessage = error!.localizedDescription
                return
            }
            if exists {
                Reporting.track("error_username_used", properties: ["username": username])
                this.userNameField.errorMessage = "Choose another username"
            }
            else {
                FireController.instance.updateUsername(userId: userId, username: username) { [weak self] error in
                    guard let this = self else { return }
                    if error == nil {
                        let _ = this.navigationController?.popToRootViewController(animated: true)
                    }
                    else {
                        this.userNameField.errorMessage = error!.localizedDescription
                    }
                }
            }
        })
    }
    
    func reauth() {
        let controller = PasswordViewController()
        let wrapper = AirNavigationController()
        controller.mode = .reauth
        wrapper.viewControllers = [controller]
        self.present(wrapper, animated: true)
    }
    
    func isValid() -> Bool {
        
        if self.emailField.isEmpty {
            self.emailField.errorMessage = "Enter an email address."
            return false
        }
        
        if !emailField.text!.isEmail() {
            self.emailField.errorMessage = "Enter a valid email address."
            return false
        }
        
        if self.userNameField.isEmpty {
            self.userNameField.errorMessage = "Choose your username"
            return false
        }
        
        let username = self.userNameField.text!
        let characterSet: NSCharacterSet = NSCharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_-")
        if username.rangeOfCharacter(from: characterSet.inverted) != nil {
            self.userNameField.errorMessage = "Lower case and no spaces or periods."
            return false
        }
        
        if (username.utf16.count > 21) {
            self.userNameField.errorMessage = "Username must be 21 characters or less."
            return false
        }
        
        if (username.utf16.count < 2) {
            self.userNameField.errorMessage = "Username must be at least 2 characters."
            return false
        }
        
        return true
    }
    
    func isDirty() -> Bool {
        if let email = Auth.auth().currentUser?.email, let username = UserController.instance.user?.username {
            return (self.emailField.text! != email || self.userNameField.text! != username)
        }
        return false
    }
}
