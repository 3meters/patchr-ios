//
//  SignInViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class LoginViewController: BaseViewController {

    var processing: Bool = false
	var provider = AuthProvider.PROXIBASE
	var onboardMode = OnboardMode.Login

    var emailField				= AirTextField()
    var passwordField			= AirTextField()
	var facebookButton			= AirButton()
	var forgotPasswordButton	= AirButtonLink()
	var doneButton				= AirButtonFeatured()
	var googleButton			= AirButton()
	var comment					= AirLabel()
	var message					= AirLabelTitle()
	var separatorGroup			= UIView()
	var separatorRule			= UIView()
	var separatorLabel			= AirLabel()

	var inputRouteToMain: Bool = true

	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		super.loadView()
		initialize()
	}
	
	/*--------------------------------------------------------------------------------------------
	* Events
	*--------------------------------------------------------------------------------------------*/
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()

		let messageSize = self.message.sizeThatFits(CGSizeMake(288, CGFloat.max))
		self.message.anchorTopCenterWithTopPadding(80, width: 288, height: messageSize.height)
		self.emailField.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 288, height: 48)
		self.passwordField.alignUnder(self.emailField, matchingCenterWithTopPadding: 8, width: 288, height: 48)

		
		if THIRD_PARTY_AUTH_ENABLED {
			if onboardMode == OnboardMode.Signup {
				self.facebookButton.alignUnder(self.passwordField, matchingCenterWithTopPadding: 24, width: 288, height: 48)
				self.googleButton.alignUnder(self.facebookButton, matchingCenterWithTopPadding: 8, width: 288, height: 48)
				self.comment.alignUnder(self.googleButton, matchingCenterWithTopPadding: 8, width: 288, height: 48)
			}
			else {
				self.forgotPasswordButton.alignUnder(self.passwordField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
				self.doneButton.alignUnder(self.forgotPasswordButton, matchingCenterWithTopPadding: 8, width: 288, height: 48)
				self.facebookButton.alignUnder(self.doneButton, matchingCenterWithTopPadding: 8, width: 288, height: 48)
				self.googleButton.alignUnder(self.facebookButton, matchingCenterWithTopPadding: 8, width: 288, height: 48)
				self.comment.alignUnder(self.googleButton, matchingCenterWithTopPadding: 8, width: 288, height: 48)
			}
		}
		else {
			if onboardMode != OnboardMode.Signup {
				self.forgotPasswordButton.alignUnder(self.passwordField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
				self.doneButton.alignUnder(self.forgotPasswordButton, matchingCenterWithTopPadding: 8, width: 288, height: 48)
			}
		}
	}
	
    func doneAction(sender: AnyObject) {
		if isValid() {
			if self.onboardMode == OnboardMode.Signup {
				let controller = ProfileEditViewController()
				controller.inputProvider = self.provider
				controller.inputState = State.Onboarding
				controller.inputEmail = self.emailField.text
				controller.inputPassword = self.passwordField.text
				controller.inputRouteToMain = self.inputRouteToMain
				self.navigationController?.pushViewController(controller, animated: true)
			}
			else {
				loginProxibase()
			}
		}
    }
    
	func passwordResetAction(sender: AnyObject) {
		let controller = PasswordResetViewController()
		self.navigationController?.pushViewController(controller, animated: true)
	}

	func facebookAction(sender: AnyObject) {
		
		let provider = FacebookProvider()
		
		if FBSDKAccessToken.currentAccessToken() == nil
			|| !FBSDKAccessToken.currentAccessToken().hasGranted("email") {
				
			provider.authorize { response, error in
				if let response = response as? FBSDKLoginManagerLoginResult where error == nil {
					if !response.isCancelled {
						
						if !FBSDKAccessToken.currentAccessToken().hasGranted("email") {
							self.Alert("Email is required to connect with Facebook")
						}
						else {
							if self.onboardMode == OnboardMode.Signup {
								provider.profile { response, error in
									if let profile = response as? ServiceUserProfile where error == nil {										
										self.showProfile(profile)
									}
								}
							}
							else {
								self.navigateToMain()
							}
						}
					}
				}
			}
		}
		else {
			if self.onboardMode == OnboardMode.Signup {
				provider.profile { response, error in
					if let profile = response as? ServiceUserProfile where error == nil {
						self.showProfile(profile)
					}
				}
			}
			else {
				self.navigateToMain()
			}
		}
	}
	
	func googleAction(sender: AnyObject) {
		navigateToMain()
	}

	func cancelAction(sender: AnyObject){
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
			self.message.text = "Sign up for a free account to post messages, create patches, and more!"
		}
		else {
			self.message.text = "Welcome back!"
		}
		
		self.message.textColor = Theme.colorTextTitle
		self.message.numberOfLines = 0
		self.message.textAlignment = .Center
		self.view.addSubview(self.message)
		
		self.emailField.placeholder = "Email"
		self.emailField.delegate = self
		self.emailField.keyboardType = UIKeyboardType.EmailAddress
		self.emailField.autocapitalizationType = .None
		self.emailField.autocorrectionType = .No
		self.emailField.returnKeyType = UIReturnKeyType.Next
		self.view.addSubview(self.emailField)
		
		self.passwordField.placeholder = "Password (6 characters or more)"
		self.passwordField.delegate = self
		self.passwordField.secureTextEntry = true
		self.passwordField.autocapitalizationType = .None
		self.passwordField.keyboardType = UIKeyboardType.Default
		self.passwordField.returnKeyType = (onboardMode == OnboardMode.Signup) ? UIReturnKeyType.Next : UIReturnKeyType.Done
		self.view.addSubview(self.passwordField)
		
		self.forgotPasswordButton.setTitle("Forgot password?", forState: .Normal)
		self.view.addSubview(self.forgotPasswordButton)
		
		self.doneButton.setTitle("LOG IN", forState: .Normal)
		self.view.addSubview(self.doneButton)
		
		if THIRD_PARTY_AUTH_ENABLED {
			
			self.facebookButton.setTitle("LOG IN WITH FACEBOOK", forState: .Normal)
			self.view.addSubview(self.facebookButton)
			
			self.googleButton.setTitle("LOG IN WITH GOOGLE", forState: .Normal)
			self.view.addSubview(self.googleButton)
			
			self.facebookButton.addTarget(self, action: Selector("facebookAction:"), forControlEvents: .TouchUpInside)
			self.googleButton.addTarget(self, action: Selector("googleAction:"), forControlEvents: .TouchUpInside)
			
			if onboardMode == OnboardMode.Signup {
				self.facebookButton.setTitle("CONTINUE WITH FACEBOOK", forState: .Normal)
				self.googleButton.setTitle("CONTINUE WITH GOOGLE", forState: .Normal)
			}
			
			self.comment.text = "Don't worry, we won't post without your permission."
			self.comment.textColor = Theme.colorTextSecondary
			self.comment.numberOfLines = 2
			self.comment.textAlignment = NSTextAlignment.Center
			self.view.addSubview(self.comment)
		}
		
		self.forgotPasswordButton.addTarget(self, action: Selector("passwordResetAction:"), forControlEvents: .TouchUpInside)
		self.doneButton.addTarget(self, action: Selector("doneAction:"), forControlEvents: .TouchUpInside)
		
		setScreenName(onboardMode == OnboardMode.Signup ? "Signup" : "Login")
		
		/* Navigation bar buttons */
		let doneButton   = UIBarButtonItem(title: "Log in", style: UIBarButtonItemStyle.Plain, target: self, action: "doneAction:")
		let cancelButton   = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: "cancelAction:")
		self.navigationItem.rightBarButtonItems = [doneButton]
		self.navigationItem.leftBarButtonItems = [cancelButton]

		if onboardMode == OnboardMode.Signup {
			self.navigationItem.rightBarButtonItem?.title = "Next"
			self.forgotPasswordButton.hidden = true
			self.doneButton.hidden = true
		}
		else {
			self.emailField.text = NSUserDefaults.standardUserDefaults().objectForKey(PatchrUserDefaultKey("userEmail")) as? String
		}
	}
	
	func showProfile(profile: ServiceUserProfile?) {
		
		let controller = ProfileEditViewController()
		if profile != nil {
			controller.inputRouteToMain = self.inputRouteToMain
			controller.inputState = .Onboarding
			controller.inputProvider = self.provider
			controller.inputName = profile?.name
			controller.inputEmail = profile?.email
			controller.inputUserId = profile?.userId
			controller.inputPhotoUrl = profile?.photoUrl
		}
		self.navigationController?.pushViewController(controller, animated: true)
	}
	
	func loginProxibase() {
		if processing { return }
		
		if self.provider == AuthProvider.PROXIBASE && !isValid() { return }
		
		processing = true
		
		self.passwordField.resignFirstResponder()
		
		let progress = AirProgress.showHUDAddedTo(self.view.window, animated: true)
		progress.mode = MBProgressHUDMode.Indeterminate
		progress.styleAs(.ActivityWithText)
		progress.minShowTime = 0.5
		progress.labelText = "Logging in..."
		progress.removeFromSuperViewOnHide = true
		progress.show(true)
		
		DataController.proxibase.login(self.emailField.text!, password: self.passwordField.text!, provider: self.provider, token: nil) {
			response, error in
			
			NSOperationQueue.mainQueue().addOperationWithBlock {
				self.processing = false
				
				progress?.hide(true)
				if var error = ServerError(error) {
					if error.code == .UNAUTHORIZED_CREDENTIALS {
						error.message = "Wrong email and password combination."
						self.handleError(error, errorActionType: .ALERT)
					}
					else {
						self.handleError(error)
					}
				}
				else {
					
					/* Remember last email address for easy data entry */
					if self.provider == AuthProvider.PROXIBASE {
						NSUserDefaults.standardUserDefaults().setObject(self.emailField.text, forKey: PatchrUserDefaultKey("userEmail"))
						NSUserDefaults.standardUserDefaults().synchronize()
						self.passwordField.text = nil
					}
					/*
					* Register this install with the service particularly to capture the
					* current user so location updates work properly. If install registration
					* fails the device will not accurately track notifications.
					*/
					DataController.proxibase.registerInstallStandard {
						response, error in
						
						NSOperationQueue.mainQueue().addOperationWithBlock {
							if let error = ServerError(error) {
								Log.w("Error during registerInstall: \(error)")
							}
							
							/* Navigate to main interface */
							if self.inputRouteToMain {
								self.navigateToMain()
							}
							else {
								if self.isModal {
									self.dismissViewControllerAnimated(true, completion: nil)
								}
								else {
									self.navigationController?.popViewControllerAnimated(true)
								}
								if UserController.instance.userName != nil {
									Shared.Toast("Logged in as \(UserController.instance.userName!)")
								}
							}
						}
					}
				}
			}
		}
	}
	
	func navigateToMain() {
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		let controller = MainTabBarController()
		controller.selectedIndex = 0
		appDelegate.window!.setRootViewController(controller, animated: true)
		
		if UserController.instance.userName != nil {
			Shared.Toast("Logged in as \(UserController.instance.userName!)", controller: controller, addToWindow: false)
		}
	}
	
    func isValid() -> Bool {
		
        if emailField.isEmpty {
            Alert("Enter an email address.")
            return false
        }
        
        if (passwordField.text!.utf16.count < 6) {
            Alert("Enter a password with six characters or more.")
            return false
        }
        
        return true
    }
}

extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        if textField == self.emailField {
            self.passwordField.becomeFirstResponder()
            return false
        } else if textField == self.passwordField {
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
