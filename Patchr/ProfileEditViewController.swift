//
//  RegistrationTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-24.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MBProgressHUD
import JVFloatLabeledTextField
import FirebaseRemoteConfig
import Firebase

class ProfileEditViewController: BaseEditViewController {
    
    var user: FireUser!
    var userQuery: UserQuery!

    var message = AirLabelTitle()
    var photoEditView = PhotoEditView()
    var firstNameField = AirTextField()
    var lastNameField = AirTextField()
    var phoneField = AirPhoneField()
    var skypeField = AirTextField()
    var accountButton = AirButton()

    var fullName: String? {
        
        let firstName = emptyToNil(self.firstNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines))
        let lastName = emptyToNil(self.lastNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines))
        
        if firstName == nil {
            if lastName == nil {
                return nil
            }
            else {
                return lastName
            }
        }
        else if lastName == nil {
            return firstName
        }
        else {
            return "\(firstName!) \(lastName!)"
        }
    }

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        
        let userId = UserController.instance.userId!
        self.userQuery = UserQuery(userId: userId, groupId: nil)
        self.userQuery.observe(with: { [weak self] user in
            if (user != nil) {
                self?.user = user
                self?.bind()
            }
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.userQuery.remove()
    }
    
    deinit {
        self.userQuery?.remove()
    }

    override func viewWillLayoutSubviews() {

        let messageSize = self.message.sizeThatFits(CGSize(width: 288, height: CGFloat.greatestFiniteMagnitude))
        self.message.anchorTopCenter(withTopPadding: 0, width: 288, height: messageSize.height)
        self.photoEditView.alignUnder(self.message, matchingCenterWithTopPadding: 16, width: 150, height: 150)
        self.firstNameField.alignUnder(self.photoEditView, matchingCenterWithTopPadding: 16, width: 288, height: 48)
        self.lastNameField.alignUnder(self.firstNameField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        self.phoneField.alignUnder(self.lastNameField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        self.skypeField.alignUnder(self.phoneField, matchingCenterWithTopPadding: 8, width: 288, height: 48)

        self.accountButton.alignUnder(self.skypeField, matchingCenterWithTopPadding: 12, width: 288, height: 48)

        super.viewWillLayoutSubviews()
    }

    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/
    
    func accountAction(sender: AnyObject) {
        /* Requires re-authentication */
        let controller = PasswordViewController()
        controller.mode = .reauth
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func closeAction(sender: AnyObject?) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Events.PhotoDidChange), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Events.PhotoRemoved), object: nil)
        close()
    }
    
    override func textFieldDidEndEditing(_ textField: UITextField) {
        super.textFieldDidEndEditing(textField)
        
        if textField == self.firstNameField {
            if emptyToNil(self.firstNameField.text) != self.user.profile?.firstName {
                let changeRequest = FIRAuth.auth()?.currentUser?.profileChangeRequest()
                changeRequest?.displayName = self.fullName
                changeRequest?.commitChanges()
                
                FireController.db.child(self.user.path).updateChildValues([
                    "modified_at": FIRServerValue.timestamp(),
                    "profile/first_name": emptyToNull(self.firstNameField.text),
                    "profile/full_name": nilToNull(self.fullName)
                    ])
            }
        }
        else if textField == self.lastNameField {
            if emptyToNil(self.lastNameField.text) != self.user.profile?.lastName {
                let changeRequest = FIRAuth.auth()?.currentUser?.profileChangeRequest()
                changeRequest?.displayName = self.fullName
                changeRequest?.commitChanges()
                
                FireController.db.child(self.user.path).updateChildValues([
                    "modified_at": FIRServerValue.timestamp(),
                    "profile/last_name": emptyToNull(self.lastNameField.text),
                    "profile/full_name": nilToNull(self.fullName)
                    ])
            }
        }
        else if textField == self.phoneField {
            if emptyToNil(self.phoneField.text) != self.user.profile?.phone {
                FireController.db.child(self.user.path).updateChildValues([
                    "modified_at": FIRServerValue.timestamp(),
                    "profile/phone": emptyToNull(self.phoneField.text)
                    ])
            }
        }
        else if textField == self.skypeField {
            if emptyToNil(self.skypeField.text) != self.user.profile?.skype {
                FireController.db.child(self.user.path).updateChildValues([
                    "modified_at": FIRServerValue.timestamp(),
                    "profile/skype": emptyToNull(self.skypeField.text)
                    ])
            }
        }
    }
    
    override func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        switch textField {
        case firstNameField:
            lastNameField.becomeFirstResponder()
        case lastNameField:
            phoneField.becomeFirstResponder()
        case phoneField:
            skypeField.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
    
    /*--------------------------------------------------------------------------------------------
     * Notifications
     *--------------------------------------------------------------------------------------------*/
    
    override func photoDidChange(sender: NSNotification) {
        super.photoDidChange(sender: sender)
        
        let image = self.photoEditView.imageButton.image
        let path = self.user.path
        var photoMap: [String: Any]?
        photoMap = postPhoto(image: image!, progress: self.photoEditView.progressBlock, next: { error in
            if error == nil {
                photoMap!["uploading"] = NSNull()
                FireController.db.child(path).updateChildValues(["profile/photo": photoMap!])
            }
        })
        
        FireController.db.child(path).updateChildValues([
            "modified_at": FIRServerValue.timestamp(),
            "profile/photo": photoMap!
        ])
        
        let photoUrl = PhotoUtils.url(prefix: photoMap!["filename"] as! String?, source: photoMap!["source"] as! String?, category: SizeCategory.profile)
        let changeRequest = FIRAuth.auth()?.currentUser?.profileChangeRequest()
        changeRequest?.photoURL = photoUrl
        changeRequest?.commitChanges()
    }
    
    override func photoRemoved(sender: NSNotification) {
        super.photoRemoved(sender: sender)
        
        let changeRequest = FIRAuth.auth()?.currentUser?.profileChangeRequest()
        changeRequest?.photoURL = nil
        changeRequest?.commitChanges()
        
        FireController.db.child(self.user.path).updateChildValues([
            "modified_at": FIRServerValue.timestamp(),
            "profile/photo": NSNull()
        ])
    }

    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/

    override func initialize() {
        super.initialize()

        Reporting.screen("ProfileEdit")

        self.message.text = "Profile"
        self.message.textColor = Theme.colorTextTitle
        self.message.numberOfLines = 0
        self.message.textAlignment = .center

        self.photoEditView.photoSchema = Schema.ENTITY_USER
        self.photoEditView.setHostController(controller: self)

        self.firstNameField.placeholder = "First name"
        self.firstNameField.font = Theme.fontTextDisplay
        self.firstNameField.delegate = self
        self.firstNameField.autocapitalizationType = .words
        self.firstNameField.autocorrectionType = .no
        self.firstNameField.keyboardType = .default
        self.firstNameField.returnKeyType = .next

        self.lastNameField.placeholder = "Last name"
        self.lastNameField.font = Theme.fontTextDisplay
        self.lastNameField.delegate = self
        self.lastNameField.autocapitalizationType = .words
        self.lastNameField.autocorrectionType = .no
        self.lastNameField.keyboardType = .default
        self.lastNameField.returnKeyType = .next

        self.phoneField.placeholder = "Phone number"
        self.phoneField.font = Theme.fontTextDisplay
        self.phoneField.delegate = self
        self.phoneField.autocapitalizationType = .none
        self.phoneField.autocorrectionType = .no
        self.phoneField.keyboardType = .phonePad
        self.phoneField.returnKeyType = .done
        
        self.skypeField.placeholder = "Skype username"
        self.skypeField.font = Theme.fontTextDisplay
        self.skypeField.delegate = self
        self.skypeField.autocapitalizationType = .none
        self.skypeField.autocorrectionType = .no
        self.skypeField.keyboardType = .default
        self.skypeField.returnKeyType = .done

        self.accountButton.setTitle("Account settings".uppercased(), for: .normal)
        self.accountButton.addTarget(self, action: #selector(accountAction(sender:)), for: .touchUpInside)
        
        self.contentHolder.addSubview(self.message)
        self.contentHolder.addSubview(self.photoEditView)
        self.contentHolder.addSubview(self.firstNameField)
        self.contentHolder.addSubview(self.lastNameField)
        self.contentHolder.addSubview(self.phoneField)
        self.contentHolder.addSubview(self.skypeField)
        self.contentHolder.addSubview(self.accountButton)
        
        if self.presented {
            let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(closeAction(sender:)))
            self.navigationItem.rightBarButtonItems = [doneButton]
        }        
        
        NotificationCenter.default.addObserver(self, selector: #selector(photoDidChange(sender:)), name: NSNotification.Name(rawValue: Events.PhotoDidChange), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(photoRemoved(sender:)), name: NSNotification.Name(rawValue: Events.PhotoRemoved), object: nil)
    }

    func bind() {
        
        self.photoEditView.configureTo(photoMode: self.user.profile?.photo != nil ? .Photo : .Placeholder)
        
        self.firstNameField.text = self.user.profile?.firstName
        self.lastNameField.text = self.user.profile?.lastName
        self.phoneField.text = self.user.profile?.phone
        self.skypeField.text = self.user.profile?.skype
        
        if let photo = self.user.profile?.photo, photo.uploading == nil {
            if let photoUrl = PhotoUtils.url(prefix: photo.filename, source: photo.source, category: SizeCategory.standard) {
                self.photoEditView.bind(url: photoUrl, fallbackUrl: PhotoUtils.fallbackUrl(prefix: photo.filename!))
            }
        }
    }
}
