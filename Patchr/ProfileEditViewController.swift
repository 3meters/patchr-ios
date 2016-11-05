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

    var ref: FIRDatabaseReference!
    var inputUser: FireUser!

    var message = AirLabelTitle()
    var photoEditView = PhotoEditView()
    var firstNameField = AirTextField()
    var lastNameField = AirTextField()
    var phoneField = AirPhoneField()
    var skypeField = AirTextField()
    var accountButton = AirButton()

    var fullName: String! {
        
        let firstName = self.firstNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastName = self.lastNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if firstName == nil || firstName!.isEmpty {
            if lastName == nil || lastName!.isEmpty {
                return ""
            }
            else {
                return lastName
            }
        }
        else if lastName == nil || lastName!.isEmpty {
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
        bind()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let messageSize = self.message.sizeThatFits(CGSize(width: 288, height: CGFloat.greatestFiniteMagnitude))
        self.message.anchorTopCenter(withTopPadding: 0, width: 288, height: messageSize.height)
        self.photoEditView.alignUnder(self.message, matchingCenterWithTopPadding: 16, width: 150, height: 150)
        self.firstNameField.alignUnder(self.photoEditView, matchingCenterWithTopPadding: 16, width: 288, height: 48)
        self.lastNameField.alignUnder(self.firstNameField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        self.phoneField.alignUnder(self.lastNameField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        self.skypeField.alignUnder(self.phoneField, matchingCenterWithTopPadding: 8, width: 288, height: 48)

        self.accountButton.alignUnder(self.skypeField, matchingCenterWithTopPadding: 12, width: 288, height: 48)

        self.contentHolder.resizeToFitSubviews()
        self.scrollView.contentSize = CGSize(width: self.contentHolder.frame.size.width, height: self.contentHolder.frame.size.height + CGFloat(32))
        self.contentHolder.anchorTopCenterFillingWidth(withLeftAndRightPadding: 16, topPadding: 24, height: self.contentHolder.frame.size.height)
    }

    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/
    
    func accountAction(sender: AnyObject) {
        let controller = AccountEditViewController()
        controller.inputUser = self.inputUser
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    override func textFieldDidEndEditing(_ textField: UITextField) {
        super.textFieldDidEndEditing(textField)
        
        if textField == self.firstNameField {
            self.ref.updateChildValues([
                "modified_at": FIRServerValue.timestamp(),
                "profile/first_name": self.firstNameField.text!,
                "profile/full_name": self.fullName
            ])
        }
        else if textField == self.lastNameField {
            self.ref.updateChildValues([
                "modified_at": FIRServerValue.timestamp(),
                "profile/last_name": self.lastNameField.text!,
                "profile/full_name": self.fullName
            ])
        }
        else if textField == self.phoneField {
            self.ref.updateChildValues([
                "modified_at": FIRServerValue.timestamp(),
                "profile/phone": self.phoneField.text!
                ])
        }
        else if textField == self.skypeField {
            self.ref.updateChildValues([
                "modified_at": FIRServerValue.timestamp(),
                "profile/skype": self.skypeField.text!
                ])
        }
    }
    
    override func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        switch textField {
        case firstNameField:
            lastNameField.becomeFirstResponder()
        case lastNameField:
            phoneField.becomeFirstResponder()
        case phoneField:
            self.doneAction(sender: textField)
        case skypeField:
            self.doneAction(sender: textField)
        default:
            textField.resignFirstResponder()
        }
        return true
    }
    
    func doneAction(sender: AnyObject?){
        cancelAction(sender: sender)
    }
    
    func cancelAction(sender: AnyObject?){
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Events.PhotoDidChange), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Events.PhotoRemoved), object: nil)
        
        if self.isModal {
            self.dismiss(animated: true, completion: nil)
        }
        else {
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }

    /*--------------------------------------------------------------------------------------------
     * Notifications
     *--------------------------------------------------------------------------------------------*/
    
    override func photoDidChange(sender: NSNotification) {
        super.photoDidChange(sender: sender)
        let image = self.photoEditView.imageButton.image(for: .normal)
        postPhoto(image: image)
    }
    
    override func photoRemoved(sender: NSNotification) {
        super.photoRemoved(sender: sender)
        self.ref.updateChildValues([
            "modified_at": FIRServerValue.timestamp(),
            "profile/photo": NSNull()
        ]) { (err, ref) in
            if err != nil {
                UIShared.Toast(message: "Network error")
            }
        }
    }

    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/

    override func initialize() {
        super.initialize()

        Reporting.screen("ProfileEdit")

        self.ref = FIRDatabase.database().reference().child("users/\(self.inputUser.id!)")

        self.message.text = "Profile"
        self.message.textColor = Theme.colorTextTitle
        self.message.numberOfLines = 0
        self.message.textAlignment = .center

        self.photoEditView.photoSchema = Schema.ENTITY_USER
        self.photoEditView.setHostController(controller: self)
        self.photoEditView.configureTo(photoMode: self.inputUser.profile?.photo != nil ? .Photo : .Placeholder)

        self.firstNameField.placeholder = "First name"
        self.firstNameField.font = Theme.fontTextDisplay
        self.firstNameField.floatingLabelActiveTextColor = Colors.accentColorTextLight
        self.firstNameField.floatingLabelFont = Theme.fontComment
        self.firstNameField.floatingLabelTextColor = Theme.colorTextPlaceholder
        self.firstNameField.delegate = self
        self.firstNameField.autocapitalizationType = .words
        self.firstNameField.autocorrectionType = .no
        self.firstNameField.keyboardType = .default
        self.firstNameField.returnKeyType = .next

        self.lastNameField.placeholder = "Last name"
        self.lastNameField.font = Theme.fontTextDisplay
        self.lastNameField.floatingLabelActiveTextColor = Colors.accentColorTextLight
        self.lastNameField.floatingLabelFont = Theme.fontComment
        self.lastNameField.floatingLabelTextColor = Theme.colorTextPlaceholder
        self.lastNameField.delegate = self
        self.lastNameField.autocapitalizationType = .words
        self.lastNameField.autocorrectionType = .no
        self.lastNameField.keyboardType = .default
        self.lastNameField.returnKeyType = .next

        self.phoneField.placeholder = "Phone number"
        self.phoneField.font = Theme.fontTextDisplay
        self.phoneField.floatingLabelActiveTextColor = Colors.accentColorTextLight
        self.phoneField.floatingLabelFont = Theme.fontComment
        self.phoneField.floatingLabelTextColor = Theme.colorTextPlaceholder
        self.phoneField.delegate = self
        self.phoneField.autocapitalizationType = .none
        self.phoneField.autocorrectionType = .no
        self.phoneField.keyboardType = .phonePad
        self.phoneField.returnKeyType = .done
        
        self.skypeField.placeholder = "Skype username"
        self.skypeField.font = Theme.fontTextDisplay
        self.skypeField.floatingLabelActiveTextColor = Colors.accentColorTextLight
        self.skypeField.floatingLabelFont = Theme.fontComment
        self.skypeField.floatingLabelTextColor = Theme.colorTextPlaceholder
        self.skypeField.delegate = self
        self.skypeField.autocapitalizationType = .none
        self.skypeField.autocorrectionType = .no
        self.skypeField.keyboardType = .default
        self.skypeField.returnKeyType = .done

        self.accountButton.setTitle("Account", for: .normal)
        self.accountButton.addTarget(self, action: #selector(accountAction(sender:)), for: .touchUpInside)
        
        self.contentHolder.addSubview(self.message)
        self.contentHolder.addSubview(self.photoEditView)
        self.contentHolder.addSubview(self.firstNameField)
        self.contentHolder.addSubview(self.lastNameField)
        self.contentHolder.addSubview(self.phoneField)
        self.contentHolder.addSubview(self.skypeField)
        self.contentHolder.addSubview(self.accountButton)
        
        NotificationCenter.default.addObserver(self, selector: #selector(photoDidChange(sender:)), name: NSNotification.Name(rawValue: Events.PhotoDidChange), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(photoRemoved(sender:)), name: NSNotification.Name(rawValue: Events.PhotoRemoved), object: nil)
    }

    func bind() {
        
        self.firstNameField.text = self.inputUser.profile?.firstName
        self.lastNameField.text = self.inputUser.profile?.lastName
        self.phoneField.text = self.inputUser.profile?.phone
        self.skypeField.text = self.inputUser.profile?.skype
        
        if let photo = self.inputUser.profile?.photo {
            if let photoUrl = PhotoUtils.url(prefix: photo.filename, source: photo.source, category: SizeCategory.standard) {
                self.photoEditView.bind(url: photoUrl)
            }
        }
    }
    
    func postPhoto(image: UIImage?) {
        
        guard image != nil else {
            Log.w("Cannot post image that is nil")
            return
        }
        
        /* Ensure image is resized/rotated before upload */
        let preparedImage = Utils.prepareImage(image: image!)
        
        /* Generate image key */
        let imageKey = "\(Utils.genImageKey()).jpg"
        
        /* Upload */
        DispatchQueue.global().async {
            S3.sharedService.upload(
                image: preparedImage,
                imageKey: imageKey,
                progress: self.photoEditView.progressBlock,
                completionHandler: { task, error in
                    
                if let error = error {
                    Log.w("Image upload error: \(error.localizedDescription)")
                }
                else {
                    let photo = [
                        "width": Int(preparedImage.size.width), // width/height are in points...should be pixels?
                        "height": Int(preparedImage.size.height),
                        "source": S3.sharedService.imageSource,
                        "filename": imageKey
                        ] as [String: Any]
                    
                    self.ref.updateChildValues([
                        "modified_at": FIRServerValue.timestamp(),
                        "profile/photo": photo
                        ])
                }
            })
        }
    }
    
    func progressWasCancelled(sender: AnyObject) {
        if let gesture = sender as? UIGestureRecognizer, let hud = gesture.view as? MBProgressHUD {
            hud.animationType = MBProgressHUDAnimation.zoomIn
            hud.hide(true)
            let _ = self.imageUploadRequest?.cancel() // Should do nothing if upload already complete or isn't any
        }
    }
}
