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

        let messageSize = self.message.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        self.message.anchorTopCenter(withTopPadding: 0, width: 288, height: messageSize.height)

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
        self.scrollView.contentSize = CGSize(width:self.contentHolder.frame.size.width, height:self.contentHolder.frame.size.height + CGFloat(32))
        self.contentHolder.anchorTopCenterFillingWidth(withLeftAndRightPadding: 16, topPadding: 16, height: self.contentHolder.frame.size.height)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bind();
    }

    override func viewDidAppear(_ animated: Bool) {
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
                    cancelAction(sender: nil)
                }
            }
            else {
                resetPassword()
            }
        }
    }

    func hideShowPasswordAction(sender: AnyObject?) {
        if let button = sender as? AirHideShowButton {
            button.toggleOn(on: !button.toggledOn)
            self.passwordField.isSecureTextEntry = !button.toggledOn
        }
    }

    func cancelAction(sender: AnyObject?){
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

        if self.inputToken != nil {
            self.resetActive = true
        }

        Reporting.screen("PasswordReset")

        self.message.text = "Find your account"
        self.message.numberOfLines = 3
        self.message.textAlignment = .center
        self.contentHolder.addSubview(self.message)

        self.submitButton.setTitle("RESET", for: .normal)
        self.contentHolder.addSubview(self.submitButton)
        self.submitButton.addTarget(self, action: #selector(PasswordResetViewController.submitAction(sender:)), for: .touchUpInside)

        if !self.resetActive {

            self.message.text = "Enter the email address associated with your account."

            self.emailField.placeholder = "Email"
            self.emailField.delegate = self
            self.emailField.autocapitalizationType = .none
            self.emailField.autocorrectionType = .no
            self.emailField.keyboardType = UIKeyboardType.emailAddress
            self.emailField.returnKeyType = UIReturnKeyType.next
            self.emailField.text = UserDefaults.standard.object(forKey: PatchrUserDefaultKey(subKey: "userEmail")) as? String
            self.contentHolder.addSubview(self.emailField)

            self.submitButton.setTitle("VERIFY", for: .normal)
        }
        else {

            self.message.text = "Welcome back! Enter your new password"

            self.contentHolder.addSubview(self.userPhoto)

            self.userName.textAlignment = .center
            self.contentHolder.addSubview(self.userName)

            self.passwordField.placeholder = "New password"
            self.passwordField.delegate = self
            self.passwordField.isSecureTextEntry = true
            self.passwordField.keyboardType = UIKeyboardType.default
            self.passwordField.returnKeyType = UIReturnKeyType.done
            self.passwordField.rightView = self.hideShowButton
            self.passwordField.rightViewMode = .always
            self.contentHolder.addSubview(self.passwordField)

            self.hideShowButton.bounds.size = CGSize(width:48, height:48)
            self.hideShowButton.imageEdgeInsets = UIEdgeInsets(top:8, left:10, bottom:8, right:10)
            self.hideShowButton.addTarget(self, action: #selector(PasswordResetViewController.hideShowPasswordAction(sender:)), for: .touchUpInside)

            self.submitButton.setTitle("RESET", for: .normal)
        }
    }

    func bind() {
        if self.resetActive {
            if self.inputUserPhoto != nil {
                let photoUrl = PhotoUtils.url(prefix: self.inputUserPhoto!, source: PhotoSource.aircandi_images, category: SizeCategory.profile)
                self.userPhoto.bindPhoto(photoUrl: photoUrl, name: nil)
            }
            else if self.inputUserName != nil {
                self.userPhoto.bindPhoto(photoUrl: nil, name: self.inputUserName)
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

        self.progress = AirProgress.showAdded(to: self.view.window!, animated: true)
        self.progress.mode = MBProgressHUDMode.indeterminate
        self.progress.styleAs(progressStyle: .ActivityWithText)
        self.progress.minShowTime = 0.5
        self.progress.labelText = "Verifying..."
        self.progress.removeFromSuperViewOnHide = true
        self.progress.show(true)

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
                        if serviceData.count != 0 {
                            self.message.text = "Email verified!"
                            self.submitButton.setTitle("SEND PASSWORD RESET EMAIL", for: .normal)
                            self.emailField.textAlignment = NSTextAlignment.center
                            self.emailField.isEnabled = false;
                            self.emailValidated = true
                            Animation.bounce(view: self.message)
                        }
                        else {
                            self.Alert(title: "Email address not found.")
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

        let progress = AirProgress.addedTo(view: self.view.window!)
        progress.mode = MBProgressHUDMode.indeterminate
        progress.styleAs(progressStyle: .ActivityWithText)
        progress.labelText = "Sending email..."
        progress.minShowTime = 1.0
        progress.show(true)
        progress.isUserInteractionEnabled = true

        DataController.proxibase.requestPasswordReset(email: self.emailField.text! as NSString) {
            response, error in

            OperationQueue.main.addOperation {
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
                    self.submitButton.setTitle("FINISHED", for: .normal)
                    Animation.bounce(view: self.message)
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

        let progress = AirProgress.addedTo(view: self.view.window!)
        progress.mode = MBProgressHUDMode.indeterminate
        progress.styleAs(progressStyle: .ActivityWithText)
        progress.labelText = "Resetting..."
        progress.minShowTime = 1.0
        progress.show(true)
        progress.isUserInteractionEnabled = true

        DataController.proxibase.resetPassword(password: self.passwordField.text! as NSString, token: self.inputToken! as NSString) {
            response, error in

            OperationQueue.main.addOperation {
                self.processing = false

                progress.hide(true)
                if let error = ServerError(error) {
                    if error.code == .UNAUTHORIZED_CREDENTIALS {
                        self.Alert(title: "Password reset has expired or is invalid. Request password reset again.", onDismiss: {
                            self.cancelAction(sender: nil)
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
                Alert(title: "Enter the email address associated with your account.")
                return false
            }

            if !emailField.text!.isEmail() {
                Alert(title: "Enter a valid email address.")
                return false
            }
        }
        else {
            if (passwordField.text!.utf16.count < 6) {
                Alert(title: "Enter a new password with six characters or more.")
                return false
            }
        }

        return true
    }

    func navigateToMain() {

        if CLLocationManager.authorizationStatus() == .notDetermined
            || !UIApplication.shared.isRegisteredForRemoteNotifications {
                let controller = PermissionsViewController()
                self.navigationController?.pushViewController(controller, animated: true)
                if UserController.instance.userName != nil {
                    UIShared.Toast(message: "Logged in as \(UserController.instance.userName!)", controller: controller, addToWindow: false)
                }
        }
        else {
            AppDelegate.appDelegate().routeForRoot()
            if UserController.instance.userName != nil {
                UIShared.Toast(message: "Logged in as \(UserController.instance.userName!)")
            }
        }
    }


    override func textFieldShouldReturn(textField: UITextField) -> Bool {

        if textField == self.emailField {
            self.passwordField.becomeFirstResponder()
            return false
        }
        else if textField == self.passwordField {
            self.submitAction(sender: textField)
            self.view.endEditing(true)
            return false
        }

        return true
    }
}
