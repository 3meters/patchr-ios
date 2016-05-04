//
//  RegistrationTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-24.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AWSS3
import Keys
import FBSDKCoreKit
import PBWebViewController
import MBProgressHUD

class ProfileEditViewController: BaseEditViewController {
	
	var processing: Bool = false
	var progressStartLabel: String?
	var progressFinishLabel: String?
	var cancelledLabel: String?
	
	var schema: String?
	
	var imageUploadRequest: AWSS3TransferManagerUploadRequest?
	var entityPostRequest: NSURLSessionTask?
	
	var inputRouteToMain: Bool = true
	var inputProvider: String? = AuthProvider.PROXIBASE
	var inputState: State? = State.Editing
	var inputUser: User?
	var inputName: String?
	var inputEmail: String?
	var inputPassword: String?
	var inputUserId: String?
	var inputPhotoUrl: NSURL?

	var photoView            = PhotoEditView()
	var nameField            = AirTextField()
	var emailField           = AirTextField()
	var areaField            = AirTextField()
	var changePasswordButton = AirButton()
	var joinButton           = AirFeaturedButton()
	var termsButton          = AirLinkButton()
	var comment				 = AirLabel()
	var message				 = AirLabelTitle()
	
	var facebookOnGroup		 = UIView()
	var facebookOffGroup	 = UIView()
	var facebookButton		 = AirButton()
	var facebookName		 = AirLabel()
	var facebookDisconnect	 = AirLinkButton()
	var facebookPhoto		 = AirImageView(frame: CGRectZero)
	var facebookActivity	 = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
	var provider			 : FacebookProvider!
	
	var progress			 : AirProgress?
	
	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
    
