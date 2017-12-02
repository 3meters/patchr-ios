//
//  MessageEditViewController.swift
//  Patchr
//
//  Created by Jay Massena on 7/24/17.
//  Copyright © 2017 3meters. All rights reserved.
//

import AIFlatSwitch
import BEMCheckBox
import Facade
import Firebase
import MBProgressHUD
import UIKit
import NextGrowingTextView

class MessageEditViewController: BaseEditViewController, BEMCheckBoxDelegate {

	var userGroup = AirRuleView()
	var userPhotoControl = PhotoControl()
	var userName = AirLabelDisplay()
    var messageField: AirTextView!
	var photoEditView = PhotoEditView()
    var photoButton = UIButton()
    var dateGroup = UIView()
    var useTakenDateCheckBox = AIFlatSwitch(frame: .zero)
    var useTakenDateLabel = AirLabelDisplay(frame: .zero)
    var useTakenDateValue = AirLabelDisplay(frame: .zero)
    var doneButton: UIBarButtonItem!

    var message: FireMessage!
    var messageQuery: MessageQuery!
    var inputMessageId: String!
    var inputChannelId: String!
    
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
			let _ = self.messageField.becomeFirstResponder()
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
        
        self.messageField.alignUnder(self.userGroup, matchingCenterWithTopPadding: 8, width: viewWidth - 32, height: max(messageSize.height, 96))
		self.photoEditView.alignUnder(self.messageField, matchingLeftAndRightWithTopPadding: 8, height: viewWidth * 0.75)
        self.photoButton.alignUnder(self.messageField, matchingLeftAndRightWithTopPadding: 8, height: 48)
        
