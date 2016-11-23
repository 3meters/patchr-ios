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
import Firebase

class MessageEditViewController: BaseEditViewController {

    /* For editing */
    var inputMessageId: String!
    var inputChannelId: String!
    var message: FireMessage!

    var descriptionField = AirTextView()
    var photoEditView = PhotoEditView()
    var doneButton = AirFeaturedButton()

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        
        if self.mode == .update {
            let messageQuery = MessageQuery(channelId: self.inputChannelId, messageId: self.inputMessageId)
            messageQuery.once(with: { message in
                guard message != nil else {
                    assertionFailure("message not found or no longer exists")
                    return
                }
                self.message = message
                self.bind()
            })
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.mode == .insert && self.firstAppearance  {
            self.descriptionField.becomeFirstResponder()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let viewWidth = min(CONTENT_WIDTH_MAX, self.view.bounds.size.width)
        let contentWidth = CGFloat(viewWidth - 32)
        self.view.bounds.size.width = viewWidth
        self.contentHolder.bounds.size.width = viewWidth

        let descriptionSize = self.descriptionField.sizeThatFits(CGSize(width:contentWidth, height:CGFloat.greatestFiniteMagnitude))

        self.descriptionField.anchorTopLeft(withLeftPadding: 0, topPadding: 0, width: contentWidth, height: max(96, descriptionSize.height))
        self.photoEditView.alignUnder(self.descriptionField, matchingLeftAndRightWithTopPadding: 8, height: self.photoEditView.photoMode == .Empty ? 48 : contentWidth * 0.75)

        self.contentHolder.resizeToFitSubviews()
        self.scrollView.contentSize = CGSize(width:self.contentHolder.width(), height: self.contentHolder.height() + CGFloat(32))
        self.contentHolder.anchorTopCenterFillingWidth(withLeftAndRightPadding: 16, topPadding: 0, height: self.contentHolder.height() + 32)
    }

    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/

    func doneAction(sender: AnyObject){

        guard isValid() else { return }
        guard !self.processing else { return }

        post()
    }

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

    func textViewDidChange(_ textView: UITextView) {
        if let textView = textView as? AirTextView {
            textView.placeholderLabel.isHidden = !self.descriptionField.text.isEmpty
            self.viewWillLayoutSubviews()
        }
    }
    
    /*--------------------------------------------------------------------------------------------
     * Notifications
     *--------------------------------------------------------------------------------------------*/
    
    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/

    override func initialize() {
        super.initialize()
        
        self.photoEditView.photoSchema = Schema.ENTITY_MESSAGE
        self.photoEditView.setHostController(controller: self)
        self.photoEditView.configureTo(photoMode: .Empty)

        self.descriptionField = AirTextView()
        self.descriptionField.placeholder = "What\'s happening?"
        self.descriptionField.floatingLabelActiveTextColor = Colors.accentColorTextLight
        self.descriptionField.floatingLabelFont = Theme.fontComment
        self.descriptionField.floatingLabelTextColor = Theme.colorTextPlaceholder
        self.descriptionField.delegate = self
        self.descriptionField.initialize()
        self.descriptionField.delegate = self

        self.contentHolder.addSubview(self.descriptionField)
        self.contentHolder.addSubview(self.photoEditView)

        self.descriptionField.placeholderLabel.text = "What\'s happening?"
        
        NotificationCenter.default.addObserver(self, selector: #selector(photoDidChange(sender:)), name: NSNotification.Name(rawValue: Events.PhotoDidChange), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(photoRemoved(sender:)), name: NSNotification.Name(rawValue: Events.PhotoRemoved), object: nil)

        if self.mode == .insert {
            
            Reporting.screen("MessageNew")
            self.progressFinishLabel = "Posted"

            /* Navigation bar buttons */
            let closeButton = UIBarButtonItem(image: UIImage(named: "imgCancelLight"), style: .plain, target: self, action: #selector(closeAction(sender:)))
            let doneButton = UIBarButtonItem(title: "Post", style: UIBarButtonItemStyle.plain, target: self, action: #selector(MessageEditViewController.doneAction(sender:)))
            self.navigationItem.leftBarButtonItems = [closeButton]
            self.navigationItem.rightBarButtonItems = [doneButton]
        }
        else if self.mode == .update {
            
            Reporting.screen("MessageEdit")
            self.progressFinishLabel = "Updated"

            self.doneButton.isHidden = true

            /* Navigation bar buttons */
            self.navigationItem.title = "Edit message"
            let closeButton = UIBarButtonItem(image: UIImage(named: "imgCancelLight"), style: .plain, target: self, action: #selector(closeAction(sender:)))
            let deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.trash, target: self, action: #selector(MessageEditViewController.deleteAction(sender:)))
            let doneButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(MessageEditViewController.doneAction(sender:)))
            self.navigationItem.leftBarButtonItems = [closeButton]
            self.navigationItem.rightBarButtonItems = [doneButton, Utils.spacer, deleteButton]
        }
    }

    func bind() {
        
        if self.message.text != nil {
            self.descriptionField.text = self.message.text!
        }
        
        if let photo = self.message.attachments?.first?.photo, !photo.uploading {
            if let photoUrl = PhotoUtils.url(prefix: photo.filename, source: photo.source, category: SizeCategory.standard) {
                self.photoEditView.configureTo(photoMode: .Photo)
                self.photoEditView.bind(url: photoUrl)
            }
        }
        
        textViewDidChange(self.descriptionField)
    }

    func post() {
        
        self.processing = true
        
        if self.mode == .insert {
            
            let path = "channel-messages/\(self.inputChannelId!)"
            let refMessage = FireController.db.child(path).childByAutoId()
            
            var photoMap: [String: Any]?
            if let image = self.photoEditView.imageButton.image(for: .normal) {
                photoMap = postPhoto(image: image, progress: self.photoEditView.progressBlock, next: { error in
                    if error == nil {
                        photoMap!["uploading"] = NSNull()
                        refMessage.child("attachments").setValue([["photo": photoMap!]])
                    }
                })
            }
            
            let timestamp = Utils.now() + (FireController.instance.serverOffset ?? 0)
            let timestampReversed = -1 * timestamp
            
            var messageMap: [String: Any] = [:]
            messageMap["modified_at"] = Int(timestamp)
            messageMap["created_at"] = Int(timestamp)
            messageMap["created_at_desc"] = Int(timestampReversed)
            messageMap["modified_by"] = UserController.instance.userId!
            messageMap["created_by"] = UserController.instance.userId!
            messageMap["channel"] = self.inputChannelId!
            
            if !self.descriptionField.text.isEmpty {
                messageMap["text"] = self.descriptionField.text
            }
            
            if photoMap != nil {
                messageMap["attachments"] = [["photo": photoMap!]]
            }
            
            refMessage.setValue(messageMap)
        }
        else if self.mode == .update {
            
            var updateMap: [String: Any] = ["modified_at": FIRServerValue.timestamp()]
            let path = self.message.path
            
            if self.photoEditView.photoDirty {
                var photoMap: [String: Any]?
                if let image = self.photoEditView.imageButton.image(for: .normal) {
                    photoMap = postPhoto(image: image, progress: self.photoEditView.progressBlock, next: { error in
                        if error == nil {
                            photoMap!["uploading"] = NSNull()
                            FireController.db.child(path).child("attachments").setValue([["photo": photoMap!]])
                        }
                    })
                }
                
                updateMap["attachments"] = photoMap != nil ? [["photo": photoMap!]] : NSNull()
            }
            
            updateMap["text"] = self.descriptionField.text.isEmpty ? NSNull() : self.descriptionField.text
            
            FireController.db.child(path).updateChildValues(updateMap)
        }
        
        UIShared.Toast(message: self.progressFinishLabel)
        self.processing = false
        self.close(animated: true)
    }
    
    func delete() {
        FireController.instance.delete(messageId: message.id!, channelId: message.channel!)
        self.close(animated: true)
    }

    func isDirty() -> Bool {

        if self.mode == .insert {
            if !self.descriptionField.text!.isEmpty {
                return true
            }
            if self.photoEditView.photoDirty {
                return true
            }
        }
        else if self.mode == .update {
            if !stringsAreEqual(string1: self.descriptionField.text, string2: self.message.text) {
                return true
            }
            if self.photoEditView.photoDirty {
                return true
            }
        }
        return false
    }

    func isValid() -> Bool {

        if ((self.descriptionField.text == nil || self.descriptionField.text!.isEmpty)
            && self.photoEditView.imageButton.image(for: .normal) == nil) {
                Alert(title: "Add message or photo", message: nil, cancelButtonTitle: "OK")
                return false
        }
        return true
    }
}

