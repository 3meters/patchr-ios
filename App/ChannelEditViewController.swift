//
//  RegistrationTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-24.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MBProgressHUD
import Facade
import Firebase

class ChannelEditViewController: BaseEditViewController {

    var inputChannelId: String!
    var channel: FireChannel!
    var channelQuery: ChannelQuery!

    var banner = AirLabelTitle()
    var photoEditView = PhotoEditView()
    var titleField = FloatTextField(frame: CGRect.zero)
    var purposeField = AirTextView()

    var doneButton: UIBarButtonItem!

    /*--------------------------------------------------------------------------------------------
    * Mark: - Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        
        if self.mode == .update {
            self.channelQuery = ChannelQuery(channelId: self.inputChannelId, userId: nil)
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
            let _ = self.titleField.becomeFirstResponder()
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
        self.titleField.alignUnder(self.banner, matchingCenterWithTopPadding: 24, width: Config.contentWidth, height: 48)
        self.photoEditView.alignUnder(self.titleField, matchingCenterWithTopPadding: 16, width: Config.contentWidth, height: Config.contentWidth * 0.56)
        self.purposeField.alignUnder(self.photoEditView, matchingCenterWithTopPadding: 16, width: Config.contentWidth, height: max(48, purposeSize.height))
        
        super.viewWillLayoutSubviews()
    }

    /*--------------------------------------------------------------------------------------------
     * MARK: - Events
     *--------------------------------------------------------------------------------------------*/

