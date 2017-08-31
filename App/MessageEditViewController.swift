//
//  MessageEditViewController.swift
//  Patchr
//
//  Created by Jay Massena on 7/24/17.
//  Copyright © 2017 3meters. All rights reserved.
//

import Facade
import Firebase
import MBProgressHUD
import UIKit

class MessageEditViewController: BaseEditViewController {

    var message: FireMessage!
    var messageQuery: MessageQuery!
    
	var inputMessageId: String!
	var inputChannelId: String!

	var userGroup = AirRuleView()
	var userPhotoControl = PhotoControl()
	var userName = AirLabelDisplay()
	var messageField = AirTextView()
	var photoEditView = PhotoEditView()
    var photoButton = UIButton()

    var doneButton: UIBarButtonItem!

	/*--------------------------------------------------------------------------------------------
	 * MARK: - Lifecycle
	 *--------------------------------------------------------------------------------------------*/

	override func viewDidLoad() {
		super.viewDidLoad()
		initialize()

		if self.mode == .update {
			self.messageQuery = MessageQuery(channelId: self.inputChannelId, messageId: self.inputMessageId)
			self.messageQuery.once(with: { [weak self] error, message in
				guard let this = self else { return }
				guard message != nil else {
					assertionFailure("Message not found or no longer exists")
					return
				}
				this.message = message
				this.bind()
			})
		}
        else {
            bind()
        }
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if self.mode == .insert && self.firstAppearance {
			self.messageField.becomeFirstResponder()
		}
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
        
        let viewWidth = min(Config.contentWidthMax, self.view.width())

		let messageSize = self.messageField.sizeThatFits(CGSize(width: viewWidth, height: CGFloat.greatestFiniteMagnitude))
        self.userName.sizeToFit()
        
        self.userGroup.anchorTopCenter(withTopPadding: -16, width: viewWidth, height: 64)
		self.userPhotoControl.anchorCenterLeft(withLeftPadding: 16, width: 48, height: 48)
        self.userName.align(toTheRightOf: self.userPhotoControl, matchingCenterWithLeftPadding: 8, width: self.userName.width(), height: self.userName.height())
        
        self.messageField.alignUnder(self.userGroup, matchingCenterWithTopPadding: 0, width: viewWidth - 32, height: max(messageSize.height, 96))
		self.photoEditView.alignUnder(self.messageField, matchingLeftAndRightWithTopPadding: 8, height: viewWidth * 0.75)
        self.photoButton.alignUnder(self.messageField, matchingLeftAndRightWithTopPadding: 8, height: 48)
	}

	/*--------------------------------------------------------------------------------------------
	 * MARK: - Events
	 *--------------------------------------------------------------------------------------------*/

