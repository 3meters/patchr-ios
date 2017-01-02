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
    
    var inputInviteParams: [AnyHashable: Any]?

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

        let messageSize = self.message.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))        
        self.message.anchorTopCenter(withTopPadding: 0, width: 288, height: messageSize.height)
        self.emailField.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 288, height: 48)

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
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    override func initialize() {
        super.initialize()

        if self.flow == .onboardLogin {
            self.message.text = "Welcome back."
        }
        else {
            self.message.text = "Patchr groups are perfect for control freaks."
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
        
        self.contentHolder.addSubview(self.message)
        self.contentHolder.addSubview(self.emailField)
        
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
                    self.emailField.errorMessage = "No account found."
                }
                else {
                    let controller = PasswordViewController()
                    controller.flow = self.flow
                    controller.branch = .login
                    controller.inputEmail = email
                    self.navigationController?.pushViewController(controller, animated: true)
                }
            }
            else if self.flow == .onboardInvite {
                let controller = PasswordViewController()
                controller.flow = self.flow
                controller.branch = .login
                controller.inputEmail = email
                controller.inputInviteParams = self.inputInviteParams
                self.navigationController?.pushViewController(controller, animated: true)
            }
            else if self.flow == .onboardCreate {
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
