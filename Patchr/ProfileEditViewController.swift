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

    var message = AirLabelTitle()
    var photoEditView = PhotoEditView()
    var firstNameField = AirTextField()
    var lastNameField = AirTextField()
    var phoneField = AirPhoneField()
    var accountButton = AirButton()
    var doneButton: UIBarButtonItem!

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
        let userQuery = UserQuery(userId: userId, groupId: nil)
        userQuery.once(with: { [weak self] error, user in
            if (user != nil) {
                self?.user = user
                self?.bind()
            }
        })
    }
    
    override func viewWillLayoutSubviews() {

        let messageSize = self.message.sizeThatFits(CGSize(width: 288, height: CGFloat.greatestFiniteMagnitude))
        self.message.anchorTopCenter(withTopPadding: 0, width: 288, height: messageSize.height)
        self.photoEditView.alignUnder(self.message, matchingCenterWithTopPadding: 16, width: 150, height: 150)
        self.firstNameField.alignUnder(self.photoEditView, matchingCenterWithTopPadding: 16, width: 288, height: 48)
        self.lastNameField.alignUnder(self.firstNameField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        self.phoneField.alignUnder(self.lastNameField, matchingCenterWithTopPadding: 8, width: 288, height: 48)

        self.accountButton.alignUnder(self.phoneField, matchingCenterWithTopPadding: 12, width: 288, height: 48)

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
        if !isDirty() {
            self.close(animated: true)
            return
        }
        DeleteConfirmationAlert(
            title: "Do you want to discard your editing changes?",
            actionTitle: "Discard", cancelTitle: "Cancel", delegate: self) {
                doIt in
                if doIt {
                    self.close(animated: true)
                }
        }
    }
    
    func doneAction(sender: AnyObject?) {
        update()
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        self.doneButton.isEnabled = isDirty()
    }
    
    override func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case firstNameField:
            lastNameField.becomeFirstResponder()
        case lastNameField:
            phoneField.becomeFirstResponder()
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
        self.doneButton.isEnabled = isDirty()
    }
    
    override func photoRemoved(sender: NSNotification) {
        super.photoRemoved(sender: sender)
        self.doneButton.isEnabled = isDirty()
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
        self.photoEditView.setHost(controller: self, view: self.photoEditView)

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
        
        self.accountButton.setTitle("Account settings".uppercased(), for: .normal)
        self.accountButton.addTarget(self, action: #selector(accountAction(sender:)), for: .touchUpInside)
        
        self.contentHolder.addSubview(self.message)
        self.contentHolder.addSubview(self.photoEditView)
        self.contentHolder.addSubview(self.firstNameField)
        self.contentHolder.addSubview(self.lastNameField)
        self.contentHolder.addSubview(self.phoneField)
        self.contentHolder.addSubview(self.accountButton)
        
        if self.presented {
            let cancelButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
            self.doneButton = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
            self.doneButton.isEnabled = false
            self.navigationItem.leftBarButtonItems = [cancelButton]
            self.navigationItem.rightBarButtonItems = [doneButton]
        }
        
        self.firstNameField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.lastNameField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.phoneField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        NotificationCenter.default.addObserver(self, selector: #selector(photoDidChange(sender:)), name: NSNotification.Name(rawValue: Events.PhotoDidChange), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(photoRemoved(sender:)), name: NSNotification.Name(rawValue: Events.PhotoRemoved), object: nil)
    }

    func bind() {
        
        self.photoEditView.configureTo(photoMode: self.user.profile?.photo != nil ? .Photo : .Placeholder)
        
        self.firstNameField.text = self.user.profile?.firstName
        self.lastNameField.text = self.user.profile?.lastName
        self.phoneField.text = self.user.profile?.phone
        
        if let photo = self.user.profile?.photo {
            if photo.uploading != nil {
                self.photoEditView.bind(url: URL(string: photo.cacheKey)!, fallbackUrl: nil, uploading: true)
            }
            else if let photoUrl = ImageUtils.url(prefix: photo.filename, source: photo.source, category: SizeCategory.standard) {
                self.photoEditView.bind(url: photoUrl, fallbackUrl: ImageUtils.fallbackUrl(prefix: photo.filename!))
            }
        }
    }
    
    func update() {
        var updates = [String: Any]()
        
        if emptyToNil(self.firstNameField.text) != self.user.profile?.firstName {
            let changeRequest = FIRAuth.auth()?.currentUser?.profileChangeRequest()
            changeRequest?.displayName = self.fullName
            changeRequest?.commitChanges()
            updates["profile/first_name"] = emptyToNull(self.firstNameField.text)
            updates["profile/full_name"] = nilToNull(self.fullName)
        }
        
        if emptyToNil(self.lastNameField.text) != self.user.profile?.lastName {
            let changeRequest = FIRAuth.auth()?.currentUser?.profileChangeRequest()
            changeRequest?.displayName = self.fullName
            changeRequest?.commitChanges()
            updates["profile/last_name"] = emptyToNull(self.lastNameField.text)
            updates["profile/full_name"] = nilToNull(self.fullName)
        }
        
        if emptyToNil(self.phoneField.text) != self.user.profile?.phone {
            updates["profile/phone"] = emptyToNull(self.phoneField.text)
        }
        
        if self.photoEditView.photoDirty {
            if self.photoEditView.photoActive {
                let image = self.photoEditView.imageButton.image
                let asset = self.photoEditView.imageButton.asset
                let path = self.user.path
                var photoMap: [String: Any]?
                photoMap = postPhoto(image: image!, asset: asset, progress: self.photoEditView.progressBlock, next: { error in
                    if error == nil {
                        photoMap!["uploading"] = NSNull()
                        FireController.db.child(path).updateChildValues(["profile/photo": photoMap!])
                    }
                })
                
                updates["profile/photo"] = photoMap!
                let photoUrl = ImageUtils.url(prefix: photoMap!["filename"] as! String?, source: photoMap!["source"] as! String?, category: SizeCategory.profile)
                let changeRequest = FIRAuth.auth()?.currentUser?.profileChangeRequest()
                changeRequest?.photoURL = photoUrl
                changeRequest?.commitChanges()
            }
            else {
                let changeRequest = FIRAuth.auth()?.currentUser?.profileChangeRequest()
                changeRequest?.photoURL = nil
                changeRequest?.commitChanges()
                updates["profile/photo"] = NSNull()
            }
        }

        if updates.keys.count > 0 {
            updates["modified_at"] = FIRServerValue.timestamp()
            FireController.db.child(self.user.path).updateChildValues(updates)
        }
        self.close(animated: true)
    }
    
    func isDirty() -> Bool {
        
        if !stringsAreEqual(string1: self.firstNameField.text, string2: self.user.profile?.firstName) {
            return true
        }
        if !stringsAreEqual(string1: self.lastNameField.text, string2: self.user.profile?.lastName) {
            return true
        }
        if !stringsAreEqual(string1: self.phoneField.text, string2: self.user.profile?.phone) {
            return true
        }
        if self.photoEditView.photoDirty {
            return true
        }
        return false
    }
}