        self.useTakenDateLabel.frame.size.width = viewWidth - (32 + 40 + 8)
        self.useTakenDateLabel.sizeToFit()
        self.useTakenDateValue.sizeToFit()
        self.useTakenDateCheckBox.anchorTopLeft(withLeftPadding: 0, topPadding: 0, width: 40, height: 40)
        self.useTakenDateLabel.align(toTheRightOf: self.useTakenDateCheckBox, matchingTopWithLeftPadding: 8
            , width: self.useTakenDateLabel.width()
            , height: self.useTakenDateLabel.height())
        self.useTakenDateValue.alignUnder(self.useTakenDateLabel, matchingLeftWithTopPadding: 0
            , width: self.useTakenDateValue.width()
            , height: self.useTakenDateValue.height())
        self.dateGroup.resizeToFitSubviews()
        self.useTakenDateCheckBox.anchorCenterLeft(withLeftPadding: 0, width: 40, height: 40)
        self.dateGroup.alignUnder(self.photoEditView, matchingCenterWithTopPadding: 24, width: self.dateGroup.width(), height: self.dateGroup.height())
	}

	/*--------------------------------------------------------------------------------------------
	 * MARK: - Events
	 *--------------------------------------------------------------------------------------------*/

    @objc func closeAction(sender: AnyObject) {
        
        if !isDirty() {
            self.close(animated: true)
            return
        }
        
        deleteConfirmationAlert(
            title: "discard_changes".localized(),
            actionTitle: "discard".localized(), cancelTitle: "cancel".localized(), delegate: self) {
                doIt in
                if doIt {
                    self.close(animated: true)
                }
        }
    }
    
	@objc func doneAction(sender: AnyObject) {

		guard isValid() else { return }
		guard !self.processing else { return }
        
        self.activeTextField?.resignFirstResponder()
        if isValid() {
            Reporting.track(mode == .update ? "update_message": "create_message")
            self.post()
        }
	}
    
    @objc func useTakenDateAction(sender: AnyObject) {
        if let flatSwitch = sender as? AIFlatSwitch {
            Log.v("Switch selected: \(flatSwitch.isSelected)")
        }
    }

	@objc func deleteAction(sender: AnyObject) {

		guard !self.processing else { return }

		deleteConfirmationAlert(
            title: "message_delete_title".localized(),
				message: "message_delete_message".localized(),
				actionTitle: "delete".localized(), cancelTitle: "cancel".localized(), delegate: self) {
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
    }
    
    override func textViewDidEndEditing(_ textView: UITextView) {
        super.textViewDidEndEditing(textView)
        self.doneButton.isEnabled = isDirty()
    }
    
    @objc func setPhotoAction(sender: AnyObject) {
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
        let asset = self.photoEditView.imageView.asset
        if let takenAt = ImageUtils.takenDateFromAsset(asset: asset) {
            self.useTakenDateValue.text = DateUtils.dateMediumString(timestamp: takenAt)
            Log.d("Photo taken: \(String(describing: self.useTakenDateValue.text!))")
            self.view.setNeedsLayout()
            self.dateGroup.fadeIn()
        }
    }
    
    override func didClearPhoto() {
        super.didClearPhoto()
        self.photoButton.fadeIn()
        self.photoEditView.fadeOut()
        self.doneButton.isEnabled = isDirty()
        self.dateGroup.fadeOut()
        self.useTakenDateCheckBox.setSelected(false, animated: false)
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
        self.messageField.initialize()
        self.messageField.minNumberOfLines = 6
        self.messageField.maxNumberOfLines = 6
        self.messageField.delegate = self
        
		self.photoEditView.photoSchema = Schema.entityMessage
		self.photoEditView.setHost(controller: self, view: self.photoEditView)
		self.photoEditView.configureTo(photoMode: .placeholder)
        self.photoEditView.photoDelegate = self
        self.photoEditView.alpha = 0
        
        self.photoButton.setImage(UIImage(named: "UIButtonCamera"), for: .normal)
        self.photoButton.backgroundColor = Theme.colorButtonFill
        self.photoButton.cornerRadius = Theme.dimenButtonCornerRadius
        self.photoButton.borderWidth = Theme.dimenButtonBorderWidth
        self.photoButton.borderColor = Theme.colorButtonBorder
        self.photoButton.alpha = 1
        
        self.photoButton.addTarget(self, action: #selector(setPhotoAction(sender:)), for: .touchUpInside)
        
        self.dateGroup.alpha = 0
        self.useTakenDateLabel.text = "message_use_taken_date".localized()
        self.useTakenDateLabel.numberOfLines = 2
        self.useTakenDateValue.textColor = Theme.colorTextSecondary
        self.useTakenDateCheckBox.lineWidth = 1.0
        self.useTakenDateCheckBox.strokeColor = MaterialColor.green.base
        self.useTakenDateCheckBox.trailStrokeColor = MaterialColor.green.base
        self.useTakenDateCheckBox.addTarget(self, action: #selector(useTakenDateAction(sender:)), for: .touchUpInside)

		self.userGroup.addSubview(self.userPhotoControl)
		self.userGroup.addSubview(self.userName)
        self.dateGroup.addSubview(self.useTakenDateCheckBox)
        self.dateGroup.addSubview(self.useTakenDateLabel)
        self.dateGroup.addSubview(self.useTakenDateValue)
		self.contentHolder.addSubview(self.messageField)
		self.contentHolder.addSubview(self.photoEditView)
        self.contentHolder.addSubview(self.photoButton)
		self.contentHolder.addSubview(self.userGroup)
        self.contentHolder.addSubview(self.dateGroup)

		if self.mode == .insert {
			/* Navigation bar buttons */
			let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
			self.doneButton = UIBarButtonItem(title: nil, style: .plain, target: self, action: #selector(doneAction(sender:)))
			self.doneButton.isEnabled = false
			self.navigationItem.leftBarButtonItems = [closeButton]
			self.navigationItem.rightBarButtonItems = [doneButton]
		}
		else {
			/* Navigation bar buttons */
			let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
			let deleteButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteAction(sender:)))
			self.doneButton = UIBarButtonItem(title: nil, style: .plain, target: self, action: #selector(doneAction(sender:)))
			self.doneButton.isEnabled = false
			self.navigationItem.leftBarButtonItems = [closeButton]
			self.navigationItem.rightBarButtonItems = [doneButton, UI.spacerFixed, deleteButton]
		}
        bindLanguage()
	}
    
    func bindLanguage() {
        self.messageField.placeholderAttributedText = NSAttributedString(
            string: "message_placeholder".localized(),
            attributes: [
                NSAttributedStringKey.font: Theme.fontText,
                NSAttributedStringKey.foregroundColor: Theme.colorTextPlaceholder
            ])
        if self.mode == .insert {
            self.doneButton.title = "post".localized()
        }
        else {
            self.navigationItem.title = "message_edit_title".localized()
            self.doneButton.title = "save".localized()
        }
    }

	func bind() {
        
        /* Creator */
        
        if let user = UserController.instance.user {
            self.userName.text = user.title
            
            if let profilePhoto = user.profile?.photo {
                let url = ImageProxy.url(photo: profilePhoto, category: SizeCategory.profile)
                if !self.userPhotoControl.imageView.associated(withUrl: url) {
                    let fullName = user.title
                    self.userPhotoControl.imageView.image = nil
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
            
            self.messageField.textView.text = message.text
            textViewDidChange(self.messageField.textView)
            
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
            
            let timestampModified = FireController.instance.getServerTimestamp()
            var timestamp = timestampModified
            var timestampReversed = -1 * timestamp
            var mutateCreatedDate = false
            var updateMap: [String: Any] = [:]
            
            if self.useTakenDateCheckBox.isSelected {
                let asset = self.photoEditView.imageView.asset
                if let takenAt = ImageUtils.takenDateFromAsset(asset: asset) {
                    timestamp = takenAt
                    timestampReversed = -1 * timestamp
                    mutateCreatedDate = true
                }
            }
            
            if mutateCreatedDate {
                updateMap["created_at"] = timestamp
                updateMap["created_at_desc"] = timestampReversed
                updateMap["modified_at"] = timestampModified
            }
            else {
                updateMap["modified_at"] = timestampModified
            }
            
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
            
            let text = self.messageField.textView.text
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
            
            var timestamp = FireController.instance.getServerTimestamp()
            var timestampReversed = -1 * timestamp
            
            if self.useTakenDateCheckBox.isSelected {
                let asset = self.photoEditView.imageView.asset
                if let takenAt = ImageUtils.takenDateFromAsset(asset: asset) {
                    timestamp = takenAt
                    timestampReversed = -1 * timestamp
                }
            }
            
            message["channel_id"] = channelId
            message["created_at"] = timestamp
            message["created_at_desc"] = timestampReversed
            message["created_by"] = userId
            message["modified_at"] = timestamp
            message["modified_by"] = userId
            
            if let text = self.messageField.textView.text, !text.isEmpty {
                message["text"] = text
            }
            
            ref.setValue(message)
            Reporting.track("send_message")
            
            if UserDefaults.standard.bool(forKey: PerUserKey(key: Prefs.soundEffects)) {
                AudioController.instance.playSystemSound(soundId: 1004) // sms bloop
            }
            Utils.incrementUserActions()
            self.close(animated: true)
        }
	}
    
	func isDirty() -> Bool {

		if self.mode == .insert {
			if !self.messageField.textView.text!.isEmpty {
				return true
			}
			if self.photoEditView.photoDirty {
				return true
			}
		}
		else if self.mode == .update {
			if !stringsAreEqual(string1: self.messageField.textView.text, string2: self.message.text) {
				return true
			}
			if self.photoEditView.photoDirty {
				return true
			}
		}
		return false
	}

	func isValid() -> Bool {
        if ((self.messageField.textView.text == nil || self.messageField.textView.text!.isEmpty)
                && !self.photoEditView.photoActive) {
            UIShared.toast(message: "message_edit_empty".localized())
            return false
        }
		return true
	}
}
