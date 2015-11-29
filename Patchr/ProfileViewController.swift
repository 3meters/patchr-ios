//
//  RegistrationTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-24.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class ProfileViewController: BaseViewController {
	
	var processing: Bool = false
	var progressStartLabel: String?
	var progressFinishLabel: String?
	var cancelledLabel: String?
	
	var provider = AuthProvider.PROXIBASE
	var schema: String?
	var state: State = State.Editing
	
	var imageUploadRequest: AWSS3TransferManagerUploadRequest?
	var entityPostRequest: NSURLSessionTask?
	
	var inputUser: User?
	var inputName: String?
	var inputEmail: String?
	var inputUserId: String?
	var inputPhotoUrl: NSURL?

	var photoView            = PhotoView()
	var nameField            = AirTextField()
	var emailField           = AirTextField()
	var areaField            = AirTextField()
	var changePasswordButton = AirButton()
	var joinButton           = AirButtonFeatured()
	var termsButton          = AirButtonLink()
	var facebookButton:	AirButton?
	var googleButton: AirButton?
	var progress: AirProgress?
	
	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }
	
	override func loadView() {
		super.loadView()
		initialize()
	}
	
	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.photoView.anchorTopCenterWithTopPadding(88, width: 150, height: 150)
		self.nameField.alignUnder(self.photoView, matchingCenterWithTopPadding: 8, width: 288, height: 48)

		if self.state == State.Onboarding {
			self.emailField.alignUnder(self.nameField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
			self.joinButton.alignUnder(self.emailField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
			self.termsButton.alignUnder(self.joinButton, matchingCenterWithTopPadding: 8, width: 288, height: 48)
		}
		else {
			self.areaField.alignUnder(self.nameField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
			self.emailField.alignUnder(self.areaField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
			self.changePasswordButton.alignUnder(self.emailField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
			if self.facebookButton != nil {
				self.facebookButton!.alignUnder(self.changePasswordButton, matchingCenterWithTopPadding: 8, width: 288, height: 48)
			}
			if self.googleButton != nil {
				self.googleButton!.alignUnder(self.changePasswordButton, matchingCenterWithTopPadding: 8, width: 288, height: 48)
			}
		}
	}
	
	func doneAction(sender: AnyObject){
		if !isValid() { return }
		post()
	}
	
	func cancelAction(sender: AnyObject){
		
		if !isDirty() {
			self.performBack(true)
			return
		}
		
		ActionConfirmationAlert(
			"Do you want to discard your editing changes?",
			actionTitle: "Discard", cancelTitle: "Cancel", delegate: self) {
				doIt in
				if doIt {
					self.performBack(true)
				}
		}
	}
	
	func facebookAction(sender: AnyObject) {
		let provider = FacebookProvider()
		provider.deauthorize()
		FBSDKAccessToken.setCurrentAccessToken(nil)
		
		self.progress = AirProgress.showHUDAddedTo(self.view.window, animated: true)
		self.progress!.mode = MBProgressHUDMode.Indeterminate
		self.progress!.styleAs(.ActivityLight)
		self.progress!.minShowTime = 0.5
		self.progress!.labelText = "Signing out..."
		self.progress!.removeFromSuperViewOnHide = true
		self.progress!.show(true)
		
		UserController.instance.signout()	// Blocks until finished
	}
	
	func googleAction(sender: AnyObject) {
		Shared.Toast("Do something with Google")
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
		
		ActionConfirmationAlert(
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
	
	func alertTextFieldDidChange(sender: AnyObject) {
		if let alertController: AirAlertController = self.presentedViewController as? AirAlertController {
			let confirm = alertController.textFields![0]
			let okAction = alertController.actions[0]
			okAction.enabled = confirm.text == "YES"
		}
	}

	/*--------------------------------------------------------------------------------------------
	 * Methods
	 *--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
		self.schema = Schema.ENTITY_USER
		
		self.photoView.photoSchema = Schema.ENTITY_USER
		self.photoView.photoDefaultId = self.inputEmail
		self.photoView.setHostController(self)
		self.view.addSubview(self.photoView)
		
		self.nameField.placeholder = "Full name"
		self.nameField.delegate = self
		self.nameField.autocapitalizationType = .Words
		self.nameField.autocorrectionType = .No
		self.nameField.keyboardType = UIKeyboardType.Default
		self.nameField.returnKeyType = UIReturnKeyType.Next
		self.view.addSubview(self.nameField)
		
		self.emailField.placeholder = "Email"
		self.emailField.delegate = self
		self.emailField.autocapitalizationType = .None
		self.emailField.autocorrectionType = .No
		self.emailField.keyboardType = UIKeyboardType.EmailAddress
		self.nameField.returnKeyType = UIReturnKeyType.Done
		self.view.addSubview(self.emailField)
		
		if self.state == State.Onboarding {
		
			setScreenName("ProfileSignup")
			navigationItem.title = "Profile"
			self.progressStartLabel = "Signing up..."
			self.progressFinishLabel = "Joined!"
			self.cancelledLabel = "Sign up cancelled"
			
			self.photoView.configureTo(self.inputPhotoUrl != nil ? .Photo : .Placeholder)
			
			self.joinButton.setTitle("JOIN", forState: .Normal)
			self.view.addSubview(self.joinButton)
			
			self.termsButton.setTitle("By joining, you agree to the Terms of Service", forState: .Normal)
			self.termsButton.titleLabel!.numberOfLines = 2
			self.termsButton.titleLabel!.textAlignment = NSTextAlignment.Center
			self.view.addSubview(self.termsButton)
			
			/* Navigation bar buttons */
			let doneButton   = UIBarButtonItem(title: "Join", style: UIBarButtonItemStyle.Plain, target: self, action: "doneAction:")
			self.navigationItem.rightBarButtonItems = [doneButton]
			self.navigationItem.leftBarButtonItems = nil
			
			self.joinButton.addTarget(self, action: Selector("doneAction:"), forControlEvents: .TouchUpInside)
			self.termsButton.addTarget(self, action: Selector("termsAction:"), forControlEvents: .TouchUpInside)
		}
		else {
			
			setScreenName("ProfileEdit")
			navigationItem.title = "Edit profile"
			self.progressStartLabel = "Updating"
			self.progressFinishLabel = "Updated!"
			self.cancelledLabel = "Update cancelled"
			
			self.photoView.configureTo(self.inputUser!.photo != nil ? .Photo : .Placeholder)
			
			self.areaField.placeholder = "Location"
			self.areaField.delegate = self
			self.areaField.keyboardType = UIKeyboardType.Default
			self.areaField.returnKeyType = UIReturnKeyType.Done
			self.view.addSubview(self.areaField)
			
			self.changePasswordButton.setTitle("CHANGE PASSWORD", forState: .Normal)
			self.view.addSubview(self.changePasswordButton)
			
			if FBSDKAccessToken.currentAccessToken() != nil {
				self.facebookButton = AirButton()
				self.facebookButton!.setTitle("DISCONNECT FROM FACEBOOK", forState: .Normal)
				self.facebookButton!.borderColor = Colors.facebookColor
				self.facebookButton!.setTitleColor(Colors.facebookColor, forState: .Normal)
				self.facebookButton!.addTarget(self, action: Selector("facebookAction:"), forControlEvents: .TouchUpInside)
				self.view.addSubview(self.facebookButton!)
			}
			
			/* Navigation bar buttons */
			let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancelAction:")
			let deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: "deleteAction:")
			let doneButton   = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: "doneAction:")
			self.navigationItem.leftBarButtonItems = [cancelButton]
			self.navigationItem.rightBarButtonItems = [doneButton, spacer, deleteButton]
			
			self.changePasswordButton.addTarget(self, action: Selector("changePasswordAction:"), forControlEvents: .TouchUpInside)
		}
	}

    func bind() {
		
		if self.state == State.Onboarding {
			self.emailField.text = self.inputEmail
			self.nameField.text = self.inputName
			
			/* Photo */
			if self.inputPhotoUrl != nil {
				let imageResult = ImageResult()
				imageResult.mediaUrl = self.inputPhotoUrl?.absoluteString
				imageResult.width = 200
				imageResult.height = 200
				self.photoView.imageButton.setImageWithImageResult(imageResult)
			}
			else {
				self.photoView.bindPhoto(nil) // Shows default
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
		progress.styleAs(.ActivityLight)
		progress.labelText = self.progressStartLabel
		progress.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("progressWasCancelled:")))
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
				image = Utils.prepareImage(image)
				
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
			
			if self.state == .Onboarding {
				let secret = PatchrKeys().proxibaseSecret()	// Obfuscated but highly insecure
				let createParameters: NSDictionary = [
					"data": parameters,
					"secret": secret,
					"installId": DataController.proxibase.installationIdentifier
				]
				
				self.entityPostRequest = DataController.proxibase.postEntity("user/create", parameters: createParameters) {
					response, error in
					if error != nil && error!.code == NSURLErrorCancelled {
						cancelled = true
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
				Shared.Toast(self.cancelledLabel)
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
				if self.state == .Onboarding {
					/*
					* After creating a user, the user is left in a logged-in state, so process the response
					* to extract the credentials.
					*/
					if let response: AnyObject = result.response as AnyObject? {
						UserController.instance.handleSuccessfulSignInResponse(response)
						
						/* Navigate to main interface */
						let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
						let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
						let controller = storyboard.instantiateViewControllerWithIdentifier("MainTabBarController")
						appDelegate.window?.setRootViewController(controller, animated: true)
						Shared.Toast("Logged in as \(UserController.instance.userName!)", controller: controller)
						return
					}
				}
			}
			
			self.performBack(true)
			Shared.Toast(self.progressFinishLabel)
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
					
					/* Return to the lobby even if there was an error since we signed out */
					UserController.instance.discardCredentials()
					NSUserDefaults.standardUserDefaults().setObject(nil, forKey: PatchrUserDefaultKey("userEmail"))
					NSUserDefaults.standardUserDefaults().synchronize()
					
					LocationController.instance.clearLastLocationAccepted()
					
					if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
						let navController = UINavigationController()
						navController.viewControllers = [LobbyViewController()]
						appDelegate.window!.setRootViewController(navController, animated: true)
						Shared.Toast("User \(userName) erased", controller: navController)
					}
				}
			}
		}
	}
	
    func gather(parameters: NSMutableDictionary) -> NSMutableDictionary {
		parameters["name"] = nilToNull(self.nameField.text)
		parameters["photo"] = nilToNull(self.photoView.imageButton.imageForState(.Normal))
		parameters["email"] = nilToNull(self.emailField.text)
		parameters["area"] = nilToNull(self.areaField.text)
        return parameters
    }

    func isDirty() -> Bool {
		
		if self.state == .Onboarding {
			if self.nameField.text != self.inputName {
				return true
			}
			if self.emailField.text != self.inputEmail {
				return true
			}
		}
		else {
			if self.nameField.text != self.inputUser!.name {
				return true
			}
			if self.emailField.text != self.inputUser!.email {
				return true
			}
			if self.areaField.text != self.inputUser!.area {
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
	
	func performBack(animated: Bool = true) {
		/* Override in subclasses for control of dismiss/pop process */
		if isModal {
			self.dismissViewControllerAnimated(animated, completion: nil)
		}
		else {
			self.navigationController?.popViewControllerAnimated(true)
		}
	}

    func endFieldEditing() {
        for field in [nameField, emailField] {
			field.endEditing(false)
        }
    }
}

extension ProfileViewController: UITextFieldDelegate {
	
    func textFieldShouldReturn(textField: UITextField) -> Bool {
		
		if self.state == .Onboarding {
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

enum State: Int {
	case Editing
	case Onboarding
}