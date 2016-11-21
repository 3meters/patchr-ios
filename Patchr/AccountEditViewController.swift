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
    var emailField = AirTextField()
    var errorLabel = AirLabelDisplay()
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
        super.viewWillLayoutSubviews()
        
        let messageSize = self.message.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        let errorSize = self.errorLabel.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        
        self.message.anchorTopCenter(withTopPadding: 0, width: 288, height: messageSize.height)
        self.emailField.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        self.errorLabel.alignUnder(self.emailField, matchingCenterWithTopPadding: 0, width: 288, height: errorSize.height)
        self.passwordButton.alignUnder(self.emailField, matchingCenterWithTopPadding: 36, width: 288, height: 48)
        
        self.contentHolder.resizeToFitSubviews()
        self.scrollView.contentSize = CGSize(width:self.contentHolder.frame.size.width, height:self.contentHolder.frame.size.height + CGFloat(32))
        self.contentHolder.anchorTopCenterFillingWidth(withLeftAndRightPadding: 16, topPadding: 16, height: self.contentHolder.frame.size.height)
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
                self.progress?.styleAs(progressStyle: .ActivityWithText)
                self.progress?.minShowTime = 0.5
                self.progress?.labelText = "Updating..."
                self.progress?.removeFromSuperViewOnHide = true
                self.progress?.show(true)
                
                validateEmail()
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
    
    override func textFieldDidBeginEditing(_ textField: UITextField) {
        super.textFieldDidBeginEditing(textField)
        self.errorLabel.fadeOut()
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
        self.emailField.delegate = self
        self.emailField.keyboardType = UIKeyboardType.emailAddress
        self.emailField.autocapitalizationType = .none
        self.emailField.autocorrectionType = .no
        self.emailField.returnKeyType = UIReturnKeyType.next
        
        self.errorLabel.textColor = Theme.colorTextValidationError
        self.errorLabel.alpha = 0.0
        self.errorLabel.numberOfLines = 0
        self.errorLabel.font = Theme.fontValidationError
        
        self.passwordButton.setTitle("Change password".uppercased(), for: .normal)
        self.passwordButton.addTarget(self, action: #selector(changePasswordAction(sender:)), for: .touchUpInside)
        
        self.contentHolder.addSubview(self.message)
        self.contentHolder.addSubview(self.emailField)
        self.contentHolder.addSubview(self.errorLabel)
        self.contentHolder.addSubview(self.passwordButton)
        
        /* Navigation bar buttons */
        let doneButton = UIBarButtonItem(title: "Update", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
        self.navigationItem.rightBarButtonItems = [doneButton]
    }
    
    func bind() {
        if let email = FIRAuth.auth()?.currentUser?.email {
            self.emailField.text = email
        }
    }
    
    func validateEmail() {
        
        guard !self.processing else { return }
        self.processing = true
        
        let email = self.emailField.text!
        
        FireController.instance.emailExists(email: email, next: { exists in
            
            self.progress?.hide(true)
            self.processing = false
            
            if exists {
                self.errorLabel.text = "Email is already being used"
                self.errorLabel.fadeIn()
            }
            else {
                self.updateEmail()
            }
        })
    }
    
    func updateEmail() {
        if let authUser = FIRAuth.auth()?.currentUser, let user = UserController.instance.user {
            let email = self.emailField.text!
            authUser.updateEmail(email, completion: { error in
                if error == nil {
                    FireController.db.child(user.path).updateChildValues([
                        "modified_at": FIRServerValue.timestamp(),
                        "email": email
                    ]) { error, ref in
                        if error == nil {
                            let _ = self.navigationController?.popToRootViewController(animated: true)
                        }
                        else {
                            self.errorLabel.text = error?.localizedDescription
                            self.errorLabel.fadeIn()
                        }
                    }
                }
                else {
                    self.errorLabel.text = error?.localizedDescription
                    self.errorLabel.fadeIn()
                }
            })
        }
    }
    
    func reauth() {
        let controller = PasswordViewController()
        let wrapper = AirNavigationController()
        controller.mode = .reauth
        wrapper.viewControllers = [controller]
        self.present(wrapper, animated: true)
    }
    
    func isValid() -> Bool {
        
        if emailField.isEmpty {
            self.errorLabel.text = "Enter an email address."
            self.view.setNeedsLayout()
            self.errorLabel.fadeIn()
            return false
        }
        
        if !emailField.text!.isEmail() {
            self.errorLabel.text = "Enter a valid email address."
            self.view.setNeedsLayout()
            self.errorLabel.fadeIn()
            return false
        }
        
        return true
    }
    
    func isDirty() -> Bool {
        if let email = FIRAuth.auth()?.currentUser?.email {
            return (emailField.text! != email)
        }
        return false
    }
    
    override func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.emailField {
            self.doneAction(sender: textField)
        }
        return true
    }
}
