//
//  RegistrationTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-24.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AWSS3
import THContactPicker
import MBProgressHUD
import Firebase

class MessageEditViewController: BaseEditViewController, UITextViewDelegate {

    var serverOffset: Int!
    
    /* For editing */
    var inputMessageId: String!
    var inputChannelId: String!
    var message: FireMessage!

    var descriptionField	= AirTextView()
    var photoEditView       = PhotoEditView()
    
    var mode: Mode = .insert
    var processing			: Bool = false
    var progressStartLabel	: String?
    var progressFinishLabel	: String?
    var cancelledLabel		: String?
    var firstAppearance		= true
    var progress			: AirProgress?
    var doneButton			= AirFeaturedButton()

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
        else if self.mode == .insert {
            FireController.instance.getServerTimeOffset(with: { offset in
                self.serverOffset = offset
            })
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.mode == .insert && self.firstAppearance  {
            self.descriptionField.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.firstAppearance = false
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

    func userCancelTaskAction(sender: AnyObject) {
        if let gesture = sender as? UIGestureRecognizer, let hud = gesture.view as? MBProgressHUD {
            hud.animationType = MBProgressHUDAnimation.zoomIn
            hud.hide(true)
            let _ = self.imageUploadRequest?.cancel() // Should do nothing if upload already complete or isn't any
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if let textView = textView as? AirTextView {
            self.activeTextField = textView
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if self.activeTextField == textView {
            self.activeTextField = nil
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
        self.descriptionField.placeholderLabel.text = "What\'s happening?"
        self.descriptionField.placeholderLabel.insets = UIEdgeInsetsMake(0, 0, 0, 0)
        self.descriptionField.initialize()
        self.descriptionField.delegate = self

        self.contentHolder.addSubview(self.descriptionField)
        self.contentHolder.addSubview(self.photoEditView)

        self.descriptionField.placeholderLabel.text = "What\'s happening?"
        
        NotificationCenter.default.addObserver(self, selector: #selector(photoDidChange(sender:)), name: NSNotification.Name(rawValue: Events.PhotoDidChange), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(photoRemoved(sender:)), name: NSNotification.Name(rawValue: Events.PhotoRemoved), object: nil)

        if self.mode == .insert {
            Reporting.screen("MessageNew")
            self.progressStartLabel = "Posting"
            self.progressFinishLabel = "Posted"
            self.cancelledLabel = "Post cancelled"

            /* Navigation bar buttons */
            let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(MessageEditViewController.cancelAction(sender:)))
            let doneButton = UIBarButtonItem(title: "Post", style: UIBarButtonItemStyle.plain, target: self, action: #selector(MessageEditViewController.doneAction(sender:)))
            self.navigationItem.leftBarButtonItems = [cancelButton]
            self.navigationItem.rightBarButtonItems = [doneButton]
        }
        else if self.mode == .update {
            Reporting.screen("MessageEdit")
            self.progressStartLabel = "Updating"
            self.progressFinishLabel = "Updated"
            self.cancelledLabel = "Update cancelled"

            self.doneButton.isHidden = true

            /* Navigation bar buttons */
            self.navigationItem.title = "Edit message"
            let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(MessageEditViewController.cancelAction(sender:)))
            let deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.trash, target: self, action: #selector(MessageEditViewController.deleteAction(sender:)))
            let doneButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(MessageEditViewController.doneAction(sender:)))
            self.navigationItem.leftBarButtonItems = [cancelButton]
            self.navigationItem.rightBarButtonItems = [doneButton, Utils.spacer, deleteButton]
        }
    }

    func bind() {
        
        if self.message.text != nil {
            self.descriptionField.text = self.message.text!
        }
        
        if let photo = self.message.attachments?.first?.photo {
            if let photoUrl = PhotoUtils.url(prefix: photo.filename, source: photo.source, category: SizeCategory.standard) {
                self.photoEditView.configureTo(photoMode: .Photo)
                self.photoEditView.bind(url: photoUrl)
            }
        }
        
        textViewDidChange(self.descriptionField)
    }

    func post() {
        self.processing = true
        
        if let image = self.photoEditView.imageButton.image(for: .normal) {
            postPhoto(image: image)
        }
        else {
            postMessage(photo: nil)
        }
        
        UIShared.Toast(message: self.progressStartLabel)
        self.processing = false
        self.performBack(animated: true)
    }
    
    func postPhoto(image: UIImage?) {
        
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
                    
                    self.postMessage(photo: photo)
                }
            })
        }
    }
    
    func postMessage(photo: [String: Any]?) {
        
        if self.mode == .insert {
            
            let timestamp = Utils.now() + self.serverOffset!
            let timestampReversed = -1 * timestamp
            
            var messageMap: [String: Any] = [:]
            messageMap["modified_at"] = Int(timestamp)
            messageMap["created_at"] = Int(timestamp)
            messageMap["modified_by"] = UserController.instance.userId!
            messageMap["created_by"] = UserController.instance.userId!
            messageMap["timestamp"] = Int(timestampReversed)
            messageMap["channel"] = self.inputChannelId!
            
            if !self.descriptionField.text.isEmpty {
                messageMap["text"] = self.descriptionField.text
            }
            
            if photo != nil {
                messageMap["attachments"] = [[
                    "photo": photo!
                    ]]
            }
            let path = "channel-messages/\(self.inputChannelId!)"
            FireController.db.child(path).childByAutoId().setValue(messageMap)
        }
        else if self.mode == .update {
            
            var updateMap: [String: Any] = ["modified_at": FIRServerValue.timestamp()]
            updateMap["attachments"] = photo != nil ? [["photo": photo!]] : NSNull()
            updateMap["text"] = self.descriptionField.text.isEmpty ? NSNull() : self.descriptionField.text
            
            FireController.db.child(self.message.path).updateChildValues(updateMap)
        }
    }
    
    func delete() {
        FireController.instance.delete(messageId: message.id!, channelId: message.channel!)
        self.performBack(animated: true)
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
    
    enum Mode: Int {
        case insert
        case update
    }
}

