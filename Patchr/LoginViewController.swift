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

        let messageSize = self.message.sizeThatFits(CGSizeMake(288, CGFloat.max))
        self.message.anchorTopCenterWithTopPadding(0, width: 288, height: messageSize.height)
        self.emailField.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        self.passwordField.alignUnder(self.emailField, matchingCenterWithTopPadding: 8, width: 288, height: 48)

        if onboardMode != OnboardMode.Signup {
            self.forgotPasswordButton.alignUnder(self.passwordField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
            self.doneButton.alignUnder(self.forgotPasswordButton, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        }

        self.contentHolder.resizeToFitSubviews()
        self.scrollView.contentSize = CGSizeMake(self.contentHolder.frame.size.width, self.contentHolder.frame.size.height + CGFloat(32))
        self.contentHolder.anchorTopCenterFillingWidthWithLeftAndRightPadding(16, topPadding: 16, height: self.contentHolder.frame.size.height)
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    func doneAction(sender: AnyObject) {
        if isValid() {
            if self.onboardMode == OnboardMode.Signup {
                self.passwordField.resignFirstResponder()

                self.progress = AirProgress.showHUDAddedTo(self.view.window!, animated: true)
                self.progress.mode = MBProgressHUDMode.Indeterminate
                self.progress.styleAs(.ActivityWithText)
                self.progress.minShowTime = 0.5
                self.progress.labelText = "Verifying..."
                self.progress.removeFromSuperViewOnHide = true
                self.progress.show(true)

                validateEmail()
            }
            else {
                self.passwordField.resignFirstResponder()

                self.progress = AirProgress.showHUDAddedTo(self.view.window!, animated: true)
                self.progress.mode = MBProgressHUDMode.Indeterminate
                self.progress.styleAs(.ActivityWithText)
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
            button.toggleOn(!button.toggledOn)
            self.passwordField.secureTextEntry = !button.toggledOn
        }
    }

    func passwordResetAction(sender: AnyObject) {
        if emailField.isEmpty {
            Alert("Enter an email address.")
            return
        }
        
        if !emailField.text!.isEmail() {
            Alert("Enter a valid email address.")
            return
        }
        
        FIRAuth.auth()?.sendPasswordResetWithEmail(emailField.text!) { error in
            if error == nil {
                self.Alert("A password reset email has been sent to your email address.")
            }
        }
    }

    func cancelAction(sender: AnyObject) {
        if self.isModal {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        else {
            self.navigationController?.popViewControllerAnimated(true)
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
        self.message.textAlignment = .Center
        self.contentHolder.addSubview(self.message)

        self.emailField.placeholder = "Email"
        self.emailField.accessibilityIdentifier = Field.Email
        self.emailField.delegate = self
        self.emailField.keyboardType = UIKeyboardType.EmailAddress
        self.emailField.autocapitalizationType = .None
        self.emailField.autocorrectionType = .No
        self.emailField.returnKeyType = UIReturnKeyType.Next
        self.contentHolder.addSubview(self.emailField)

        self.passwordField.placeholder = "Password (6+ characters)"
        self.passwordField.accessibilityIdentifier = Field.Password
        self.passwordField.delegate = self
        self.passwordField.secureTextEntry = true
        self.passwordField.autocapitalizationType = .None
        self.passwordField.keyboardType = UIKeyboardType.Default
        self.passwordField.returnKeyType = (onboardMode == OnboardMode.Signup) ? UIReturnKeyType.Next : UIReturnKeyType.Done
        self.passwordField.rightView = self.hideShowButton
        self.passwordField.rightViewMode = .Always
        self.contentHolder.addSubview(self.passwordField)

        self.hideShowButton.bounds.size = CGSizeMake(48, 48)
        self.hideShowButton.imageEdgeInsets = UIEdgeInsetsMake(8, 10, 8, 10)
        self.hideShowButton.addTarget(self, action: #selector(LoginViewController.hideShowPasswordAction(_:)), forControlEvents: .TouchUpInside)

        self.forgotPasswordButton.setTitle("Forgot password?", forState: .Normal)
        self.forgotPasswordButton.accessibilityIdentifier = Button.ForgotPassword
        self.contentHolder.addSubview(self.forgotPasswordButton)

        self.doneButton.setTitle("LOG IN", forState: .Normal)
        self.doneButton.accessibilityIdentifier = Button.Submit
        self.contentHolder.addSubview(self.doneButton)

        self.forgotPasswordButton.addTarget(self, action: #selector(LoginViewController.passwordResetAction(_:)), forControlEvents: .TouchUpInside)
        self.doneButton.addTarget(self, action: #selector(LoginViewController.doneAction(_:)), forControlEvents: .TouchUpInside)

        Reporting.screen(onboardMode == OnboardMode.Signup ? "Signup" : "Login")

        /* Navigation bar buttons */
        let doneButton = UIBarButtonItem(title: "Log in", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(LoginViewController.doneAction(_:)))
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(LoginViewController.cancelAction(_:)))

        cancelButton.accessibilityIdentifier = Nav.Cancel
        doneButton.accessibilityIdentifier = Nav.Submit

        self.navigationItem.rightBarButtonItems = [doneButton]
        self.navigationItem.leftBarButtonItems = [cancelButton]

        if onboardMode == OnboardMode.Signup {
            self.view.accessibilityIdentifier = View.SignupLogin
            self.navigationItem.rightBarButtonItem?.title = "Next"
            self.forgotPasswordButton.hidden = true
            self.doneButton.hidden = true
        }
        else {
            self.view.accessibilityIdentifier = View.Login
            self.emailField.text = NSUserDefaults.standardUserDefaults().objectForKey(PatchrUserDefaultKey("userEmail")) as? String
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
        DataController.proxibase.validEmail(self.emailField.text!) {
            response, error in

            NSOperationQueue.mainQueue().addOperationWithBlock {
                self.processing = false

                self.progress?.hide(true)

                if let error = ServerError(error) {
                    self.handleError(error)
                }
                else {
                    if let serviceData = DataController.instance.dataWrapperForResponse(response!) {
                        if serviceData.count == 0 {
                            self.didValidate()
                        }
                        else {
                            self.Alert("Email has already been used.")
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
        
        FIRAuth.auth()?.signInWithEmail(self.emailField.text!, password: self.passwordField.text!) { (user, error) in
            self.processing = false
            self.progress?.hide(true)
            if error != nil {
                if error!.code == FIRAuthErrorCode.ErrorCodeEmailAlreadyInUse.rawValue {
                    self.Alert("Email already used")
                }
                else if error!.code == FIRAuthErrorCode.ErrorCodeInvalidEmail.rawValue {
                    self.Alert("Email address is not valid")
                }
                else if error!.code == FIRAuthErrorCode.ErrorCodeWrongPassword.rawValue {
                    self.Alert("Wrong email and password combination")
                }
            }
            else {
                Reporting.track("Logged In", properties: ["source": self.source])
                self.didLogin()
            }
        }
    }

    func didLogin() {
        /* Navigate to main interface */
        if self.inputRouteToMain {
            self.navigateToMain()    // Replaces any current navigation stack
        }
        else {
            if self.isModal {
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            else {
                self.navigationController?.popViewControllerAnimated(true)
            }
            if UserController.instance.userName != nil {
                UIShared.Toast("Logged in as \(UserController.instance.userName!)")
            }
        }
    }

    func didValidate() {
        /* Navigate to next page */
        let controller = ProfileEditViewController()
        controller.inputProvider = self.provider
        controller.inputState = State.Onboarding
        controller.inputEmail = self.emailField.text
        controller.inputPassword = self.passwordField.text
        controller.inputRouteToMain = self.inputRouteToMain
        controller.source = self.source
        self.navigationController?.pushViewController(controller, animated: true)
    }

    func navigateToMain() {

        if CLLocationManager.authorizationStatus() == .NotDetermined
                || !UIApplication.sharedApplication().isRegisteredForRemoteNotifications() {
            let controller = PermissionsViewController()
            self.navigationController?.pushViewController(controller, animated: true)
            if UserController.instance.userName != nil {
                UIShared.Toast("Logged in as \(UserController.instance.userName!)", controller: controller, addToWindow: false)
            }
        }
        else {
            AppDelegate.appDelegate().routeForRoot()
            if UserController.instance.userName != nil {
                UIShared.Toast("Logged in as \(UserController.instance.userName!)")
            }
        }
    }

    func isValid() -> Bool {

        if emailField.isEmpty {
            Alert("Enter an email address.")
            return false
        }

        if !emailField.text!.isEmail() {
            Alert("Enter a valid email address.")
            return false
        }

        if (passwordField.text!.utf16.count < 6) {
            Alert("Enter a password with six characters or more.")
            return false
        }

        return true
    }

    override func textFieldShouldReturn(textField: UITextField) -> Bool {

        if textField == self.emailField {
            self.passwordField.becomeFirstResponder()
            return false
        }
        else if textField == self.passwordField {
            self.doneAction(textField)
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
