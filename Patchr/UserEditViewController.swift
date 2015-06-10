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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collection = "users"
        self.defaultPhotoName = "imgDefaultUser"
        
        if !editMode {
            navigationItem.title = LocalizedString("Register")
            self.progressStartLabel = "Registering"
            self.progressFinishLabel = "Registered!"
            
            /* Photo default */
            photo = UIImage(named: "imgDefaultUser")!
            usingPhotoDefault = true
            
            /* Use tab order when inserting users */
            nameField.delegate = self
            emailField.delegate = self
            if passwordField != nil {
                passwordField.delegate = self
            }
        }
        else {
            navigationItem.title = LocalizedString("Edit profile")
            self.progressStartLabel = "Updating"
            self.progressFinishLabel = "Updated!"
            bind()
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
    
        let proxibase = DataController.proxibase
        var parameters = NSMutableDictionary()
        parameters = self.gather(parameters)
        
        if let image = self.photoImage.imageForState(.Normal) {
            parameters["photo"] = image
        }
        
        proxibase.insertUser(nameField.text, email: emailField.text, password: passwordField.text, parameters: parameters) { (_, error) in
            
            dispatch_async(dispatch_get_main_queue()) {
                if let error = ServerError(error) {
                    var errorMessage = error.message

                    if error.code == .FORBIDDEN_DUPLICATE {
                        errorMessage = LocalizedString("Email address already in use.")
                    }
                    
                    let alert = UIAlertController(title: LocalizedString("Registration Failure"), message: errorMessage, preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: { _ in }))
                    self.presentViewController(alert, animated: true) {}
                }
                else {
                    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                    let viewController = UIStoryboard(name:"Main", bundle:NSBundle.mainBundle()).instantiateInitialViewController() as! UIViewController;
                    appDelegate.window!.setRootViewController(viewController, animated: true)
                }
            }   
        }
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
        
        let user = entity as! User
        
        email = user.email
        
        if areaField != nil {
            area = user.area
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
            UIAlertView(title: "Enter a name.", message: nil, delegate: nil, cancelButtonTitle: "OK").show()
            return false
        }
        
        if emailField.isEmpty {
            UIAlertView(title: "Enter an email address.", message: nil, delegate: nil, cancelButtonTitle: "OK").show()
            return false
        }

		if !editMode {
            if (count(passwordField.text.utf16) < 6) {
                UIAlertView(title: "Enter a password with six characters or more.", message: nil, delegate: nil, cancelButtonTitle: "OK").show()
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
