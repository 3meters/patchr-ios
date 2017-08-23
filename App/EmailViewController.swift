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

class EmailViewController: BaseEditViewController {
    
    var inputInviteLink: [AnyHashable: Any]!

    var emailField = FloatTextField(frame: CGRect.zero)
    var message = AirLabelTitle()

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func loadView() {
        super.loadView()
        initialize()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let _ = self.emailField.becomeFirstResponder()
    }

    override func viewWillLayoutSubviews() {

        let messageSize = self.message.sizeThatFits(CGSize(width: Config.contentWidth, height:CGFloat.greatestFiniteMagnitude))        
        self.message.anchorTopCenter(withTopPadding: 0, width: Config.contentWidth, height: messageSize.height)
        self.emailField.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: Config.contentWidth, height: 48)

        super.viewWillLayoutSubviews()
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    func doneAction(sender: AnyObject) {
        if isValid() {
            let _ = self.emailField.resignFirstResponder()

            self.progress = AirProgress.showAdded(to: self.view.window!, animated: true)
            self.progress?.mode = MBProgressHUDMode.indeterminate
            self.progress?.styleAs(progressStyle: .activityWithText)
            self.progress?.minShowTime = 0.5
            self.progress?.labelText = "Verifying..."
            self.progress?.removeFromSuperViewOnHide = true
            self.progress?.show(true)
            Reporting.track("validate_email")
            validateEmail()
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
        
        if self.flow == .onboardLogin {
            self.message.text = "Welcome back."
        }
        else if self.flow == .onboardInvite {
            self.message.text = "Welcome."
        }
        else if self.flow == .onboardSignup {
            self.message.text = "Teeny channels are perfect for just enough sharing."
        }

        self.message.textColor = Theme.colorTextTitle
        self.message.numberOfLines = 0
        self.message.textAlignment = .center

        self.emailField.placeholder = "Email"
        self.emailField.setDelegate(delegate: self)
        self.emailField.keyboardType = UIKeyboardType.emailAddress
        self.emailField.autocapitalizationType = .none
        self.emailField.autocorrectionType = .no
        self.emailField.returnKeyType = UIReturnKeyType.next
        if let email = UserDefaults.standard.string(forKey: Prefs.lastUserEmail) {
            self.emailField.text = email
        }
        
        self.contentHolder.addSubview(self.message)
        self.contentHolder.addSubview(self.emailField)
        
        /* Navigation bar buttons */
        let nextButton = UIBarButtonItem(title: "Next", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
        self.navigationItem.rightBarButtonItems = [nextButton]
    }
    
    func validateEmail() {
        
        guard !self.processing else { return }
        self.processing = true
        
        let email = self.emailField.text!
        
        FireController.instance.emailProviderExists(email: email, next: { error, exists in
            
            self.progress?.hide(true)
            self.processing = false
            
            if error != nil {
                self.emailField.errorMessage = error!.localizedDescription
                return
            }
            
            if self.flow == .onboardLogin {
                if !exists {
                    Reporting.track("email_account_not_found", properties: ["email": email])
                    self.emailField.errorMessage = "No account found."
                }
                else {
                    Reporting.track("email_found")
                    Reporting.track("view_password_entry")
                    let controller = PasswordViewController()
                    controller.flow = self.flow
                    controller.branch = .login
                    controller.inputEmail = email
                    self.navigationController?.pushViewController(controller, animated: true)
                }
            }
            else if self.flow == .onboardInvite {
                Reporting.track("view_password_entry")
                let controller = PasswordViewController()
                controller.flow = self.flow
                controller.branch = exists ? .login : .signup
                controller.inputEmail = email
                controller.inputInviteLink = self.inputInviteLink
                self.navigationController?.pushViewController(controller, animated: true)
            }
            else if self.flow == .onboardSignup {
                Reporting.track("view_password_entry")
                let controller = PasswordViewController()
                controller.flow = self.flow
                controller.branch = exists ? .login : .signup
                controller.inputEmail = email
                self.navigationController?.pushViewController(controller, animated: true)
            }
        })
    }

    func isValid() -> Bool {

        if emailField.isEmpty {
            self.emailField.errorMessage = "Enter an email address."
            return false
        }

        if !emailField.text!.isEmail() {
            self.emailField.errorMessage = "Enter a valid email address."
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
