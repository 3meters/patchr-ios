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
    var channelQuery: ChannelQuery!

    var banner = AirLabelTitle()
    var photoEditView = PhotoEditView()
    var nameField = FloatTextField(frame: CGRect.zero)
    var purposeField = AirTextView()
    var visibilityGroup = AirRuleView()
    var visibilitySwitch = UISwitch()
    var visibilityLabel	= AirLabelDisplay()
    var visibilityComment = AirLabelDisplay()
    var visibilityValue = "open"
    var usersButton = AirButton()
    var doneButton: UIBarButtonItem!

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        
        if self.mode == .update {
            self.channelQuery = ChannelQuery(groupId: self.inputGroupId, channelId: self.inputChannelId, userId: nil)
            self.channelQuery.once(with: { [weak self] error, channel in
                guard let this = self else { return }
                guard channel != nil else {
                    assertionFailure("Channel not found or no longer exists")
                    return
                }
                this.channel = channel
                this.bind()
            })
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if self.mode == .insert {
            let _ = self.nameField.becomeFirstResponder()
        }
    }

    override func viewWillLayoutSubviews() {
        /*
         * Triggers
         * - addSubview called on self.view
         * - setting frame on self.view if size is different
         * - scrolling when self.view is a scrollview
         */
        let bannerSize = self.banner.sizeThatFits(CGSize(width: Config.contentWidth, height:CGFloat.greatestFiniteMagnitude))
        let purposeSize = self.purposeField.sizeThatFits(CGSize(width: Config.contentWidth, height:CGFloat.greatestFiniteMagnitude))

        self.banner.anchorTopCenter(withTopPadding: 0, width: Config.contentWidth, height: bannerSize.height)
        
        if self.usersButton.isHidden {
            self.usersButton.alignUnder(self.banner, matchingCenterWithTopPadding: 0, width: Config.contentWidth, height: 0)
        }
        else {
            self.usersButton.alignUnder(self.banner, matchingCenterWithTopPadding: 24, width: Config.contentWidth, height: 48)
        }
        
        self.nameField.alignUnder(self.usersButton, matchingCenterWithTopPadding: 8, width: Config.contentWidth, height: 48)
        
        if self.visibilityGroup.isHidden {
            self.visibilityGroup.alignUnder(self.nameField, matchingCenterWithTopPadding: 0, width: Config.contentWidth, height: 0)
        }
        else {
            self.visibilityLabel.sizeToFit()
            self.visibilityComment.sizeToFit()
            self.visibilityGroup.alignUnder(self.nameField, matchingCenterWithTopPadding: 8, width: Config.contentWidth, height: 48)
            self.visibilityLabel.anchorCenterLeft(withLeftPadding: 0, width: self.visibilityLabel.width(), height: self.visibilityLabel.height())
            self.visibilityComment.align(toTheRightOf: self.visibilityLabel, matchingBottomWithLeftPadding: 8, width: self.visibilityComment.width(), height: self.visibilityComment.height())
            self.visibilitySwitch.anchorCenterRight(withRightPadding: 0, width: self.visibilitySwitch.width(), height: self.visibilitySwitch.height())
        }
        
        self.photoEditView.alignUnder(self.visibilityGroup, matchingCenterWithTopPadding: 16, width: Config.contentWidth, height: Config.contentWidth * 0.56)
        self.purposeField.alignUnder(self.photoEditView, matchingCenterWithTopPadding: 16, width: Config.contentWidth, height: max(48, purposeSize.height))
        
        super.viewWillLayoutSubviews()
    }

    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/

    func closeAction(sender: AnyObject){
        
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
    
    func doneAction(sender: AnyObject){
        
        guard !self.processing else { return }
        
        if self.mode == .update {
            self.activeTextField?.resignFirstResponder()
            if isValid() {
                self.progress = AirProgress.showAdded(to: self.view.window!, animated: true)
                self.progress?.mode = MBProgressHUDMode.indeterminate
                self.progress?.styleAs(progressStyle: .activityWithText)
                self.progress?.minShowTime = 0.5
                self.progress?.labelText = "Updating..."
                self.progress?.removeFromSuperViewOnHide = true
                self.progress?.show(true)
                isValidChannelName() { valid in
                    if valid {
                        Reporting.track("update_channel")
                        self.post()
                    }
                    else {
                        self.progress?.hide(true)
                    }
                }
            }
        }
        else if self.mode == .insert {
            FireController.instance.isConnected() { connected in
                if connected == nil || !connected! {
                    let message = "Creating a channel requires a network connection."
                    self.alert(title: "Not connected", message: message, cancelButtonTitle: "OK")
                }
                else {
                    if self.isValid() {
                        self.progress = AirProgress.showAdded(to: self.view.window!, animated: true)
                        self.progress?.mode = MBProgressHUDMode.indeterminate
                        self.progress?.styleAs(progressStyle: .activityWithText)
                        self.progress?.minShowTime = 0.5
                        self.progress?.labelText = "Creating..."
                        self.progress?.removeFromSuperViewOnHide = true
                        self.progress?.show(true)
                        self.isValidChannelName() { valid in
                            if valid {
                                Reporting.track("create_channel")
                                self.post()
                            }
                            else {
                                self.progress?.hide(true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func deleteAction(sender: AnyObject) {
        
        guard !self.processing else { return }
        
        FireController.instance.isConnected() { connected in
            if connected == nil || !connected! {
                let message = "Deleting a channel requires a network connection."
                self.alert(title: "Not connected", message: message, cancelButtonTitle: "OK")
            }
            else {
                self.DeleteConfirmationAlert(
                    title: "Confirm Delete",
                    message: "Are you sure you want to delete this?",
                    actionTitle: "Delete", cancelTitle: "Cancel", delegate: self) {
                        doIt in
                        if doIt {
                            Reporting.track("delete_channel")
                            self.delete()
                        }
                }
            }
        }
    }
    
    func manageUsersAction(sender: AnyObject?) {
        Reporting.track("view_channel_members_management")
        let controller = MemberListController()
        controller.scope = .channel
        controller.target = .channel
        controller.manage = true
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        self.doneButton.isEnabled = isDirty()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.view.setNeedsLayout()
        self.doneButton.isEnabled = isDirty()
        if let placeHolderLabel = textView.viewWithTag(100) as? UILabel {
            placeHolderLabel.isHidden = textView.hasText
        }
    }
    
    override func textViewDidEndEditing(_ textView: UITextView) {
        super.textViewDidEndEditing(textView)
        self.doneButton.isEnabled = isDirty()
    }
    
    func visibilityChanged(sender: AnyObject) {
        self.doneButton.isEnabled = isDirty()
        if let switchView = sender as? UISwitch {
            self.visibilityValue = (switchView.isOn) ? "private" : "open"
            self.banner.text = (switchView.isOn) ? "New Private Channel" : "New Channel"
            self.visibilityLabel.text = (switchView.isOn) ? "Private" : "Open"
            self.visibilityComment.text = (switchView.isOn) ? "Invite only" : "Any member can join."
            self.view.setNeedsLayout()
        }
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

        self.banner.textColor = Theme.colorTextTitle
        self.banner.numberOfLines = 0
        self.banner.textAlignment = .center

        self.photoEditView.photoSchema = Schema.entityPatch
        self.photoEditView.setHost(controller: self, view: self.photoEditView)
        self.photoEditView.configureTo(photoMode: .placeholder)

        self.nameField.placeholder = "Channel name"
        self.nameField.title = "Channel name (lower case)"
        self.nameField.setDelegate(delegate: self)
        self.nameField.autocapitalizationType = .none
        self.nameField.autocorrectionType = .no
        self.nameField.keyboardType = .default
        self.nameField.returnKeyType = .next
        
        self.purposeField.placeholder = "Channel purpose (optional)"
        self.purposeField.autocapitalizationType = .sentences
        self.purposeField.autocorrectionType = .yes
        self.purposeField.initialize()
        self.purposeField.delegate = self

        self.visibilityLabel.text = "Open"
        self.visibilitySwitch.isOn = false
        
        self.visibilityComment.text = "Any member can join."
        self.visibilityComment.font = Theme.fontComment
        self.visibilityComment.textColor = Theme.colorTextSecondary
        
        self.usersButton.setTitle("Manage Members".uppercased(), for: .normal)
        self.usersButton.imageRight = UIImageView(image: UIImage(named: "imgArrowRightLight"))
        self.usersButton.imageRight?.bounds.size = CGSize(width: 10, height: 14)
        self.usersButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 36)
        self.usersButton.addTarget(self, action: #selector(manageUsersAction(sender:)), for: .touchUpInside)

        self.visibilityGroup.addSubview(self.visibilityLabel)
        self.visibilityGroup.addSubview(self.visibilityComment)
        self.visibilityGroup.addSubview(self.visibilitySwitch)

        self.contentHolder.addSubview(self.banner)
        self.contentHolder.addSubview(self.nameField)
        self.contentHolder.addSubview(self.purposeField)
        self.contentHolder.addSubview(self.photoEditView)
        self.contentHolder.addSubview(self.visibilityGroup)
        self.contentHolder.addSubview(self.usersButton)

        if self.mode == .insert {

            self.banner.text = "New Channel"
            self.usersButton.isHidden = true

            /* Navigation bar buttons */
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
            self.doneButton = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(doneAction(sender:)))
            self.doneButton.isEnabled = false
            self.navigationItem.leftBarButtonItems = [closeButton]
            self.navigationItem.rightBarButtonItems = [doneButton]
        }
        else if self.mode == .update  {

            self.banner.text = "Edit Channel"
            self.visibilityGroup.isHidden = true

            /* Navigation bar buttons */
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
            self.doneButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(doneAction(sender:)))
            self.doneButton.isEnabled = false
            self.navigationItem.leftBarButtonItems = [closeButton]
            self.navigationItem.rightBarButtonItems = [doneButton]
        }
        
        self.nameField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.visibilitySwitch.addTarget(self, action: #selector(visibilityChanged(sender:)), for: .touchUpInside)
        
        NotificationCenter.default.addObserver(self, selector: #selector(photoDidChange(sender:)), name: NSNotification.Name(rawValue: Events.PhotoDidChange), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(photoRemoved(sender:)), name: NSNotification.Name(rawValue: Events.PhotoRemoved), object: nil)
    }

    func bind() {
        
        self.nameField.text = self.channel.name
        self.purposeField.text = self.channel.purpose
        
        if let photo = self.channel.photo {
            self.photoEditView.configureTo(photoMode: .photo)
            let photoUrl = ImageProxy.url(photo: photo, category: SizeCategory.standard)
            self.photoEditView.bind(url: photoUrl)
        }
        
        /* Delete */
        if !self.channel.general! && self.mode == .update {
            self.navigationController?.setToolbarHidden(false, animated: true)
            let deleteIconButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.trash, target: self, action: #selector(deleteAction(sender:)))
            let deleteTitleButton = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(deleteAction(sender:)))
            deleteIconButton.tintColor = Colors.brandColor
            deleteTitleButton.tintColor = Colors.brandColor
            self.toolbarItems = [Ui.spacerFlex, deleteIconButton, deleteTitleButton, Ui.spacerFlex]
        }

        /* Visibility */
        self.banner.text = (self.channel.visibility == "private") ? "Private Channel Settings" : "Channel Settings"
        self.view.setNeedsLayout()
    }

    func post() {
        
        self.processing = true
        
        let groupId = self.inputGroupId!
        let userId = UserController.instance.userId!
        
        if self.mode == .update {
            
            let nameChange = (self.nameField.text != self.channel!.name)
            let priorName = self.channel!.name!
            var updates = [String: Any]()
            
            if self.nameField.text != self.channel!.name {
                updates["name"] = self.nameField.text
            }
            if emptyToNil(self.purposeField.text) != self.channel!.purpose {
                updates["purpose"] = emptyToNull(self.purposeField.text)
            }
            if self.photoEditView.photoDirty {
                if self.photoEditView.photoActive {
                    let image = self.photoEditView.imageView.image
                    let asset = self.photoEditView.imageView.asset
                    let path = self.channel.path
                    var photoMap: [String: Any]?
                    photoMap = postPhoto(image: image!, asset: asset, progress: self.photoEditView.progressBlock, next: { error in
                        if error == nil {
                            photoMap!["uploading"] = NSNull()
                            FireController.db.child(path).updateChildValues(["photo": photoMap!])
                        }
                    })
                    updates["photo"] = photoMap!
                }
                else {
                    updates["photo"] = NSNull()
                }
            }
            
            if updates.keys.count > 0 {
                let timestamp = FireController.instance.getServerTimestamp()
                updates["modified_at"] = timestamp
                FireController.db.child(self.channel.path).updateChildValues(updates) { error, ref in
                    if error != nil {
                        self.progress?.hide(true)
                        Log.w("Error updating channel: \(error!.localizedDescription)")
                        return
                    }
                    if nameChange {
                        let name = self.nameField.text!
                        let channelId = self.channel.id!
                        var updates = [String: Any]()
                        updates["channel-names/\(groupId)/\(name)"] = channelId
                        updates["channel-names/\(groupId)/\(priorName)"] = NSNull()
                        FireController.db.updateChildValues(updates) { error, ref in
                            if error != nil {
                                Log.w("Error updating channel: \(error!.localizedDescription)")
                                return
                            }
                            self.progress?.hide(true)
                            self.close(animated: true)
                        }
                    }
                    else {
                        self.progress?.hide(true)
                        self.close(animated: true)
                    }
                }
            }
            else {
                self.progress?.hide(true)
                self.close(animated: true)
                return
            }
        }
        
        if self.mode == .insert {
            
            let channelId = "ch-\(Utils.genRandomId())"
            let channelName = self.nameField.text!
            let ref = FireController.db.child("group-channels/\(groupId)/\(channelId)")
            let timestamp = FireController.instance.getServerTimestamp()
            
            var photoMap: [String: Any]?
            if let image = self.photoEditView.imageView.image {
                let asset = self.photoEditView.imageView.asset
                photoMap = self.postPhoto(image: image, asset: asset, next: { error in
                    if error == nil {
                        photoMap!["uploading"] = NSNull()
                        ref.child("photo").setValue(photoMap!)
                    }
                })
            }
            
            var channelMap: [String: Any] = [:]
            channelMap["archived"] = false
            channelMap["created_at"] = timestamp
            channelMap["created_by"] = userId
            channelMap["general"] = false
            channelMap["group_id"] = groupId
            channelMap["name"] = channelName
            channelMap["owned_by"] = userId
            if photoMap != nil {
                channelMap["photo"] = photoMap!
            }
            if !(self.purposeField.text?.isEmpty)! {
                channelMap["purpose"] = self.purposeField.text
            }
            channelMap["type"] = "channel"
            channelMap["visibility"] = self.visibilityValue
            
            FireController.instance.addChannelToGroup(channelId: channelId, channelMap: channelMap, groupId: groupId) { [weak self] success in
                
                guard let this = self else { return }
                this.progress?.hide(true)
                if !success {
                    Log.w("Error creating channel")
                    return
                }
                
                let controller = ChannelInviteController()
                controller.flow = .internalCreate
                controller.inputAsOwner = true
                controller.inputChannelId = channelId
                controller.inputChannelName = channelName
                this.navigationController?.setViewControllers([controller], animated: true)
            }
        }
    }

    func delete() {
        FireController.instance.deleteChannel(channelId: self.channel.id!, groupId: self.channel.groupId!)
        self.close(animated: true)
    }

    func isDirty() -> Bool {
        
        if self.mode == .update {
            if !stringsAreEqual(string1: self.nameField.text, string2: self.channel.name) {
                return true
            }
            if !stringsAreEqual(string1: self.purposeField.text, string2: self.channel.purpose) {
                return true
            }
            if self.photoEditView.photoDirty {
                return true
            }
        }
        else {
            if !self.nameField.text!.isEmpty {
                return true
            }
            if !self.purposeField.text!.isEmpty {
                return true
            }
            if self.photoEditView.photoDirty {
                return true
            }
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
            self.nameField.errorMessage = "Lower case and no spaces or periods."
            return false
        }
        
        if (nameField.text!.utf16.count > 50) {
            self.nameField.errorMessage = "Channel name must be 50 characters or less."
            return false
        }

        if (nameField.text!.utf16.count < 3) {
            self.nameField.errorMessage = "Channel name must be at least 3 characters."
            return false
        }
        return true
    }
    
    func isValidChannelName(then: @escaping (Bool) -> Void) {
        if self.mode == .insert || !stringsAreEqual(string1: self.nameField.text, string2: self.channel.name) {
            let channelName = nameField.text!
            let groupId = self.inputGroupId!
            FireController.instance.channelNameExists(groupId: groupId, channelName: channelName) { error, exists in
                if error != nil {
                    Log.w("Error checking if channel name is used")
                    then(false)
                    return
                }
                if exists {
                    Reporting.track("error_channel_name_used")
                    self.nameField.errorMessage = "Choose another channel name"
                    then(false)
                    return
                }
                then(true)
            }
        }
        else {
            then(true)
        }
    }
    
    enum Mode: Int {
        case insert
        case update
    }
}
