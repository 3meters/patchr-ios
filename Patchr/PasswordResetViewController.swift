//
//  SignInViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MBProgressHUD

class PasswordResetViewController: BaseEditViewController {

    var processing			: Bool = false
    var emailValidated		: Bool = false
    var resetRequested		: Bool = false
    var progress			: AirProgress!
    var userId				: String?
    var sessionKey			: String?

    var inputToken			: String?
    var inputUserName		: String?
    var inputUserPhoto		: String?
    var resetActive			: Bool = false

    var message         = AirLabelTitle()
    var submitButton    = AirButton()
    var emailField      = AirTextField()

    var userName        = AirLabel()
    var userPhoto       = UserPhotoView()
    var passwordField   = AirTextField()
    var hideShowButton  = AirHideShowButton()

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

        if !self.resetActive {
            self.emailField.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 288, height: 48)
            self.submitButton.alignUnder(self.emailField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        }
        else {
            self.userPhoto.alignUnder(self.message, matchingCenterWithTopPadding: 16, width: 72, height: 72)
            self.userName.alignUnder(self.userPhoto, matchingCenterWithTopPadding: 0, width: 288, height: 48)
            self.passwordField.alignUnder(self.userName, matchingCenterWithTopPadding: 8, width: 288, height: 48)
            self.submitButton.alignUnder(self.passwordField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        }

        self.contentHolder.resizeToFitSubviews()
        self.scrollView.contentSize = CGSizeMake(self.contentHolder.frame.size.width, self.contentHolder.frame.size.height + CGFloat(32))
        self.contentHolder.anchorTopCenterFillingWidthWithLeftAndRightPadding(16, topPadding: 16, height: self.contentHolder.frame.size.height)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        bind();
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if self.emailField.isEmpty {
            self.emailField.becomeFirstResponder()
        }
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    func submitAction(sender: AnyObject) {
        if processing { return }
        if isValid() {
            if !self.resetActive {
                if !self.emailValidated {
                    validateEmail()
                }
                else if !self.resetRequested {
                    resetEmail()
                }
                else {
                    cancelAction(nil)
                }
            }
            else {
                resetPassword()
            }
        }
    }

    func hideShowPasswordAction(sender: AnyObject?) {
        if let button = sender as? AirHideShowButton {
            button.toggleOn(!button.toggledOn)
            self.passwordField.secureTextEntry = !button.toggledOn
        }
    }

    func cancelAction(sender: AnyObject?){
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

        if self.inputToken != nil {
            self.resetActive = true
        }

        Reporting.screen("PasswordReset")
        self.view.accessibilityIdentifier = View.PasswordReset

        self.message.text = "Find your account"
        self.message.numberOfLines = 3
        self.message.textAlignment = .Center
        self.contentHolder.addSubview(self.message)

        self.submitButton.setTitle("RESET", forState: .Normal)
        self.submitButton.accessibilityIdentifier = Button.Submit
        self.contentHolder.addSubview(self.submitButton)
        self.submitButton.addTarget(self, action: #selector(PasswordResetViewController.submitAction(_:)), forControlEvents: .TouchUpInside)

        if !self.resetActive {

            self.message.text = "Enter the email address associated with your account."

            self.emailField.placeholder = "Email"
            self.emailField.accessibilityIdentifier = Field.ResetEmail
            self.emailField.delegate = self
            self.emailField.autocapitalizationType = .None
            self.emailField.autocorrectionType = .No
            self.emailField.keyboardType = UIKeyboardType.EmailAddress
            self.emailField.returnKeyType = UIReturnKeyType.Next
            self.emailField.text = NSUserDefaults.standardUserDefaults().objectForKey(PatchrUserDefaultKey("userEmail")) as? String
            self.contentHolder.addSubview(self.emailField)

            self.submitButton.setTitle("VERIFY", forState: .Normal)
        }
        else {

            self.message.text = "Welcome back! Enter your new password"

            self.contentHolder.addSubview(self.userPhoto)

            self.userName.textAlignment = .Center
            self.contentHolder.addSubview(self.userName)

            self.passwordField.placeholder = "New password"
            self.passwordField.accessibilityIdentifier = Field.ResetPassword
            self.passwordField.delegate = self
            self.passwordField.secureTextEntry = true
            self.passwordField.keyboardType = UIKeyboardType.Default
            self.passwordField.returnKeyType = UIReturnKeyType.Done
            self.passwordField.rightView = self.hideShowButton
            self.passwordField.rightViewMode = .Always
            self.contentHolder.addSubview(self.passwordField)

            self.hideShowButton.bounds.size = CGSizeMake(48, 48)
            self.hideShowButton.imageEdgeInsets = UIEdgeInsetsMake(8, 10, 8, 10)
            self.hideShowButton.addTarget(self, action: #selector(PasswordResetViewController.hideShowPasswordAction(_:)), forControlEvents: .TouchUpInside)

            self.submitButton.setTitle("RESET", forState: .Normal)
        }
    }

    func bind() {
        if self.resetActive {
            if self.inputUserPhoto != nil {
                let photoUrl = PhotoUtils.url(self.inputUserPhoto!, source: PhotoSource.aircandi_images, category: SizeCategory.profile)
                self.userPhoto.bindPhoto(photoUrl, name: nil)
            }
            else if self.inputUserName != nil {
                self.userPhoto.bindPhoto(nil, name: self.inputUserName)
            }
            self.userName.text = self.inputUserName
        }
    }

    func validateEmail() {

        guard !self.processing else {
            return
        }

        processing = true

        self.emailField.resignFirstResponder()

        self.progress = AirProgress.showHUDAddedTo(self.view.window!, animated: true)
        self.progress.mode = MBProgressHUDMode.Indeterminate
        self.progress.styleAs(.ActivityWithText)
        self.progress.minShowTime = 0.5
        self.progress.labelText = "Verifying..."
        self.progress.removeFromSuperViewOnHide = true
        self.progress.show(true)

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
                        if serviceData.count != 0 {
                            self.message.text = "Email verified!"
                            self.submitButton.setTitle("SEND PASSWORD RESET EMAIL", forState: .Normal)
                            self.emailField.textAlignment = NSTextAlignment.Center
                            self.emailField.enabled = false;
                            self.emailValidated = true
                            Animation.bounce(self.message)
                        }
                        else {
                            self.Alert("Email address not found.")
                        }
                    }
                }
            }
        }
    }

    func resetEmail() {

        guard !self.processing else {
            return
        }

        self.processing = true

        let progress = AirProgress.addedTo(self.view.window!)
        progress.mode = MBProgressHUDMode.Indeterminate
        progress.styleAs(.ActivityWithText)
        progress.labelText = "Sending email..."
        progress.minShowTime = 1.0
        progress.show(true)
        progress.userInteractionEnabled = true

        DataController.proxibase.requestPasswordReset(self.emailField.text!) {
            response, error in

            NSOperationQueue.mainQueue().addOperationWithBlock {
                self.processing = false

                progress.hide(true)

                if let error = ServerError(error) {
                    self.handleError(error)
                }
                else {
                    self.resetRequested = true
                    self.message.numberOfLines = 0
                    self.message.text = "An email has been sent to your account\'s email address. Please check your email to continue."
                    self.view.setNeedsLayout()
                    self.submitButton.setTitle("FINISHED", forState: .Normal)
                    Animation.bounce(self.message)
                }
            }
        }
    }

    func resetPassword() {

        guard !self.processing else {
            return
        }

        processing = true

        self.passwordField.resignFirstResponder()

        let progress = AirProgress.addedTo(self.view.window!)
        progress.mode = MBProgressHUDMode.Indeterminate
        progress.styleAs(.ActivityWithText)
        progress.labelText = "Resetting..."
        progress.minShowTime = 1.0
        progress.show(true)
        progress.userInteractionEnabled = true

        DataController.proxibase.resetPassword(self.passwordField.text!, token: self.inputToken!) {
            response, error in

            NSOperationQueue.mainQueue().addOperationWithBlock {
                self.processing = false

                progress.hide(true)
                if let error = ServerError(error) {
                    if error.code == .UNAUTHORIZED_CREDENTIALS {
                        self.Alert("Password reset has expired or is invalid. Request password reset again.", onDismiss: {
                            self.cancelAction(nil)
                        })
                    }
                    else {
                        self.handleError(error)	// Could log user out if looks like credential problem.
                    }
                }
                else {
                    Reporting.track("Reset Password and Logged In")
                    self.navigateToMain()
                }
            }
        }
    }

    func isValid() -> Bool {

        if !self.resetActive {
            if emailField.isEmpty {
                Alert("Enter the email address associated with your account.")
                return false
            }

            if !emailField.text!.isEmail() {
                Alert("Enter a valid email address.")
                return false
            }
        }
        else {
            if (passwordField.text!.utf16.count < 6) {
                Alert("Enter a new password with six characters or more.")
                return false
            }
        }

        return true
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


    override func textFieldShouldReturn(textField: UITextField) -> Bool {

        if textField == self.emailField {
            self.passwordField.becomeFirstResponder()
            return false
        }
        else if textField == self.passwordField {
            self.submitAction(textField)
            self.view.endEditing(true)
            return false
        }

        return true
    }
}