    func closeAction(sender: AnyObject) {
        
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
    
	func doneAction(sender: AnyObject) {

		guard isValid() else { return }
		guard !self.processing else { return }
        
        self.activeTextField?.resignFirstResponder()
        if isValid() {
            Reporting.track(mode == .update ? "update_message": "create_message")
            self.post()
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
                let channelId = self.message.channelId!
                let messageId = self.message.id!
                Reporting.track("delete_message")
                FireController.instance.deleteMessage(messageId: messageId, channelId: channelId)
                self.close(animated: true)
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
    
    func setPhotoAction(sender: AnyObject) {
        self.view.endEditing(true)
        self.photoEditView.setPhotoAction(sender: sender)
    }
    
    override func willSetPhoto() {
        super.willSetPhoto()
        self.photoButton.fadeOut()
        self.photoEditView.fadeIn()
    }
    
    override func didSetPhoto() {
        super.didSetPhoto()
        self.photoButton.fadeOut()
        self.photoEditView.fadeIn()
        self.doneButton.isEnabled = isDirty()
    }
    
    override func didClearPhoto() {
        super.didClearPhoto()
        self.photoButton.fadeIn()
        self.photoEditView.fadeOut()
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

        self.userPhotoControl.contentMode = .scaleAspectFill
        self.userPhotoControl.clipsToBounds = true
        self.userPhotoControl.layer.cornerRadius = 24
        
        self.userGroup.backgroundColor = UIColor(red: CGFloat(0.98), green: CGFloat(0.98), blue: CGFloat(0.98), alpha: CGFloat(1))
        self.userGroup.thickness = 0.5
        
        self.messageField = AirTextView()
        self.messageField.placeholder = "What\'s happening?"
        self.messageField.initialize()
        self.messageField.delegate = self
        
		self.photoEditView.photoSchema = Schema.entityMessage
		self.photoEditView.setHost(controller: self, view: self.photoEditView)
		self.photoEditView.configureTo(photoMode: .placeholder)
        self.photoEditView.photoDelegate = self
        self.photoEditView.alpha = 0
        
        self.photoButton.setImage(#imageLiteral(resourceName: "UIButtonCamera"), for: .normal)
        self.photoButton.backgroundColor = Theme.colorButtonFill
        self.photoButton.cornerRadius = Theme.dimenButtonCornerRadius
        self.photoButton.borderWidth = Theme.dimenButtonBorderWidth
        self.photoButton.borderColor = Theme.colorButtonBorder
        self.photoButton.alpha = 1
        
        self.photoButton.addTarget(self, action: #selector(setPhotoAction(sender:)), for: .touchUpInside)

		self.userGroup.addSubview(self.userPhotoControl)
		self.userGroup.addSubview(self.userName)
		self.contentHolder.addSubview(self.messageField)
		self.contentHolder.addSubview(self.photoEditView)
        self.contentHolder.addSubview(self.photoButton)
		self.contentHolder.addSubview(self.userGroup)

		if self.mode == .insert {
			/* Navigation bar buttons */
			let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
			self.doneButton = UIBarButtonItem(title: "Post", style: .plain, target: self, action: #selector(doneAction(sender:)))
			self.doneButton.isEnabled = false
			self.navigationItem.leftBarButtonItems = [closeButton]
			self.navigationItem.rightBarButtonItems = [doneButton]
		}
		else {
			/* Navigation bar buttons */
			self.navigationItem.title = "Edit message"
			let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
			let deleteButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteAction(sender:)))
			self.doneButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(doneAction(sender:)))
			self.doneButton.isEnabled = false
			self.navigationItem.leftBarButtonItems = [closeButton]
			self.navigationItem.rightBarButtonItems = [doneButton, UI.spacerFixed, deleteButton]
		}
	}

	func bind() {
        
        /* Creator */
        
        if let user = UserController.instance.user {
            self.userName.text = user.title
            
            if let profilePhoto = user.profile?.photo {
                let url = ImageProxy.url(photo: profilePhoto, category: SizeCategory.profile)
                if !self.userPhotoControl.photoView.associated(withUrl: url) {
                    let fullName = user.title
                    self.userPhotoControl.photoView.image = nil
                    self.userPhotoControl.bind(url: url, name: fullName, colorSeed: user.id)
                }
            }
            else {
                let fullName = user.title
                self.userPhotoControl.bind(url: nil, name: fullName, colorSeed: user.id)
            }
        }
        
        if let message = self.message {
            
            /* Text */
            
            self.messageField.text = message.text
            textViewDidChange(self.messageField)
            
            /* Photo */
            
            if let photo = message.attachments?.values.first?.photo {
                self.photoEditView.configureTo(photoMode: .photo)
                self.photoEditView.isHidden = false
                let url = ImageProxy.url(photo: photo, category: SizeCategory.standard)
                self.photoEditView.bind(url: url)
            }
            else {
                self.photoEditView.configureTo(photoMode: .placeholder)
            }
        }
        else {
            self.photoEditView.configureTo(photoMode: .placeholder)
        }
	}

	func post() {

		self.processing = true
        
        guard let userId = UserController.instance.userId
            , let channelId = StateController.instance.channelId else {
                fatalError("Tried to send/update a message without complete state available")
        }
        
        if self.mode == .update {
            
            let timestamp = FireController.instance.getServerTimestamp()
            var updateMap: [String: Any] = ["modified_at": timestamp]
            let path = self.message.path
            
            if self.photoEditView.photoDirty {
                if self.photoEditView.photoActive {
                    let attachmentId = "at-\(Utils.genRandomId(digits: 9))"
                    let image = self.photoEditView.imageView.image
                    let asset = self.photoEditView.imageView.asset
                    var photoMap: [String: Any]?
                    photoMap = postPhoto(image: image!, asset: asset) { error in
                        if error == nil {
                            photoMap!["uploading"] = NSNull()
                            FireController.db.child(path).child("attachments/\(attachmentId)").setValue(["photo": photoMap!])
                        }
                    }
                    updateMap["attachments"] = [attachmentId: ["photo": photoMap!]]
                }
                else {
                    updateMap["attachments"] = NSNull()
                }
            }
            
            let text = self.messageField.text
            updateMap["text"] = (text == nil || text!.isEmpty) ? NSNull() : text
            
            Reporting.track("send_edited_message")
            FireController.db.child(path).updateChildValues(updateMap)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.MessageDidUpdate), object: self, userInfo: ["message_id":self.message.id!])
            
            self.close(animated: true)
        }
        
        if self.mode == .insert {
            
            var message: [String: Any] = [:]
            let ref = FireController.db.child("channel-messages/\(channelId)").childByAutoId()
            
            if self.photoEditView.photoActive {
                let attachmentId = "at-\(Utils.genRandomId(digits: 9))"
                let image = self.photoEditView.imageView.image
                let asset = self.photoEditView.imageView.asset
                var photoMap: [String: Any]?
                photoMap = postPhoto(image: image!, asset: asset) { error in
                    if error == nil {
                        photoMap!["uploading"] = NSNull()
                        ref.child("attachments/\(attachmentId)").setValue(["photo": photoMap!])
                        Log.d("*** Cleared uploading: \(photoMap!["filename"]!)")
                    }
                }
                message["attachments"] = [attachmentId: ["photo": photoMap!]]
            }
            
            let timestamp = FireController.instance.getServerTimestamp()
            let timestampReversed = -1 * timestamp
            
            message["channel_id"] = channelId
            message["created_at"] = timestamp
            message["created_at_desc"] = timestampReversed
            message["created_by"] = userId
            message["modified_at"] = timestamp
            message["modified_by"] = userId
            
            if let text = self.messageField.text, !text.isEmpty {
                message["text"] = text
            }
            
            ref.setValue(message)
            Reporting.track("send_message")
            
            if UserDefaults.standard.bool(forKey: PerUserKey(key: Prefs.soundEffects)) {
                AudioController.instance.playSystemSound(soundId: 1004) // sms bloop
            }
            
            self.close(animated: true)
        }
	}
    
	func isDirty() -> Bool {

		if self.mode == .insert {
			if !self.messageField.text!.isEmpty {
				return true
			}
			if self.photoEditView.photoDirty {
				return true
			}
		}
		else if self.mode == .update {
			if !stringsAreEqual(string1: self.messageField.text, string2: self.message.text) {
				return true
			}
			if self.photoEditView.photoDirty {
				return true
			}
		}
		return false
	}

	func isValid() -> Bool {
        if ((self.messageField.text == nil || self.messageField.text!.isEmpty)
                && !self.photoEditView.photoActive) {
            UIShared.toast(message: "Add message or photo")
            return false
        }
		return true
	}
}