	override func loadView() {
		super.loadView()
		initialize()
		draw()
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		let messageSize = self.message.sizeThatFits(CGSizeMake(288, CGFloat.max))
		self.message.anchorTopCenterWithTopPadding(0, width: 288, height: messageSize.height)
		self.photoView.alignUnder(self.message, matchingCenterWithTopPadding: 16, width: 150, height: 150)
		self.nameField.alignUnder(self.photoView, matchingCenterWithTopPadding: 8, width: 288, height: 48)
		
		if self.inputState == State.Onboarding {
			self.emailField.alignUnder(self.nameField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
			self.joinButton.alignUnder(self.emailField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
			self.termsButton.alignUnder(self.joinButton, matchingCenterWithTopPadding: 8, width: 288, height: 48)
			self.facebookButton.alignUnder(self.termsButton, matchingLeftWithTopPadding: 24, width: 288, height: 48)
		}
		else {
			self.areaField.alignUnder(self.nameField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
			self.emailField.alignUnder(self.areaField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
			self.changePasswordButton.alignUnder(self.emailField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
			
			self.facebookPhoto.anchorTopCenterWithTopPadding(0, width: 72, height: 72)
			self.facebookName.alignUnder(self.facebookPhoto, matchingCenterWithTopPadding: 8, width: 288, height: 24)
			self.facebookDisconnect.alignUnder(self.facebookName, matchingCenterWithTopPadding: 0, width: 288, height: 24)
			self.facebookActivity.alignUnder(self.facebookName, matchingCenterWithTopPadding: 0, width: 288, height: 24)
			self.facebookOnGroup.alignUnder(self.changePasswordButton, matchingCenterWithTopPadding: 16, width: 288, height: 136)
			
			self.facebookButton.anchorTopCenterWithTopPadding(0, width: 288, height: 48)
			self.comment.alignUnder(self.facebookButton, matchingLeftWithTopPadding: 8, width: 288, height: 48)
			self.facebookOffGroup.alignUnder(self.changePasswordButton, matchingCenterWithTopPadding: 8, width: 288, height: 104)
		}
		
		self.contentHolder.resizeToFitSubviews()
		self.scrollView.contentSize = CGSizeMake(self.contentHolder.frame.size.width, self.contentHolder.frame.size.height + CGFloat(32))
		self.contentHolder.anchorTopCenterFillingWidthWithLeftAndRightPadding(16, topPadding: 24, height: self.contentHolder.frame.size.height)
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		let notificationCenter = NSNotificationCenter.defaultCenter()
		notificationCenter.addObserver(self, selector: #selector(ProfileEditViewController.providerConnectionChanged(_:)), name: FBSDKAccessTokenDidChangeNotification, object: nil)
		notificationCenter.addObserver(self, selector: #selector(ProfileEditViewController.draw), name: FBSDKProfileDidChangeNotification, object: nil)
	}
	
	override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: FBSDKAccessTokenDidChangeNotification, object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: FBSDKProfileDidChangeNotification, object: nil)
	}
	
	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/

	func doneAction(sender: AnyObject){
		if !isValid() { return }
		post()
	}
	
	func cancelAction(sender: AnyObject){
		
		if !isDirty() {
			self.performBack(true)
			return
		}
		
		DeleteConfirmationAlert(
			"Do you want to discard your editing changes?",
			actionTitle: "Discard", cancelTitle: "Cancel", delegate: self) {
				doIt in
				if doIt {
					self.performBack(true)
				}
		}
	}
	
	func facebookDisconnectAction(sender: AnyObject) {
		/*
		 * User stays logged in with proxibase. Any features that use Facebook
		 * like app invites will fallback to a different provider.
		 */
		self.facebookDisconnect.fadeOut()
		self.facebookActivity.fadeIn()
		self.facebookActivity.hidesWhenStopped = true
		self.facebookActivity.startAnimating()
		if FBSDKAccessToken.currentAccessToken() != nil {
			self.provider.deauthorize { response, error in
				self.facebookActivity.stopAnimating()
				self.facebookDisconnect.fadeIn()
				if error == nil {
					self.facebookOffGroup.fadeIn()
					self.facebookOnGroup.fadeOut()
				}
			}
		}
	}	
	
	func facebookConnectAction(sender: AnyObject) {
		/*
		* User stays logged in with proxibase. Any features that use Google
		* like app invites will fallback to a different provider.
		*/
		if FBSDKAccessToken.currentAccessToken() == nil {
			self.provider.authorize { response, error in
				if FBSDKAccessToken.currentAccessToken() != nil {
					if self.inputState == .Onboarding {
						self.provider.profile {
							response, error in
							if let profile = response as? ServiceUserProfile where error == nil {
								self.inputName = profile.name
								self.inputEmail = profile.email
								self.inputUserId = profile.userId
								self.inputPhotoUrl = profile.photoUrl
								self.bind()
							}
						}
					}
					else {
						self.facebookOffGroup.fadeOut()
						self.facebookOnGroup.fadeIn()
					}
				}
			}
		}
		else {
			if self.inputState == .Onboarding {
				provider.profile {
					response, error in
					if let profile = response as? ServiceUserProfile where error == nil {
						self.inputName = profile.name
						self.inputEmail = profile.email
						self.inputUserId = profile.userId
						self.inputPhotoUrl = profile.photoUrl
						self.bind()
					}
				}
			}
		}
	}
	
	func changePasswordAction(sender: AnyObject) {
		let controller = PasswordEditViewController()
		self.navigationController?.pushViewController(controller, animated: true)
	}
	
    func termsAction(sender: AnyObject) {
        let webViewController = PBWebViewController()
        webViewController.URL = NSURL(string: "http://patchr.com/terms")!
        webViewController.showsNavigationToolbar = false
        self.navigationController?.pushViewController(webViewController, animated: true)
    }
	
	func deleteAction(sender: AnyObject) {
		
		DeleteConfirmationAlert(
			"Confirm account delete",
			message: "Deleting your user account will erase all patches and messages you have created and cannot be undone. Enter YES to confirm.",
			actionTitle: "Delete",
			cancelTitle: "Cancel",
			destructConfirmation: true,
			delegate: self) {
				doIt in
				if doIt {
					self.delete()
				}
		}
	}
	
	func providerConnectionChanged(notification: NSNotification) {
		if notification.userInfo![FBSDKAccessTokenDidChangeUserID] != nil {
			draw()
		}
	}
	
	/*--------------------------------------------------------------------------------------------
	 * Methods
	 *--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
		self.schema = Schema.ENTITY_USER
		
		if self.inputState == State.Onboarding {
			self.message.text = "Make your profile more personal"
		}
		else {
			self.message.text = "Profile"
		}
		
		self.facebookActivity.accessibilityIdentifier = "activity_facebook"
		self.provider = FacebookProvider(controller: self)
		
		self.message.textColor = Theme.colorTextTitle
		self.message.numberOfLines = 0
		self.message.textAlignment = .Center
		self.contentHolder.addSubview(self.message)
		
		self.photoView.photoSchema = Schema.ENTITY_USER
		self.photoView.setHostController(self)
		self.contentHolder.addSubview(self.photoView)
		
		self.nameField.placeholder = "Full name"
		self.nameField.accessibilityIdentifier = "name_field"
		self.nameField.delegate = self
		self.nameField.autocapitalizationType = .Words
		self.nameField.autocorrectionType = .No
		self.nameField.keyboardType = UIKeyboardType.Default
		self.nameField.returnKeyType = UIReturnKeyType.Next
		self.contentHolder.addSubview(self.nameField)
		
		self.emailField.placeholder = "Email"
		self.emailField.accessibilityIdentifier = "email_field"
		self.emailField.delegate = self
		self.emailField.autocapitalizationType = .None
		self.emailField.autocorrectionType = .No
		self.emailField.keyboardType = UIKeyboardType.EmailAddress
		self.nameField.returnKeyType = UIReturnKeyType.Done
		self.contentHolder.addSubview(self.emailField)
		
		if self.inputState == State.Onboarding {
			
			Reporting.screen("ProfileSignup")
			self.view.accessibilityIdentifier = View.SignupProfile
			
			navigationItem.title = "Profile"
			self.progressStartLabel = "Signing up..."
			self.progressFinishLabel = "Joined"
			self.cancelledLabel = "Sign up cancelled"
			
			self.photoView.configureTo(self.inputPhotoUrl != nil ? .Photo : .Placeholder)
			
			self.emailField.enabled = false
			self.emailField.textColor = Theme.colorTextSecondary
			
			self.joinButton.setTitle("JOIN", forState: .Normal)
			self.joinButton.accessibilityIdentifier = "submit_button"
			self.contentHolder.addSubview(self.joinButton)
			
			self.termsButton.setTitle("By joining, you agree to the Terms of Service", forState: .Normal)
			self.termsButton.accessibilityIdentifier = "terms_button"
			self.termsButton.titleLabel!.numberOfLines = 2
			self.termsButton.titleLabel!.textAlignment = NSTextAlignment.Center
			self.contentHolder.addSubview(self.termsButton)
			
			self.facebookButton = AirButton()
			self.facebookButton.setTitle("AUTO FILL USING FACEBOOK", forState: .Normal)
			self.facebookButton.accessibilityIdentifier = "facebook_button"
			self.contentHolder.addSubview(self.facebookButton)
			
			/* Navigation bar buttons */
			let doneButton   = UIBarButtonItem(title: "Join", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(ProfileEditViewController.doneAction(_:)))
			doneButton.accessibilityIdentifier = "nav_submit_button"
			
			self.navigationItem.rightBarButtonItems = [doneButton]
			self.navigationItem.leftBarButtonItems = nil
			
			self.joinButton.addTarget(self, action: #selector(ProfileEditViewController.doneAction(_:)), forControlEvents: .TouchUpInside)
			self.termsButton.addTarget(self, action: #selector(ProfileEditViewController.termsAction(_:)), forControlEvents: .TouchUpInside)
			self.facebookButton.addTarget(self, action: #selector(ProfileEditViewController.facebookConnectAction(_:)), forControlEvents: .TouchUpInside)
		}
		else {
			
			Reporting.screen("ProfileEdit")
			self.view.accessibilityIdentifier = View.ProfileEdit
			
			navigationItem.title = "Edit profile"
			self.progressStartLabel = "Updating"
			self.progressFinishLabel = "Updated"
			self.cancelledLabel = "Update cancelled"
			
			self.photoView.configureTo(self.inputUser?.photo != nil ? .Photo : .Placeholder)
			
			self.areaField.placeholder = "Location"
			self.areaField.accessibilityIdentifier = "area_field"
			self.areaField.delegate = self
			self.areaField.keyboardType = UIKeyboardType.Default
			self.areaField.returnKeyType = UIReturnKeyType.Done
			self.contentHolder.addSubview(self.areaField)
			
			self.changePasswordButton.setTitle("CHANGE PASSWORD", forState: .Normal)
			self.changePasswordButton.accessibilityIdentifier = "change_password_button"
			self.contentHolder.addSubview(self.changePasswordButton)
			
			self.facebookOnGroup.alpha = 0
			
			self.facebookButton.setTitle("CONNECT WITH FACEBOOK", forState: .Normal)
			self.facebookButton.accessibilityIdentifier = "facebook_button"
			self.facebookButton.addTarget(self, action: #selector(ProfileEditViewController.facebookConnectAction(_:)), forControlEvents: .TouchUpInside)
			self.facebookOffGroup.addSubview(self.facebookButton)
			
			self.comment.text = "Don't worry, we won't post without your permission."
			self.comment.textColor = Theme.colorTextSecondary
			self.comment.numberOfLines = 2
			self.comment.textAlignment = NSTextAlignment.Center
			self.facebookOffGroup.addSubview(self.comment)
			self.contentHolder.addSubview(self.facebookOffGroup)
			
			self.facebookPhoto.contentMode = UIViewContentMode.ScaleAspectFill
			self.facebookPhoto.clipsToBounds = true
			self.facebookPhoto.layer.cornerRadius = 36
			self.facebookPhoto.layer.backgroundColor = Theme.colorBackgroundImage.CGColor
			self.facebookOnGroup.addSubview(self.facebookPhoto)
			
			self.facebookName.textAlignment = .Center
			self.facebookOnGroup.addSubview(self.facebookName)
			
			self.facebookDisconnect.setTitle("Disconnect from Facebook", forState: .Normal)
			self.facebookDisconnect.accessibilityIdentifier = "facebook_disconnect_button"
			self.facebookOnGroup.addSubview(self.facebookDisconnect)
			
			self.facebookActivity.hidden = true
			self.facebookOnGroup.addSubview(self.facebookActivity)
			self.contentHolder.addSubview(self.facebookOnGroup)
			
			self.facebookOnGroup.alpha = 0
			self.facebookOffGroup.alpha = 1
			if FBSDKAccessToken.currentAccessToken() != nil {
				self.facebookOnGroup.alpha = 1
				self.facebookOffGroup.alpha = 0
			}
			
			/* Navigation bar buttons */
			let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: #selector(ProfileEditViewController.cancelAction(_:)))
			let deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: #selector(ProfileEditViewController.deleteAction(_:)))
			let doneButton   = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: #selector(ProfileEditViewController.doneAction(_:)))
			
			doneButton.accessibilityIdentifier = "nav_submit_button"
			cancelButton.accessibilityIdentifier = "nav_cancel_button"
			deleteButton.accessibilityIdentifier = "nav_delete_button"
			
			self.navigationItem.leftBarButtonItems = [cancelButton]
			self.navigationItem.rightBarButtonItems = [doneButton, Utils.spacer, deleteButton]
			
			self.changePasswordButton.addTarget(self, action: #selector(ProfileEditViewController.changePasswordAction(_:)), forControlEvents: .TouchUpInside)
			self.facebookButton.addTarget(self, action: #selector(ProfileEditViewController.facebookConnectAction(_:)), forControlEvents: .TouchUpInside)
			self.facebookDisconnect.addTarget(self, action: #selector(ProfileEditViewController.facebookDisconnectAction(_:)), forControlEvents: .TouchUpInside)
		}
	}
	
	func draw() {
		if self.inputState != .Onboarding {
			if FBSDKAccessToken.currentAccessToken() != nil {
				if FBSDKProfile.currentProfile() != nil {
					self.facebookName.text = FBSDKProfile.currentProfile().name
					let userId = FBSDKProfile.currentProfile().userID
					let url = NSURL(string: "https://graph.facebook.com/\(userId!)/picture?type=large")
					self.facebookPhoto.sd_setImageWithURL(url, placeholderImage: nil, options: [.RetryFailed, .LowPriority])
				}
			}
		}
	}
	
    func bind() {
		
		if self.inputState == State.Onboarding {
			self.emailField.text = self.inputEmail
			self.nameField.text = self.inputName
			
			/* Photo */
			if self.inputPhotoUrl != nil {
				let imageResult = ImageResult()
				imageResult.mediaUrl = self.inputPhotoUrl?.absoluteString
				imageResult.width = 200
				imageResult.height = 200
				self.photoView.imageButton.setImageWithImageResult(imageResult)
				self.photoView.configureTo(.Photo)
			}
		}
		else {
			self.nameField.text = self.inputUser?.name
			self.emailField.text = self.inputUser?.email
			self.areaField.text = self.inputUser?.area
			self.photoView.bindPhoto(self.inputUser?.photo)
		}
    }
	
	func post() {
		
		if self.processing { return }
		
		processing = true
		
		let progress = AirProgress.showHUDAddedTo(self.view.window, animated: true)
		progress.mode = MBProgressHUDMode.Indeterminate
		progress.styleAs(.ActivityWithText)
		progress.labelText = self.progressStartLabel
		progress.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileEditViewController.progressWasCancelled(_:))))
		progress.removeFromSuperViewOnHide = true
		progress.show(true)
		
		let parameters = self.gather(NSMutableDictionary())
		var cancelled = false
		
		let queue = TaskQueue()
		
		Utils.delay(5.0) {
			progress?.detailsLabelText = "Tap to cancel"
		}
		
		/* Process image if any */
		
		if var image = parameters["photo"] as? UIImage {
			queue.tasks +=~ { _, next in
				
				/* Ensure image is resized/rotated before upload */
				image = Utils.prepareImage(image: image)
				
				/* Generate image key */
				let imageKey = "\(Utils.genImageKey()).jpg"
				
				/* Upload */
				self.imageUploadRequest = S3.sharedService.uploadImageToS3(image, imageKey: imageKey) {
					task in
					
					if let error = task.error {
						if error.domain == AWSS3TransferManagerErrorDomain as String {
							if let errorCode = AWSS3TransferManagerErrorType(rawValue: error.code) {
								if errorCode == .Cancelled {
									cancelled = true
								}
							}
						}
						queue.skip()
						next(Result(response: nil, error: error))
					}
					else {
						let photo = [
							"width": Int(image.size.width), // width/height are in points...should be pixels?
							"height": Int(image.size.height),
							"source": S3.sharedService.imageSource,
							"prefix": imageKey
						]
						parameters["photo"] = photo
						next(nil)
					}
				}
			}
		}
		
		/* Upload user */
		
		queue.tasks +=~ { _, next in
			
			if self.inputState == .Onboarding {
				let secret = PatchrKeys().proxibaseSecret()	// Obfuscated but highly insecure
				let createParameters: NSDictionary = [
					"data": parameters,
					"secret": secret,
					"installId": UserController.instance.installId
				]
				
				self.entityPostRequest = DataController.proxibase.postEntity("user/create", parameters: createParameters) {
					response, error in
					if error != nil && error!.code == NSURLErrorCancelled {
						cancelled = true
					}
					if error == nil {
						/* Remember email address for easy data entry */
						NSUserDefaults.standardUserDefaults().setObject(self.emailField.text, forKey: PatchrUserDefaultKey("userEmail"))
						NSUserDefaults.standardUserDefaults().synchronize()
					}
					next(Result(response: response, error: error))
				}
			}
			else {
				let endpoint = "data/users/\(self.inputUser!.id_)"
				self.entityPostRequest = DataController.proxibase.postEntity(endpoint, parameters: parameters) {
					response, error in
					if error == nil {
						progress!.progress = 1.0
					}
					else if error!.code == NSURLErrorCancelled {
						cancelled = true
					}
					next(Result(response: response, error: error))
				}
			}
		}
		
		/* Update Ui */
		
		queue.tasks +=! {
			self.processing = false
			
			if cancelled {
				UIShared.Toast(self.cancelledLabel)
				return
			}
			
			progress?.hide(true)
			
			if let result: Result = queue.lastResult as? Result {
				if var error = ServerError(result.error) {
					if error.code == .FORBIDDEN_DUPLICATE {
						error.message = Utils.LocalizedString("Email address already in use.")
						self.handleError(error, errorActionType: .ALERT)
					}
					else {
						self.handleError(error)
					}
					return
				}
				if self.inputState == .Onboarding {
					/*
					* After creating a user, the user is left in a logged-in state, so process the response
					* to extract the credentials.
					*/
					if let response: AnyObject = result.response as AnyObject? {
						
						UserController.instance.handleSuccessfulLoginResponse(response)
						
						/* Navigate to main interface */
						if self.inputRouteToMain {
							self.navigateToMain() // Replaces any current navigation stack
						}
						else {
							if self.isModal {
								self.dismissViewControllerAnimated(true, completion: nil)
							}
							else {
								self.navigationController?.popViewControllerAnimated(true)
							}
						}
						Reporting.track("Created User and Logged In", properties: nil)
						return
					}
				}
				else {
					Reporting.track("Updated User", properties: nil)
				}
			}
			
			self.performBack(true)
			UIShared.Toast(self.progressFinishLabel)
		}
		
		/* Start tasks */
		
		queue.run()
	}
	
	func delete() {
		
		if self.processing {
			return
		}
		self.processing = true
		
		if self.inputUser != nil {
			
			let entityPath = "user/\((self.inputUser!.id_)!)?erase=true"
			let userName: String = self.inputUser!.name
			
			DataController.proxibase.deleteObject(entityPath) {
				response, error in
				
				NSOperationQueue.mainQueue().addOperationWithBlock {
					
					self.processing = false
					if let error = ServerError(error) {
						self.handleError(error)
					}
					else {
						Log.i("User deleted: \(userName)")
					}
					
					/* Return to the lobby even if there was an error since we signed out */
					UserController.instance.discardCredentials()
					Reporting.updateUser(nil)
					BranchProvider.logout()
					UserController.instance.clearStore()
					NSUserDefaults.standardUserDefaults().setObject(nil, forKey: PatchrUserDefaultKey("userEmail"))
					NSUserDefaults.standardUserDefaults().synchronize()
					
					LocationController.instance.clearLastLocationAccepted()
					
					let navController = UINavigationController()
					navController.viewControllers = [LobbyViewController()]
					AppDelegate.appDelegate().window!.setRootViewController(navController, animated: true)
					Reporting.track("Deleted User", properties: ["id":self.inputUser!.id_, "name": userName, "email": self.inputUser!.email])
					UIShared.Toast("User \(userName) erased", controller: navController)
				}
			}
		}
	}
	
    func gather(parameters: NSMutableDictionary) -> NSMutableDictionary {
		parameters["name"] = nilToNull(self.nameField.text)
		parameters["photo"] = nilToNull(self.photoView.imageButton.imageForState(.Normal))
		parameters["email"] = nilToNull(self.emailField.text)
		parameters["area"] = nilToNull(self.areaField.text)
		if self.inputState == .Onboarding && self.inputProvider == AuthProvider.PROXIBASE {
			parameters["password"] = nilToNull(self.inputPassword)
		}
        return parameters
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
			let controller = MainTabBarController()
			controller.selectedIndex = 0
			AppDelegate.appDelegate().window!.setRootViewController(controller, animated: true)
			if UserController.instance.userName != nil {
				UIShared.Toast("Logged in as \(UserController.instance.userName!)", controller: controller, addToWindow: false)
			}
		}
	}
	
    func isDirty() -> Bool {
		
		if self.inputState == .Onboarding {
			if self.nameField.text != self.inputName {
				return true
			}
			if self.emailField.text != self.inputEmail {
				return true
			}
		}
		else {
			if !stringsAreEqual(self.nameField.text, string2: self.inputUser!.name) {
				return true
			}
			if !stringsAreEqual(self.emailField.text, string2: self.inputUser!.email) {
				return true
			}
			if !stringsAreEqual(self.areaField.text, string2: self.inputUser!.area) {
				return true
			}
		}
		
		if photoView.photoDirty {
			return true
		}
		
		return false
	}
	
    func isValid() -> Bool {
		
        if nameField.isEmpty {
            Alert("Enter a name.", message: nil, cancelButtonTitle: "OK")
            return false
        }
		
		if emailField.isEmpty {
			Alert("Enter an email address.", message: nil, cancelButtonTitle: "OK")
			return false
		}
		
		if !emailField.text!.isEmail() {
			Alert("Enter a valid email address.")
			return false
		}		

        return true
    }
	
	func progressWasCancelled(sender: AnyObject) {
		if let gesture = sender as? UIGestureRecognizer, let hud = gesture.view as? MBProgressHUD {
			hud.animationType = MBProgressHUDAnimation.ZoomIn
			hud.hide(true)
			self.imageUploadRequest?.cancel() // Should do nothing if upload already complete or isn't any
			self.entityPostRequest?.cancel()
		}
	}
	
	override func textFieldShouldReturn(textField: UITextField) -> Bool {
		
		if self.inputState == .Onboarding {
			if textField == self.nameField {
				self.doneAction(textField)
				textField.resignFirstResponder()
				return false
			}
		}
		else {
			if textField == self.nameField {
				self.emailField.becomeFirstResponder()
				return false
			}
			else if textField == self.emailField {
				self.doneAction(textField)
				textField.resignFirstResponder()
				return false
			}
		}
		return true
	}
}