    func closeAction(sender: AnyObject){
        
        if !isDirty() {
            self.close(animated: true)
            return
        }
        
        DeleteConfirmationAlert(
            title: "discard_changes".localized(),
            actionTitle: "discard".localized(), cancelTitle: "cancel".localized(), delegate: self) {
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
                self.progress?.labelText = "progress_updating".localized()
                self.progress?.removeFromSuperViewOnHide = true
                self.progress?.show(true)
                Reporting.track("update_channel")
                self.post()
            }
        }
        else if self.mode == .insert {
            FireController.instance.isConnected() { connected in
                if connected == nil || !connected! {
                    let message = "channel_not_connected_message".localizedFormat("creating".localized())
                    self.alert(title: "channel_not_connected_title".localized()
                        , message: message
                        , cancelButtonTitle: "ok".localized())
                }
                else {
                    if self.isValid() {
                        self.progress = AirProgress.showAdded(to: self.view.window!, animated: true)
                        self.progress?.mode = MBProgressHUDMode.indeterminate
                        self.progress?.styleAs(progressStyle: .activityWithText)
                        self.progress?.minShowTime = 0.5
                        self.progress?.labelText = "progress_creating".localized()
                        self.progress?.removeFromSuperViewOnHide = true
                        self.progress?.show(true)
                        Reporting.track("create_channel")
                        self.post()
                    }
                }
            }
        }
    }
    
    func deleteAction(sender: AnyObject) {
        
        guard !self.processing else { return }
        
        FireController.instance.isConnected() { connected in
            if connected == nil || !connected! {
                let message = "channel_not_connected_message".localizedFormat("deleting".localized())
                self.alert(title: "channel_not_connected_title".localized()
                    , message: message
                    , cancelButtonTitle: "ok".localized())
            }
            else {
                self.DeleteConfirmationAlert(
                    title: "channel_delete_title".localized(),
                    message: "channel_delete_message".localized(),
                    actionTitle: "delete".localized(),
                    cancelTitle: "cancel".localized(),
                    delegate: self) {
                        doIt in
                        if doIt {
                            Reporting.track("delete_channel")
                            self.delete()
                        }
                }
            }
        }
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
    
    override func didSetPhoto() {
        super.didSetPhoto()
        self.doneButton.isEnabled = isDirty()
    }
    
    override func didClearPhoto() {
        super.didClearPhoto()
        self.doneButton.isEnabled = isDirty()
    }
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Notifications
     *--------------------------------------------------------------------------------------------*/
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Methods
     *--------------------------------------------------------------------------------------------*/

    override func initialize() {
        super.initialize()

        self.banner.textColor = Theme.colorTextTitle
        self.banner.numberOfLines = 0
        self.banner.textAlignment = .center

        self.photoEditView.photoSchema = Schema.entityPatch
        self.photoEditView.setHost(controller: self, view: self.photoEditView)
        self.photoEditView.configureTo(photoMode: .placeholder)
        self.photoEditView.photoDelegate = self

        self.titleField.setDelegate(delegate: self)
        self.titleField.autocapitalizationType = .words
        self.titleField.autocorrectionType = .no
        self.titleField.keyboardType = .default
        self.titleField.returnKeyType = .next
        
        self.purposeField.autocapitalizationType = .sentences
        self.purposeField.autocorrectionType = .yes
        self.purposeField.initialize()
        self.purposeField.delegate = self

        self.contentHolder.addSubview(self.banner)
        self.contentHolder.addSubview(self.titleField)
        self.contentHolder.addSubview(self.purposeField)
        self.contentHolder.addSubview(self.photoEditView)

        if self.mode == .insert {
            /* Navigation bar buttons */
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
            self.doneButton = UIBarButtonItem(title: nil, style: .plain, target: self, action: #selector(doneAction(sender:)))
            self.doneButton.isEnabled = false
            self.navigationItem.leftBarButtonItems = [closeButton]
            self.navigationItem.rightBarButtonItems = [doneButton]
        }
        else if self.mode == .update  {
            /* Navigation bar buttons */
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
            self.doneButton = UIBarButtonItem(title: nil, style: .plain, target: self, action: #selector(doneAction(sender:)))
            self.doneButton.isEnabled = false
            self.navigationItem.leftBarButtonItems = [closeButton]
            self.navigationItem.rightBarButtonItems = [doneButton]
        }
        
        self.titleField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        bindLanguage()
    }
    
    func bindLanguage() {
        self.titleField.placeholder = "channel_edit_title_placeholder".localized()
        self.titleField.title = "title".localized()
        self.purposeField.placeholder = "channel_edit_purpose_placeholder".localized()
        if self.mode == .insert {
            self.banner.text = "channel_edit_header_insert".localizedFormat("patchr".localized())
            self.doneButton.title = "create".localized()
        }
        else if self.mode == .update  {
            self.banner.text = "channel_edit_header_update".localizedFormat("patchr".localized())
            self.doneButton.title = "save".localized()
        }
    }

    func bind() {
        
        self.titleField.text = self.channel.title
        self.purposeField.text = self.channel.purpose
        
        if let photo = self.channel.photo {
            self.photoEditView.configureTo(photoMode: .photo)
            let photoUrl = ImageProxy.url(photo: photo, category: SizeCategory.standard)
            self.photoEditView.bind(url: photoUrl)
        }
        
        if !self.channel.general! {
            let deleteButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteAction(sender:)))
            self.navigationItem.setRightBarButtonItems([self.doneButton, UI.spacerFixed, deleteButton], animated: true)
        }
        
        /* Visibility */
        self.view.setNeedsLayout()
    }

    func post() {
        
        self.processing = true
        
        let userId = UserController.instance.userId!
        
        if self.mode == .update {
            
            var updates = [String: Any]()
            
            if self.titleField.text != self.channel!.title {
                updates["title"] = self.titleField.text
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
                    photoMap = postPhoto(image: image!, asset: asset, next: { error in
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
                    self.progress?.hide(true)
                    self.close(animated: true)
                }
            }
            else {
                self.progress?.hide(true)
                self.close(animated: true)
                return
            }
        }
        
        if self.mode == .insert {
            
            let channelId = "ch-\(Utils.genRandomId(digits: 9))"
            let channelCode = Utils.genRandomId(digits: 12)
            let channelTitle = self.titleField.text!
            let ref = FireController.db.child("channels/\(channelId)")
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
            channelMap["created_at"] = timestamp
            channelMap["created_by"] = userId
            channelMap["general"] = false
            channelMap["title"] = channelTitle
            channelMap["code"] = channelCode // code is required
            channelMap["owned_by"] = userId
            if photoMap != nil {
                channelMap["photo"] = photoMap!
            }
            if !(self.purposeField.text?.isEmpty)! {
                channelMap["purpose"] = self.purposeField.text
            }
            
            FireController.instance.addChannel(channelId: channelId, channelMap: channelMap) { [weak self] success in
                
                guard let this = self else { return }
                this.progress?.hide(true)
                if !success {
                    Log.w("Error creating channel")
                    return
                }
                
                let controller = InviteViewController()
                controller.flow = .internalCreate
                controller.inputAsOwner = true
                controller.inputCode = channelCode
                controller.inputChannelId = channelId
                controller.inputChannelTitle = channelTitle
                this.navigationController?.setViewControllers([controller], animated: true)
            }
        }
    }

    func delete() {
        FireController.instance.deleteChannel(channelId: self.channel.id!)
        self.close(animated: true)
    }

    func isDirty() -> Bool {
        
        if self.mode == .update {
            if !stringsAreEqual(string1: self.titleField.text, string2: self.channel.title) {
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
            if !self.titleField.text!.isEmpty {
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
        
        if self.titleField.isEmpty {
            self.titleField.errorMessage = "channel_title_empty".localized()
            return false
        }
        
        if (titleField.text!.utf16.count > 200) {
            self.titleField.errorMessage = "channel_title_too_long".localized()
            return false
        }

        if (titleField.text!.utf16.count < 3) {
            self.titleField.errorMessage = "channel_title_too_short".localized()
            return false
        }
        return true
    }
    
    enum Mode: Int {
        case insert
        case update
    }
}
