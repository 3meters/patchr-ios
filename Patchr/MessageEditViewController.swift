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

enum MessageType: Int {
    case Content
    case Share
}

class MessageEditViewController: BaseEditViewController, UITextViewDelegate {

    var ref: FIRDatabaseReference!
    var serverOffset: Int!
    var inputMessageId: String!
    var inputChannelId: String!
    var message: FireMessage!
    var user: FireUser!

    var descriptionField	= AirTextView()
    var photoEditView       = PhotoEditView()
    
    var inputState			: State? = State.Editing
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
        
        let userId = FIRAuth.auth()?.currentUser?.uid
        FIRDatabase.database().reference().child("users/\(userId!)").observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                self.user = FireUser.from(dict: snap.value as? [String: Any], id: snap.key)
                if self.inputMessageId != nil {
                    self.ref.child(self.inputMessageId!).observeSingleEvent(of: .value, with: { snap in
                        if snap.value != nil {
                            self.message = FireMessage.from(dict: snap.value as? [String: Any], id: snap.key)
                            self.bind()
                        }
                    })
                }
                else {
                    FIRDatabase.database().reference().child(".info/serverTimeOffset").observeSingleEvent(of: .value, with: { snap in
                        if snap.value != nil {
                            self.serverOffset = snap.value as! Int!
                        }
                    })
                }
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.inputState == State.Creating && self.firstAppearance  {
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
        
        self.ref = FIRDatabase.database().reference().child("channel-messages/\(self.inputChannelId!)")

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

        if self.inputState == State.Creating {
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
        else {
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
                self.photoEditView.bind(url: photoUrl)
            }
        }
        
        textViewDidChange(self.descriptionField)
    }

    func post() {
        self.processing = true
        
        if self.inputMessageId == nil {
            if let image = self.photoEditView.imageButton.image(for: .normal) {
                postPhoto(image: image)
            }
            else {
                postMessage(photo: nil)
            }
        }
        
        UIShared.Toast(message: self.progressStartLabel)
        self.processing = true
        self.performBack(animated: true)
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
                    
                    self.postMessage(photo: photo)
                }
            })
        }
    }
    
    func postMessage(photo: [String: Any]?) {
        
        var messageMap: [String: Any] = [:]
        
        let timestamp = Utils.now() + self.serverOffset!
        let timestampReversed = -1 * timestamp
        
        messageMap["modified_at"] = Int(timestamp)
        messageMap["created_at"] = Int(timestamp)
        messageMap["modified_by"] = self.user.id!
        messageMap["created_by"] = self.user.id!
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
        
        let newMessage = self.ref.childByAutoId()
        newMessage.setValue(messageMap)
    }
    
    func delete() {
        self.processing = true
        self.ref.child(self.inputMessageId!).removeValue {_,_ in
            self.processing = false
            self.performBack(animated: true)
        }
    }

    func isDirty() -> Bool {

        if self.inputState == .Creating {
            if !self.descriptionField.text!.isEmpty {
                return true
            }
            if self.photoEditView.photoDirty {
                return true
            }
        }
        else if self.inputState == .Sharing {
            if !self.descriptionField.text!.isEmpty {
                return true
            }
        }
        else if self.inputState == .Editing {
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
