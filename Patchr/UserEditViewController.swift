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
                
        if editMode {
            navigationItem.title = Utils.LocalizedString("Edit profile")
            self.progressStartLabel = "Updating"
            self.progressFinishLabel = "Updated!"
            
            /* Navigation bar buttons */
            var deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: "deleteAction:")
            var doneButton   = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.Plain, target: self, action: "doneAction:")
            self.navigationItem.rightBarButtonItems = [doneButton, spacer, deleteButton]
        }
        else {
            navigationItem.title = Utils.LocalizedString("Register")
            self.progressStartLabel = "Registering"
            self.progressFinishLabel = "Registered!"
            
            /* Use tab order when inserting users */
            nameField.delegate = self
            emailField.delegate = self
            if passwordField != nil {
                passwordField.delegate = self
            }
        }
        
        bind()
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
        
        if processing { return }
        
        if !isValid() { return }
    
        processing = true
        
        let progress = MBProgressHUD.showHUDAddedTo(self.view.window, animated: true)
        progress.mode = MBProgressHUDMode.Indeterminate
        progress.labelText = "Registering..."
        progress.show(true)
        
        var parameters = self.gather(NSMutableDictionary())
        
        DataController.proxibase.insertUser(nameField.text, email: emailField.text, password: passwordField.text, parameters: parameters) {
            response, error in
            
            self.processing = false
            
            /* Make sure ui updates happen on the main thread */
            dispatch_async(dispatch_get_main_queue()) {
                
                progress.hide(true, afterDelay: 1.0)
                if var error = ServerError(error) {
                    if error.code == .FORBIDDEN_DUPLICATE {
                        error.message = Utils.LocalizedString("Email address already in use.")
                        self.handleError(error, errorActionType: .ALERT)
                    }
                    else {
                        self.handleError(error)
                    }
                }
                else {
                    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                    let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
                    if let controller = storyboard.instantiateViewControllerWithIdentifier("MainTabBarController") as? UIViewController {
                        appDelegate.window?.setRootViewController(controller, animated: true)
                        Shared.Toast("Signed in as \(UserController.instance.userName!)", controller: controller)
                    }
                }
            }   
        }
    }
    
    @IBAction override func cancelAction(sender: AnyObject){
        self.navigationController?.popViewControllerAnimated(true)
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
            parameters["email"] = nilToNull(email)
            if areaField != nil {
                parameters["area"] = nilToNull(area)
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

    /*--------------------------------------------------------------------------------------------
    * Helpers
    *--------------------------------------------------------------------------------------------*/
    
	override func endFieldEditing() {
		for field in [nameField, emailField, areaField, passwordField] {
			if (field?.isFirstResponder() != nil) {
				field.endEditing(false)
			}
		}
	}
    
    /*--------------------------------------------------------------------------------------------
    * Field wrappers
    *--------------------------------------------------------------------------------------------*/
    
    var email: String {
        get {
            return emailField.text
        }
        set {
            emailField.text = newValue
        }
    }
    
    var area: String {
        get {
            return areaField.text
        }
        set {
            areaField.text = newValue
        }
    }
    
    var password: String {
        get {
            return passwordField.text
        }
        set {
            passwordField.text = newValue
        }
    }
}

extension UserEditViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        if !editMode {
            if textField == self.nameField {
                self.emailField.becomeFirstResponder()
                return false
            } else if textField == self.emailField {
                self.passwordField.becomeFirstResponder()
                return false
            } else if textField == self.passwordField {
                
                // Kind of lame. Rely on bar button as the signal
                if self.doneButton.enabled {
                    self.joinAction(textField)
                    textField.resignFirstResponder()
                }
                return false
            }
        }
        return true
    }
}
