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

class EmailViewController: BaseEditViewController {

    var emailField = AirTextField()
    var errorLabel = AirLabelDisplay()
    var message = AirLabelTitle()

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func loadView() {
        super.loadView()
        initialize()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.emailField.becomeFirstResponder()
    }

    override func viewWillLayoutSubviews() {

        let messageSize = self.message.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        let errorSize = self.errorLabel.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        
        self.message.anchorTopCenter(withTopPadding: 0, width: 288, height: messageSize.height)
        self.emailField.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        self.errorLabel.alignUnder(self.emailField, matchingCenterWithTopPadding: 0, width: 288, height: errorSize.height)

        super.viewWillLayoutSubviews()
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    func doneAction(sender: AnyObject) {
        if isValid() {
            self.emailField.resignFirstResponder()

            self.progress = AirProgress.showAdded(to: self.view.window!, animated: true)
            self.progress?.mode = MBProgressHUDMode.indeterminate
            self.progress?.styleAs(progressStyle: .ActivityWithText)
            self.progress?.minShowTime = 0.5
            self.progress?.labelText = "Verifying..."
            self.progress?.removeFromSuperViewOnHide = true
            self.progress?.show(true)
            
            validateEmail()
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

        if self.flow == .onboardLogin {
            self.message.text = "Welcome back."
        }
        else {
            self.message.text = "Patchr groups are for control enthusiasts."
        }

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
        
        self.contentHolder.addSubview(self.message)
        self.contentHolder.addSubview(self.emailField)
        self.contentHolder.addSubview(self.errorLabel)
        
        if self.flow == .onboardCreate {
            self.navigationItem.title = "Step 1 of 3"
        }
        
        /* Navigation bar buttons */
        let nextButton = UIBarButtonItem(title: "Next", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
        self.navigationItem.rightBarButtonItems = [nextButton]

        self.emailField.text = UserDefaults.standard.object(forKey: PatchrUserDefaultKey(subKey: "userEmail")) as? String
    }
    
    func validateEmail() {
        
        guard !self.processing else { return }
        self.processing = true
        
        let email = self.emailField.text!
        
        FireController.instance.emailExists(email: email, next: { exists in
            
            self.progress?.hide(true)
            self.processing = false
            
            if self.flow == .onboardLogin {
                if !exists {
                    self.errorLabel.text = "No account found."
                    self.errorLabel.fadeIn()
                }
                else {
                    let controller = PasswordViewController()
                    controller.flow = .onboardLogin
                    controller.inputEmail = email
                    controller.inputEmailExists = true
                    self.navigationController?.pushViewController(controller, animated: true)
                }
            }
            else {
                let controller = PasswordViewController()
                controller.flow = .onboardCreate
                controller.inputEmail = email
                controller.inputEmailExists = exists
                self.navigationController?.pushViewController(controller, animated: true)
            }
        })
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

    override func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        if textField == self.emailField {
            self.doneAction(sender: textField)
        }

        return true
    }
}
