//
//  RegistrationTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-24.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class UserEditViewController: EntityEditViewController {

	@IBOutlet weak var emailField: 			 UITextField!
	@IBOutlet weak var areaField: 			 UITextField!
	@IBOutlet weak var passwordField: 		 UITextField!

    @IBOutlet weak var joinButton: 			 UIButton!
	@IBOutlet weak var changePasswordButton: UIButton!

	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.collection = "users"
        self.defaultPhotoName = "imgDefaultUser"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.photoView!.frame = CGRectMake(0, 0, 200, 200)
        
        if editMode {
            navigationItem.title = Utils.LocalizedString("Edit profile")
            self.progressStartLabel = "Updating"
            self.progressFinishLabel = "Updated!"
            self.cancelledLabel = "Update cancelled"
            
            /* Navigation bar buttons */
            var deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: "deleteAction:")
            var doneButton   = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: "doneAction:")
            self.navigationItem.rightBarButtonItems = [doneButton, spacer, deleteButton]
        }
        else {
            navigationItem.title = Utils.LocalizedString("Register")
            self.progressStartLabel = "Registering"
            self.progressFinishLabel = "Registered!"
            self.cancelledLabel = "Registration cancelled"
            
            /* Use tab order when inserting users */
            nameField.delegate = self
            emailField.delegate = self
            if passwordField != nil {
                passwordField.delegate = self
            }
            
            /* Navigation bar buttons */
            var doneButton   = UIBarButtonItem(title: "Join", style: UIBarButtonItemStyle.Plain, target: self, action: "doneAction:")
            self.navigationItem.rightBarButtonItems = [doneButton]
        }
        
        bind()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if editMode {
            setScreenName("UserEdit")
        }
        else {
            setScreenName("UserCreate")
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if !editMode {
            self.nameField.becomeFirstResponder()
        }
    }
    
	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/

	@IBAction func joinAction(sender: AnyObject) {
		if !isValid() { return }
		join()
	}

    @IBAction func termsAction(sender: AnyObject) {
        let webViewController = PBWebViewController()
        webViewController.URL = NSURL(string: "http://patchr.com/terms")!
        webViewController.showsNavigationToolbar = false
        self.navigationController?.pushViewController(webViewController, animated: true)
    }

	/*--------------------------------------------------------------------------------------------
	 * Methods
	 *--------------------------------------------------------------------------------------------*/

    override func bind() {
        super.bind()
        
        if let user = entity as? User {
            self.email = user.email            
            if self.areaField != nil && user.area != nil {
                self.area = user.area
            }
        }
    }
    
    override func gather(parameters: NSMutableDictionary) -> NSMutableDictionary {
        
        var parameters = super.gather(parameters)
        
        if editMode {
            let user = entity as! User
            if email != user.email {
                parameters["email"] = nilToNull(email)
            }
            if areaField != nil && area != user.area {
                parameters["area"] = nilToNull(area)
            }
        }
        else {
            parameters["email"] = nilToNull(self.email)
            parameters["password"] = nilToNull(self.password)
            if areaField != nil {
                parameters["area"] = nilToNull(self.area)
            }
        }
        return parameters
    }

    override func isDirty() -> Bool {
        
        if editMode {
            let user = entity as! User
            
            if user.email != email {
                return true
            }
            if user.area != area {
                return true
            }
            return super.isDirty()
        }
        else {
            if !(password.isEmpty && email.isEmpty) {
                return true
            }
            return super.isDirty()
        }
    }
    
    override func isValid() -> Bool {
        
        if nameField.isEmpty {
            Alert("Enter a name.", message: nil, cancelButtonTitle: "OK")
            return false
        }
        
        if emailField.isEmpty {
            Alert("Enter an email address.", message: nil, cancelButtonTitle: "OK")
            return false
        }

		if !editMode {
            if (count(passwordField.text.utf16) < 6) {
                Alert("Enter a password with six characters or more.", message: nil, cancelButtonTitle: "OK")
                return false
            }
        }
        
        return true
    }

    override func endFieldEditing() {
        for field in [nameField, emailField, areaField, passwordField] {
            if (field?.isFirstResponder() != nil) {
                field.endEditing(false)
            }
        }
    }
    
    func join() {
        
        if self.processing { return }
        
        processing = true
        
        var progress = AirProgress.showHUDAddedTo(self.view.window, animated: true)
        progress.mode = MBProgressHUDMode.Indeterminate
        progress.styleAs(.ActivityLight)
        progress.labelText = "Registering..."
        progress!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("progressWasCancelled:")))
        progress.show(true)
        
        var parameters = self.gather(NSMutableDictionary())
        var cancelled = false
        
        let queue = TaskQueue()
        
        Utils.delay(5.0, closure: {
            () -> () in
            progress?.detailsLabelText = "Tap to cancel"
        })
        
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
            let createParameters: NSDictionary = [
                "data": parameters,
                "secret": "larissa",
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
        
        /* Update Ui */
        
        queue.tasks +=! {
            self.processing = false
            
            if cancelled {
                Shared.Toast(self.cancelledLabel)
                return
            }
            
            progress!.hide(true)
            progress = nil
            
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
                /*
                * After creating a user, the user is left in a logged-in state, so process the response
                * to extract the credentials.
                */
                if let response: AnyObject = result.response as AnyObject? {
                    UserController.instance.handleSuccessfulSignInResponse(response)
                    
                    /* Navigate to main interface */
                    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                    let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
                    if let controller = storyboard.instantiateViewControllerWithIdentifier("MainTabBarController") as? UIViewController {
                        appDelegate.window?.setRootViewController(controller, animated: true)
                        Shared.Toast("Signed in as \(UserController.instance.userName!)", controller: controller)
                    }
                    
                }
            }
        }
        
        /* Start tasks */
        
        queue.run()
    }
    
    /*--------------------------------------------------------------------------------------------
    * Field wrappers
    *--------------------------------------------------------------------------------------------*/
    
    var email: String {
        get {
            return self.emailField.text
        }
        set {
            self.emailField.text = newValue
        }
    }
    
    var area: String {
        get {
            return self.areaField.text
        }
        set {
            self.areaField.text = newValue
        }
    }
    
    var password: String {
        get {
            return self.passwordField.text
        }
        set {
            self.passwordField.text = newValue
        }
    }
}

extension UserEditViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        if !editMode {
            if textField == self.nameField {
                self.emailField.becomeFirstResponder()
                return false
            }
            else if textField == self.emailField {
                self.passwordField.becomeFirstResponder()
                return false
            }
            else if textField == self.passwordField {                
                self.joinAction(textField)
                textField.resignFirstResponder()
                return false
            }
        }
        return true
    }
}
