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

class AccountEditViewController: BaseEditViewController {

    var message = AirLabelTitle()
    var emailField = TextFieldView()
    var userNameField = TextFieldView()
    var passwordButton = AirButton()
    
    /*--------------------------------------------------------------------------------------------
     * Lifecycle
     *--------------------------------------------------------------------------------------------*/
    
    override func loadView() {
        super.loadView()
        initialize()
        bind()
    }
    
    override func viewWillLayoutSubviews() {
        
        let messageSize = self.message.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        
        self.message.anchorTopCenter(withTopPadding: 0, width: 288, height: messageSize.height)
        self.emailField.alignUnder(self.message, matchingCenterWithTopPadding: 16, width: 288, height: 48 + emailField.errorLabel.height())
        self.userNameField.alignUnder(self.emailField, matchingCenterWithTopPadding: 8, width: 288, height: 48 + userNameField.errorLabel.height())
        self.passwordButton.alignUnder(self.userNameField, matchingCenterWithTopPadding: 16, width: 288, height: 48)
        
        super.viewWillLayoutSubviews()
    }
    
    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/
    
    func doneAction(sender: AnyObject) {
        if isValid() {
            if isDirty() {
                self.emailField.resignFirstResponder()
                
                self.progress = AirProgress.showAdded(to: self.view.window!, animated: true)
                self.progress?.mode = MBProgressHUDMode.indeterminate
                self.progress?.styleAs(progressStyle: .activityWithText)
                self.progress?.minShowTime = 0.5
                self.progress?.labelText = "Updating..."
                self.progress?.removeFromSuperViewOnHide = true
                self.progress?.show(true)
                
                guard !self.processing else { return }
                
                if self.emailField.textField.text != FIRAuth.auth()?.currentUser?.email {
                    self.processing = true
                    verifyEmail()
                }
                else if self.userNameField.textField.text != UserController.instance.user?.username {
                    self.processing = true
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
        let controller = PasswordEditViewController()
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.emailField.textField {
            clearErrorIfNeeded(self.emailField)
        }
        else if textField == self.userNameField.textField {
            clearErrorIfNeeded(self.userNameField)
        }
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if textField == self.emailField.textField {
            clearErrorIfNeeded(self.emailField)
        }
        else if textField == self.userNameField.textField {
            clearErrorIfNeeded(self.userNameField)
        }
        return true
    }
    
    override func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.emailField.textField {
            self.userNameField.becomeFirstResponder()
        }
        else if textField == self.userNameField {
            self.doneAction(sender: textField)
        }
        return true
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
        
        self.emailField.textField.placeholder = "Email"
        self.emailField.textField.delegate = self
        self.emailField.textField.keyboardType = .emailAddress
        self.emailField.textField.autocapitalizationType = .none
        self.emailField.textField.autocorrectionType = .no
        self.emailField.textField.returnKeyType = .next
        
        self.userNameField.textField.placeholder = "Username (lower case)"
        self.userNameField.textField.delegate = self
        self.userNameField.textField.keyboardType = .default
        self.userNameField.textField.autocapitalizationType = .none
        self.userNameField.textField.autocorrectionType = .no
        self.userNameField.textField.returnKeyType = .next
        
        self.passwordButton.setTitle("Change password".uppercased(), for: .normal)
        self.passwordButton.addTarget(self, action: #selector(changePasswordAction(sender:)), for: .touchUpInside)
        
        self.contentHolder.addSubview(self.message)
        self.contentHolder.addSubview(self.emailField)
        self.contentHolder.addSubview(self.userNameField)
        self.contentHolder.addSubview(self.passwordButton)
        
        /* Navigation bar buttons */
        let doneButton = UIBarButtonItem(title: "Update", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
        self.navigationItem.rightBarButtonItems = [doneButton]
    }
    
    func bind() {
        if let email = FIRAuth.auth()?.currentUser?.email {
            self.emailField.textField.text = email
        }
        if let username = UserController.instance.user?.username {
            self.userNameField.textField.text = username
        }
    }
    
    func verifyEmail() {
        
        let email = self.emailField.textField.text!
        
        FireController.instance.emailProviderExists(email: email, next: { error, exists in
            if error != nil {
                self.progress?.hide(true)
                self.processing = false
                self.showError(self.emailField, error: error!.localizedDescription)
            }
            if exists {
                self.progress?.hide(true)
                self.processing = false
                self.showError(self.emailField, error: "Email is already being used")
            }
            else {
                self.updateEmail()
            }
        })
    }
    
    func updateEmail() {
        
        if let authUser = FIRAuth.auth()?.currentUser,
            let userId = UserController.instance.userId,
            let email = self.emailField.textField.text {
            
            /* Update in firebase auth account */
            authUser.updateEmail(email, completion: { error in
                if error == nil {
                    authUser.sendEmailVerification()
                    
                    /* Update in memberships that share email */
                    FireController.instance.updateEmail(userId: userId, email: email) { error in
                        if error == nil {
                            if self.userNameField.textField.text != UserController.instance.user?.username {
                                self.verifyUsername()
                                return
                            }
                            self.progress?.hide(true)
                            self.processing = false
                            let _ = self.navigationController?.popToRootViewController(animated: true)
                        }
                        else {
                            self.progress?.hide(true)
                            self.processing = false
                            self.showError(self.emailField, error: error!.localizedDescription)
                        }
                    }
                }
                else {
                    self.progress?.hide(true)
                    self.processing = false
                    self.showError(self.emailField, error: error!.localizedDescription)
                }
            })
        }
    }
    
    func verifyUsername() {
        
        let username = self.userNameField.textField.text!
        
        FireController.instance.usernameExists(username: username, next: { error, exists in
            self.progress?.hide(true)
            self.processing = false
            if error != nil {
                self.showError(self.userNameField, error: error!.localizedDescription)
                return
            }
            if exists {
                self.showError(self.userNameField, error: "Choose another username")
            }
            else {
                let userId = UserController.instance.userId!
                FireController.instance.updateUsername(userId: userId, username: username) { error, result in
                    if error == nil {
                        let _ = self.navigationController?.popToRootViewController(animated: true)
                    }
                    else {
                        let message = error!["message"] as! String
                        self.showError(self.userNameField, error: message)
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
        
        if self.emailField.textField.isEmpty {
            showError(self.emailField, error: "Enter an email address.")
            return false
        }
        
        if !emailField.textField.text!.isEmail() {
            showError(self.emailField, error: "Enter a valid email address.")
            return false
        }
        
        if self.userNameField.textField.isEmpty {
            showError(self.userNameField, error: "Choose your username")
            return false
        }
        
        let username = self.userNameField.textField.text!
        let characterSet: NSCharacterSet = NSCharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_-")
        if username.rangeOfCharacter(from: characterSet.inverted) != nil {
            showError(self.userNameField, error: "Username must be lower case and cannot contain spaces or periods.")
            return false
        }
        
        if (username.utf16.count > 21) {
            showError(self.userNameField, error: "Username must be 21 characters or less.")
            return false
        }
        
        return true
    }
    
    func isDirty() -> Bool {
        if let email = FIRAuth.auth()?.currentUser?.email, let username = UserController.instance.user?.username {
            return (self.emailField.textField.text! != email || self.userNameField.textField.text! != username)
        }
        return false
    }
}
