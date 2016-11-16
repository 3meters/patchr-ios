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
    var message = AirLabelDisplay()
    var photoEditView = PhotoEditView()
    var nameField = AirTextField()
    var purposeField = AirTextView()
    var visibilityGroup = AirRuleView()
    var visibilitySwitch = UISwitch()
    var visibilityLabel	= AirLabelDisplay()
    var visibilityValue = "public"
    
    var doneButton = AirFeaturedButton()

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
        super.viewWillLayoutSubviews()

        let bannerSize = self.banner.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        let messageSize = self.message.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        let descriptionSize = self.purposeField.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))

        self.visibilityLabel.sizeToFit()

        self.banner.anchorTopCenter(withTopPadding: 0, width: 288, height: bannerSize.height)
        self.message.alignUnder(self.banner, matchingCenterWithTopPadding: 8, width: 288, height: messageSize.height)
        self.nameField.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        self.purposeField.alignUnder(self.nameField, matchingCenterWithTopPadding: 8, width: 288, height: max(48, descriptionSize.height))
        self.photoEditView.alignUnder(self.purposeField, matchingCenterWithTopPadding: 16, width: 288, height: 288 * 0.56)
        self.visibilityGroup.alignUnder(self.photoEditView, matchingCenterWithTopPadding: 8, width: 288, height: 48)

        self.visibilityLabel.anchorCenterLeft(withLeftPadding: 0, width: 144, height: self.visibilityLabel.height())
        self.visibilitySwitch.anchorCenterRight(withRightPadding: 0, width: self.visibilitySwitch.width(), height: self.visibilitySwitch.height())

        self.contentHolder.resizeToFitSubviews()
        self.scrollView.contentSize = CGSize(width:self.contentHolder.width(), height:self.contentHolder.height() + CGFloat(32))
        self.contentHolder.anchorTopCenterFillingWidth(withLeftAndRightPadding: 16, topPadding: 16, height: self.contentHolder.height())
    }

    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/

    func doneAction(sender: AnyObject){
        
        if self.mode == .insert {
            guard isValid() else { return }
            guard !self.processing else { return }
            post()
        }
        else {
            self.performBack(animated: true)
        }
    }

    func cancelAction(sender: AnyObject){

        if !isDirty() {
            self.performBack(animated: true)
            return
        }

        DeleteConfirmationAlert(
            title: "Do you want to discard your editing changes?",
            actionTitle: "Discard", cancelTitle: "Cancel", delegate: self) {
                doIt in
                if doIt {
                    self.performBack(animated: true)
                }
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
    
    override func textViewDidEndEditing(_ textView: UITextView) {
        super.textViewDidEndEditing(textView)
        if self.mode == .update {
            if textView == self.purposeField {
                FireController.db.child(self.channel.path).updateChildValues([
                    "modified_at": FIRServerValue.timestamp(),
                    "purpose": self.purposeField.text!
                    ])
            }
        }
    }
    
    override func textFieldDidEndEditing(_ textField: UITextField) {
        super.textFieldDidEndEditing(textField)
        
        if self.mode == .update {
            if textField == self.nameField {
                FireController.db.child(self.channel.path).updateChildValues([
                    "modified_at": FIRServerValue.timestamp(),
                    "name": self.nameField.text!
                ])
            }
        }
    }

    func visibilityChanged(sender: AnyObject) {
        if let switchView = sender as? UISwitch {
            self.visibilityValue = (switchView.isOn) ? "private" : "public"
            if self.mode == .update {
                FireController.db.child(self.channel.path).updateChildValues([
                    "modified_at": FIRServerValue.timestamp(),
                    "visibility": (switchView.isOn) ? "private" : "public"
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
            let image = self.photoEditView.imageButton.image(for: .normal)
            let path = self.channel.path
            var photoMap: [String: Any]?
            photoMap = postPhoto(image: image!, progress: self.photoEditView.progressBlock, next: { error in
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

        self.message.numberOfLines = 0
        self.message.textAlignment = .center

        self.photoEditView.photoSchema = Schema.ENTITY_PATCH
        self.photoEditView.setHostController(controller: self)
        self.photoEditView.configureTo(photoMode: .Placeholder)

        self.nameField.placeholder = "Channel Name"
        self.nameField.delegate = self
        self.nameField.autocapitalizationType = .none
        self.nameField.autocorrectionType = .no
        self.nameField.keyboardType = UIKeyboardType.default
        self.nameField.returnKeyType = UIReturnKeyType.next

        self.purposeField.placeholder = "Tell people what this channel is for"
        self.purposeField.autocapitalizationType = .sentences
        self.purposeField.autocorrectionType = .yes
        self.purposeField.initialize()
        self.purposeField.delegate = self

        self.visibilityLabel.text = "Private Channel"
        self.visibilitySwitch.isOn = false
        self.visibilitySwitch.addTarget(self, action: #selector(visibilityChanged(sender:)), for: .touchUpInside)

        self.visibilityGroup.addSubview(self.visibilityLabel)
        self.visibilityGroup.addSubview(self.visibilitySwitch)

        self.contentHolder.addSubview(self.banner)
        self.contentHolder.addSubview(self.message)
        self.contentHolder.addSubview(self.nameField)
        self.contentHolder.addSubview(self.purposeField)
        self.contentHolder.addSubview(self.photoEditView)
        self.contentHolder.addSubview(self.visibilityGroup)

        if self.mode == .insert {

            Reporting.screen("ChannelNew")
            self.banner.text = "New Channel"

            /* Navigation bar buttons */
            let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(cancelAction(sender:)))
            let createButton = UIBarButtonItem(title: "Create", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
            self.navigationItem.leftBarButtonItems = [cancelButton]
            self.navigationItem.rightBarButtonItems = [createButton]
        }
        else if self.mode == .update  {

            Reporting.screen("ChannelEdit")
            self.banner.text = "Edit Channel"
            self.doneButton.isHidden = true

            /* Navigation bar buttons */
            let deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.trash, target: self, action: #selector(deleteAction(sender:)))
            let closeButton = UIBarButtonItem(title: "Close", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
            self.navigationItem.leftBarButtonItems = [closeButton]
            self.navigationItem.rightBarButtonItems = [deleteButton]
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(photoDidChange(sender:)), name: NSNotification.Name(rawValue: Events.PhotoDidChange), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(photoRemoved(sender:)), name: NSNotification.Name(rawValue: Events.PhotoRemoved), object: nil)
    }

    func bind() {
        
        /* Only called once: onViewLoad */

        self.nameField.text = self.channel.name
        self.purposeField.text = self.channel.purpose
        
        if let photo = self.channel.photo, !photo.uploading {
            if let photoUrl = PhotoUtils.url(prefix: photo.filename, source: photo.source, category: SizeCategory.standard) {
                self.photoEditView.configureTo(photoMode: .Photo)
                self.photoEditView.bind(url: photoUrl)
            }
        }

        /* Visibility */
        self.visibilitySwitch.isOn = (self.channel.visibility == "private")
        self.visibilityValue = (self.channel.visibility)!
    }

    func post() {
        
        self.processing = true
        
        let channelId = "ch-\(Utils.genRandomId())"
        let groupId = self.inputGroupId!
        let refChannel = FireController.db.child("group-channels/\(groupId)/\(channelId)")
        
        var photoMap: [String: Any]?
        if let image = self.photoEditView.imageButton.image(for: .normal) {
            photoMap = postPhoto(image: image, next: { error in
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
            StateController.instance.setChannelId(channelId: channelId, next: nil) // We know it's good
            MainController.instance.showChannel(groupId: groupId, channelId: channelId)
            self.performBack(animated: true)
        }
    }

    func delete() {
        self.performBack(animated: true)
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
            Alert(title: "Enter a name for the channel.", message: nil, cancelButtonTitle: "OK")
            return false
        }

        return true
    }
    
    enum Mode: Int {
        case insert
        case update
    }
}
