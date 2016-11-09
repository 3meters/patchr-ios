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

class LoginViewController: BaseEditViewController {

    var processing: Bool = false
    var provider = AuthProvider.PROXIBASE
    var onboardMode = OnboardMode.Login
    var progress: AirProgress!
    var source = "Lobby"

    var emailField = AirTextField()
    var passwordField = AirTextField()
    var hideShowButton = AirHideShowButton()
    var forgotPasswordButton = AirLinkButton()
    var doneButton = AirFeaturedButton()
    var message = AirLabelTitle()

    var inputRouteToMain: Bool = true

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func loadView() {
        super.loadView()
        initialize()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let messageSize = self.message.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        self.message.anchorTopCenter(withTopPadding: 0, width: 288, height: messageSize.height)
        self.emailField.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        self.passwordField.alignUnder(self.emailField, matchingCenterWithTopPadding: 8, width: 288, height: 48)

        if onboardMode != OnboardMode.Signup {
            self.forgotPasswordButton.alignUnder(self.passwordField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
            self.doneButton.alignUnder(self.forgotPasswordButton, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        }

        self.contentHolder.resizeToFitSubviews()
        self.scrollView.contentSize = CGSize(width:self.contentHolder.frame.size.width, height:self.contentHolder.frame.size.height + CGFloat(32))
        self.contentHolder.anchorTopCenterFillingWidth(withLeftAndRightPadding: 16, topPadding: 16, height: self.contentHolder.frame.size.height)
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    func doneAction(sender: AnyObject) {
        if isValid() {
            if self.onboardMode == OnboardMode.Signup {
                self.passwordField.resignFirstResponder()

                self.progress = AirProgress.showAdded(to: self.view.window!, animated: true)
                self.progress.mode = MBProgressHUDMode.indeterminate
                self.progress.styleAs(progressStyle: .ActivityWithText)
                self.progress.minShowTime = 0.5
                self.progress.labelText = "Verifying..."
                self.progress.removeFromSuperViewOnHide = true
                self.progress.show(true)

                validateEmail()
            }
            else {
                self.passwordField.resignFirstResponder()

                self.progress = AirProgress.showAdded(to: self.view.window!, animated: true)
                self.progress.mode = MBProgressHUDMode.indeterminate
                self.progress.styleAs(progressStyle: .ActivityWithText)
                self.progress.minShowTime = 0.5
                self.progress.labelText = "Logging in..."
                self.progress.removeFromSuperViewOnHide = true
                self.progress.show(true)

                login()
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
        if emailField.isEmpty {
            Alert(title: "Enter an email address.")
            return
        }
        
        if !emailField.text!.isEmail() {
            Alert(title: "Enter a valid email address.")
            return
        }
        
        FIRAuth.auth()?.sendPasswordReset(withEmail: emailField.text!) { error in
            if error == nil {
                self.Alert(title: "A password reset email has been sent to your email address.")
            }
        }
    }

    func cancelAction(sender: AnyObject) {
        if self.isModal {
            self.dismiss(animated: true, completion: nil)
        }
        else {
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    override func initialize() {
        super.initialize()

        if self.onboardMode == .Signup {
            self.message.text = "Sign up for a free account to post messages, create patches, and more."
        }
        else {
            self.message.text = "Welcome back."
        }

        self.message.textColor = Theme.colorTextTitle
        self.message.numberOfLines = 0
        self.message.textAlignment = .center
        self.contentHolder.addSubview(self.message)

        self.emailField.placeholder = "Email"
        self.emailField.delegate = self
        self.emailField.keyboardType = UIKeyboardType.emailAddress
        self.emailField.autocapitalizationType = .none
        self.emailField.autocorrectionType = .no
        self.emailField.returnKeyType = UIReturnKeyType.next
        self.contentHolder.addSubview(self.emailField)

        self.passwordField.placeholder = "Password (6+ characters)"
        self.passwordField.delegate = self
        self.passwordField.isSecureTextEntry = true
        self.passwordField.autocapitalizationType = .none
        self.passwordField.keyboardType = UIKeyboardType.default
        self.passwordField.returnKeyType = (onboardMode == OnboardMode.Signup) ? UIReturnKeyType.next : UIReturnKeyType.done
        self.passwordField.rightView = self.hideShowButton
        self.passwordField.rightViewMode = .always
        self.contentHolder.addSubview(self.passwordField)

        self.hideShowButton.bounds.size = CGSize(width:48, height:48)
        self.hideShowButton.imageEdgeInsets = UIEdgeInsetsMake(8, 10, 8, 10)
        self.hideShowButton.addTarget(self, action: #selector(LoginViewController.hideShowPasswordAction(sender:)), for: .touchUpInside)

        self.forgotPasswordButton.setTitle("Forgot password?", for: .normal)
        self.contentHolder.addSubview(self.forgotPasswordButton)

        self.doneButton.setTitle("LOG IN", for: .normal)
        self.contentHolder.addSubview(self.doneButton)

        self.forgotPasswordButton.addTarget(self, action: #selector(LoginViewController.passwordResetAction(sender:)), for: .touchUpInside)
        self.doneButton.addTarget(self, action: #selector(LoginViewController.doneAction(sender:)), for: .touchUpInside)

        Reporting.screen(onboardMode == OnboardMode.Signup ? "Signup" : "Login")

        /* Navigation bar buttons */
        let doneButton = UIBarButtonItem(title: "Log in", style: UIBarButtonItemStyle.plain, target: self, action: #selector(LoginViewController.doneAction(sender:)))
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(LoginViewController.cancelAction(sender:)))

        self.navigationItem.rightBarButtonItems = [doneButton]
        self.navigationItem.leftBarButtonItems = [cancelButton]

        if onboardMode == OnboardMode.Signup {
            self.navigationItem.rightBarButtonItem?.title = "Next"
            self.forgotPasswordButton.isHidden = true
            self.doneButton.isHidden = true
        }
        else {
            self.emailField.text = UserDefaults.standard.object(forKey: PatchrUserDefaultKey(subKey: "userEmail")) as? String
        }
    }

    func validateEmail() {

        guard !self.processing else {
            return
        }

        processing = true

        /*
        * Successful login will also update the install record so the authenticated user
        * is associated with the install. Logging out clears the associated user.
        */
        DataController.proxibase.validEmail(email: self.emailField.text!) {
            response, error in

            OperationQueue.main.addOperation {
                self.processing = false

                self.progress?.hide(true)

                if let error = ServerError(error) {
                    self.handleError(error)
                }
                else {
                    if let serviceData = DataController.instance.dataWrapperForResponse(response: response!) {
                        if serviceData.count == 0 {
                            self.didValidate()
                        }
                        else {
                            self.Alert(title: "Email has already been used.")
                        }
                    }
                }
            }
        }
    }

    func login() {

        guard !self.processing else {
            return
        }

        processing = true
        
        FIRAuth.auth()?.signIn(withEmail: self.emailField.text!, password: self.passwordField.text!) { (user, error) in
            self.processing = false
            self.progress?.hide(true)
            if error != nil {
                if error!._code == FIRAuthErrorCode.errorCodeEmailAlreadyInUse.rawValue {
                    self.Alert(title: "Email already used")
                }
                else if error!._code == FIRAuthErrorCode.errorCodeInvalidEmail.rawValue {
                    self.Alert(title: "Email address is not valid")
                }
                else if error!._code == FIRAuthErrorCode.errorCodeWrongPassword.rawValue {
                    self.Alert(title: "Wrong email and password combination")
                }
            }
            else {
                Reporting.track("Logged In", properties: ["source": self.source as AnyObject])
                UserController.instance.setUserId(userId: user?.uid)
                self.didLogin()
            }
        }
    }

    func didLogin() {
        /* Navigate to main interface */
        MainController.instance.route()
        if self.isModal {
            self.dismiss(animated: true, completion: nil)
        }
        else {
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }

    func didValidate() {
        /* Navigate to next page */
        let controller = ZProfileEditViewController()
        controller.inputProvider = self.provider
        controller.inputState = State.Onboarding
        controller.inputEmail = self.emailField.text
        controller.inputPassword = self.passwordField.text
        controller.inputRouteToMain = self.inputRouteToMain
        controller.source = self.source
        self.navigationController?.pushViewController(controller, animated: true)
    }

    func navigateToMain() {

//        if CLLocationManager.authorizationStatus() == .notDetermined
//                || !UIApplication.shared.isRegisteredForRemoteNotifications {
//            let controller = PermissionsViewController()
//            self.navigationController?.pushViewController(controller, animated: true)
//            if UserController.instance.userName != nil {
//                UIShared.Toast(message: "Logged in as \(UserController.instance.userName!)", controller: controller, addToWindow: false)
//            }
//        }
//        else {
//        }
    }

    func isValid() -> Bool {

        if emailField.isEmpty {
            Alert(title: "Enter an email address.")
            return false
        }

        if !emailField.text!.isEmail() {
            Alert(title: "Enter a valid email address.")
            return false
        }

        if (passwordField.text!.utf16.count < 6) {
            Alert(title: "Enter a password with six characters or more.")
            return false
        }

        return true
    }

    override func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        if textField == self.emailField {
            self.passwordField.becomeFirstResponder()
            return false
        }
        else if textField == self.passwordField {
            self.doneAction(sender: textField)
            textField.resignFirstResponder()
            return false
        }

        return true
    }
}

enum OnboardMode: Int {
    case Login
    case Signup
    case None
}
