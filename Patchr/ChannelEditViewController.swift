//
//  RegistrationTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-24.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AWSS3
import MBProgressHUD
import Facade
import Firebase

class ChannelEditViewController: BaseEditViewController {

    var inputGroupId: String!
    var inputChannelId: String!
    var channel: FireChannel!

    var banner = AirLabelTitle()
    var photoEditView = PhotoEditView()
    var nameField = FloatTextField(frame: CGRect.zero)
    var purposeField = AirTextView()
    var visibilityGroup = AirRuleView()
    var visibilitySwitch = UISwitch()
    var visibilityLabel	= AirLabelDisplay()
    var visibilityValue = "open"
    var usersButton = AirButton()

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        
        if self.mode == .update {
            let channelQuery = ChannelQuery(groupId: self.inputGroupId, channelId: self.inputChannelId, userId: nil)
            channelQuery.once(with: { channel in
                guard channel != nil else {
                    assertionFailure("Channel not found or no longer exists")
                    return
                }
                self.channel = channel
                self.bind()
            })
        }
    }

    override func viewWillLayoutSubviews() {
        /*
         * Triggers
         * - addSubview called on self.view
         * - setting frame on self.view if size is different
         * - scrolling when self.view is a scrollview
         */
        let bannerSize = self.banner.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        let purposeSize = self.purposeField.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        
        self.visibilityLabel.sizeToFit()

        self.banner.anchorTopCenter(withTopPadding: 0, width: 288, height: bannerSize.height)
        self.usersButton.alignUnder(self.banner, matchingCenterWithTopPadding: 24, width: 288, height: self.usersButton.isHidden ? 0 : 48)
        self.nameField.alignUnder(self.usersButton, matchingCenterWithTopPadding: 16, width: 288, height: 48)
        self.purposeField.alignUnder(self.nameField, matchingCenterWithTopPadding: 16, width: 288, height: max(48, purposeSize.height))
        self.photoEditView.alignUnder(self.purposeField, matchingCenterWithTopPadding: 16, width: 288, height: 288 * 0.56)
        
        self.visibilityGroup.alignUnder(self.photoEditView, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        self.visibilityLabel.anchorCenterLeft(withLeftPadding: 0, width: 144, height: self.visibilityLabel.height())
        self.visibilitySwitch.anchorCenterRight(withRightPadding: 0, width: self.visibilitySwitch.width(), height: self.visibilitySwitch.height())

        super.viewWillLayoutSubviews()
    }

    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/

    func closeAction(sender: AnyObject){
        
        if self.mode == .insert {
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
        else {
            self.close(animated: true)
        }
    }
    
    func deleteAction(sender: AnyObject) {
        
        guard !self.processing else { return }
        
        DeleteConfirmationAlert(
            title: "Confirm Delete",
            message: "Are you sure you want to delete this?",
            actionTitle: "Delete", cancelTitle: "Cancel", delegate: self) {
                doIt in
                if doIt {
                    self.delete()
                }
        }
    }
    
    func manageUsersAction(sender: AnyObject?) {
        let controller = MemberListController()
        controller.scope = .channel
        controller.target = .channel
        controller.manage = true
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func doneAction(sender: AnyObject){
        
        if self.mode == .insert {
            guard isValid() else { return }
            guard !self.processing else { return }
            post()
        }
        else {
            self.activeTextField?.resignFirstResponder()
            if isValid() {
                self.close(animated: true)
            }
        }
    }
    
    override func textViewDidEndEditing(_ textView: UITextView) {
        super.textViewDidEndEditing(textView)
        if self.mode == .update {
            if textView == self.purposeField {
                if emptyToNil(self.purposeField.text) != self.channel!.purpose {
                    FireController.db.child(self.channel.path).updateChildValues([
                        "modified_at": FIRServerValue.timestamp(),
                        "purpose": emptyToNull(self.purposeField.text)
                    ])
                }
            }
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.view.setNeedsLayout()
    }
    
    override func textFieldDidEndEditing(_ textField: UITextField) {
        super.textFieldDidEndEditing(textField)
        
        if self.mode == .update {
            if textField == self.nameField {
                if isValid() {
                    FireController.db.child(self.channel.path).updateChildValues([
                        "modified_at": FIRServerValue.timestamp(),
                        "name": emptyToNull(self.nameField.text)
                    ])
                }
            }
        }
    }
    
    func visibilityChanged(sender: AnyObject) {
        if let switchView = sender as? UISwitch {
            self.visibilityValue = (switchView.isOn) ? "private" : "open"
            self.banner.text = (self.visibilityValue == "private") ? "New Private Channel" : "New Channel"
            self.view.setNeedsLayout()
            
            if self.mode == .update {
                FireController.db.child(self.channel.path).updateChildValues([
                    "modified_at": FIRServerValue.timestamp(),
                    "visibility": (switchView.isOn) ? "private" : "open"
                ])
            }
        }
    }
    
    /*--------------------------------------------------------------------------------------------
     * Notifications
     *--------------------------------------------------------------------------------------------*/
    
    override func photoDidChange(sender: NSNotification) {
        super.photoDidChange(sender: sender)
        
        if self.mode == .update {
            let image = self.photoEditView.imageButton.image
            let asset = self.photoEditView.imageButton.asset
            let path = self.channel.path
            var photoMap: [String: Any]?
            photoMap = postPhoto(image: image!, asset: asset, progress: self.photoEditView.progressBlock, next: { error in
                if error == nil {
                    photoMap!["uploading"] = NSNull()
                    FireController.db.child(path).updateChildValues(["photo": photoMap!])
                }
            })
            
            FireController.db.child(path).updateChildValues([
                "modified_at": FIRServerValue.timestamp(),
                "photo": photoMap!
            ])
        }
    }
    
    override func photoRemoved(sender: NSNotification) {
        super.photoRemoved(sender: sender)
        
        if self.mode == .update {
            FireController.db.child(self.channel.path).updateChildValues([
                "modified_at": FIRServerValue.timestamp(),
                "photo": NSNull()
            ])
        }
    }

    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/

    override func initialize() {
        super.initialize()

        self.banner.textColor = Theme.colorTextTitle
        self.banner.numberOfLines = 0
        self.banner.textAlignment = .center

        self.photoEditView.photoSchema = Schema.ENTITY_PATCH
        self.photoEditView.setHostController(controller: self)
        self.photoEditView.configureTo(photoMode: .Placeholder)

        self.nameField.placeholder = "Channel name"
        self.nameField.title = "Channel name (lower case)"
        self.nameField.setDelegate(delegate: self)
        self.nameField.autocapitalizationType = .none
        self.nameField.autocorrectionType = .no
        self.nameField.keyboardType = UIKeyboardType.default
        self.nameField.returnKeyType = UIReturnKeyType.next
        
        self.purposeField.placeholder = "Channel purpose (optional)"
        self.purposeField.placeholderLabel.numberOfLines = 0
        self.purposeField.autocapitalizationType = .sentences
        self.purposeField.autocorrectionType = .yes
        self.purposeField.initialize()
        self.purposeField.delegate = self

        self.visibilityLabel.text = "Private Channel"
        self.visibilitySwitch.isOn = false
        self.visibilitySwitch.addTarget(self, action: #selector(visibilityChanged(sender:)), for: .touchUpInside)
        
        self.usersButton.setTitle("Manage Channel Members".uppercased(), for: .normal)
        self.usersButton.imageRight = UIImageView(image: UIImage(named: "imgArrowRightLight"))
        self.usersButton.imageRight?.bounds.size = CGSize(width: 10, height: 14)
        self.usersButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 36)
        self.usersButton.addTarget(self, action: #selector(manageUsersAction(sender:)), for: .touchUpInside)

        self.visibilityGroup.addSubview(self.visibilityLabel)
        self.visibilityGroup.addSubview(self.visibilitySwitch)

        self.contentHolder.addSubview(self.banner)
        self.contentHolder.addSubview(self.nameField)
        self.contentHolder.addSubview(self.purposeField)
        self.contentHolder.addSubview(self.photoEditView)
        self.contentHolder.addSubview(self.visibilityGroup)
        self.contentHolder.addSubview(self.usersButton)

        if self.mode == .insert {

            Reporting.screen("ChannelNew")
            self.banner.text = "New Channel"
            self.usersButton.isHidden = true

            /* Navigation bar buttons */
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
            let doneButton = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(doneAction(sender:)))
            self.navigationItem.leftBarButtonItems = [closeButton]
            self.navigationItem.rightBarButtonItems = [doneButton]
        }
        else if self.mode == .update  {

            Reporting.screen("ChannelEdit")
            self.banner.text = "Edit Channel"
            self.visibilityGroup.isHidden = true

            /* Navigation bar buttons */
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
            self.navigationItem.leftBarButtonItems = [closeButton]
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(photoDidChange(sender:)), name: NSNotification.Name(rawValue: Events.PhotoDidChange), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(photoRemoved(sender:)), name: NSNotification.Name(rawValue: Events.PhotoRemoved), object: nil)
    }

    func bind() {
        
        self.nameField.text = self.channel.name
        self.purposeField.text = self.channel.purpose
        
        if let photo = self.channel.photo {
            self.photoEditView.configureTo(photoMode: .Photo)
            if photo.uploading != nil {
                self.photoEditView.bind(url: URL(string: photo.cacheKey)!, fallbackUrl: nil, uploading: true)
            }
            else if let photoUrl = ImageUtils.url(prefix: photo.filename, source: photo.source, category: SizeCategory.standard) {
                self.photoEditView.bind(url: photoUrl, fallbackUrl: ImageUtils.fallbackUrl(prefix: photo.filename!))
            }
        }
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
        let deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.trash, target: self, action: #selector(deleteAction(sender:)))
        if self.channel.general! {
            self.navigationItem.setRightBarButtonItems([doneButton], animated: true)
        }
        else {
            self.navigationItem.setRightBarButtonItems([doneButton, deleteButton], animated: true)
        }

        /* Visibility */
        self.banner.text = (self.channel.visibility == "private") ? "Private Channel Settings" : "Channel Settings"
        self.view.setNeedsLayout()
    }

    func post() {
        
        self.processing = true
        
        let groupId = self.inputGroupId!
        let channelName = self.nameField.text!
        
        FireController.instance.channelNameExists(groupId: groupId, channelName: channelName, next: { exists in
            if exists {
                self.progress?.hide(true)
                self.processing = false
                self.nameField.errorMessage = "Choose another channel name"
            }
            else {
                let channelId = "ch-\(Utils.genRandomId())"
                let refChannel = FireController.db.child("group-channels/\(groupId)/\(channelId)")
                
                var photoMap: [String: Any]?
                if let image = self.photoEditView.imageButton.image {
                    let asset = self.photoEditView.imageButton.asset
                    photoMap = self.postPhoto(image: image, asset: asset, next: { error in
                        if error != nil {
                            photoMap!["uploading"] = NSNull()
                            refChannel.child("photo").setValue(photoMap!)
                        }
                    })
                }
                
                let timestamp = Utils.now() + (FireController.instance.serverOffset ?? 0)
                
                var channelMap: [String: Any] = [:]
                channelMap["group"] = self.inputGroupId!
                channelMap["type"] = "channel"
                channelMap["general"] = false
                channelMap["archived"] = false
                channelMap["visibility"] = self.visibilityValue
                channelMap["created_at"] = Int(timestamp)
                channelMap["created_by"] = UserController.instance.userId!
                
                if !self.purposeField.text.isEmpty {
                    channelMap["purpose"] = self.purposeField.text
                }
                
                if !(self.nameField.text?.isEmpty)! {
                    channelMap["name"] = self.nameField.text
                }
                
                if photoMap != nil {
                    channelMap["photo"] = photoMap!
                }
                
                FireController.instance.addChannelToGroup(channelId: channelId, channelMap: channelMap, groupId: groupId) { result in
                    let controller = MemberPickerController()
                    controller.flow = .internalCreate
                    controller.inputChannelId = channelId
                    self.navigationController?.setViewControllers([controller], animated: true)
                }
            }
        })
    }

    func delete() {
        self.close(animated: true)
        FireController.instance.delete(channelId: self.channel.id!, groupId: self.channel.group!)
    }

    func isDirty() -> Bool {

        if !self.nameField.text!.isEmpty {
            return true
        }
        if !self.purposeField.text!.isEmpty {
            return true
        }
        if self.photoEditView.photoDirty {
            return true
        }
        return false
    }

    func isValid() -> Bool {
        
        if self.nameField.isEmpty {
            self.nameField.errorMessage = "Name your channel"
            return false
        }
        
        let channelName = nameField.text!
        let characterSet: NSCharacterSet = NSCharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_-")
        if channelName.rangeOfCharacter(from: characterSet.inverted) != nil {
            self.nameField.errorMessage = "Channel name must be lower case and cannot contain spaces or periods."
            return false
        }
        
        if (nameField.text!.utf16.count > 50) {
            self.nameField.errorMessage = "Channel name must be 50 characters or less."
            return false
        }

        return true
    }
    
    enum Mode: Int {
        case insert
        case update
    }
}
