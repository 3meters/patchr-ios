//
//  BaseViewController.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import SlackTextViewController
import Photos
import Firebase
import FirebaseDatabaseUI
import FirebaseStorage

class BaseSlackController: SLKTextViewController {
	
    var controllerIsActive = false
    var authHandle: AuthStateDidChangeListenerHandle!
    
    var queryController: DataSourceController!
    var editingComment: FireMessage!
    var inputChannelId: String!
    var inputMessageId: String!
    
    var array: FUIArray!

    override var tableView: UITableView {
        get {
            return super.tableView!
        }
    }
    
	/*--------------------------------------------------------------------------------------------
	* MARK: - Lifecycle
	*--------------------------------------------------------------------------------------------*/
    
    override class func tableViewStyle(for decoder: NSCoder) -> UITableViewStyle {
        return .plain
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.controllerIsActive = (UIApplication.shared.applicationState == .active)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self.tableView, selector: #selector(UITableView.reloadData), name: NSNotification.Name.UIContentSizeCategoryDidChange, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIContentSizeCategoryDidChange, object: nil)
    }

	/*--------------------------------------------------------------------------------------------
	* MARK: - Events
	*--------------------------------------------------------------------------------------------*/
    
    override func didPressRightButton(_ sender: Any!) {
        self.textView.refreshFirstResponder()
        sendComment()
        if UserDefaults.standard.bool(forKey: PerUserKey(key: Prefs.soundEffects)) {
            AudioController.instance.playSystemSound(soundId: 1004) // sms bloop
        }
        super.didPressRightButton(sender)
    }
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Notifications
     *--------------------------------------------------------------------------------------------*/

    @objc func viewDidBecomeActive(sender: NSNotification) {
        /* User either switched to app, launched app, or turned their screen back on with app in foreground. */
        self.controllerIsActive = true
    }
    
    @objc func viewWillResignActive(sender: NSNotification) {
        /* User either switched away from app or turned their screen off. */
        self.controllerIsActive = false
    }

	/*--------------------------------------------------------------------------------------------
	* MARK: - Methods
	*--------------------------------------------------------------------------------------------*/
	
	func initialize() {
        
		self.view.backgroundColor = Theme.colorBackgroundForm
        
        self.bounces = true
        self.isKeyboardPanningEnabled = true
        self.shouldScrollToBottomAfterKeyboardShows = false
        self.isInverted = false
        
        self.rightButton.setTitle("send".localized(), for: UIControlState())
        
        self.textInputbar.autoHideRightButton = false
        self.textInputbar.editorTitle.textColor = UIColor.darkGray
        
        self.typingIndicatorView!.canResignByTouch = true
        
        self.registerPrefixes(forAutoCompletion: ["@",  "#", ":", "+:", "/"])

        NotificationCenter.default.addObserver(self, selector: #selector(viewWillResignActive(sender:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(viewDidBecomeActive(sender:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
	}
    
    func sendComment() {
        
        guard let userId = UserController.instance.userId
            , let channelId = self.inputChannelId
                , let messageId = self.inputMessageId else {
                fatalError("Tried to send a comment without complete state available")
        }
        
        var comment: [String: Any] = [:]
        let ref = FireController.db.child("channel-messages/\(channelId)/\(messageId)/comments").childByAutoId()
        
        let timestamp = FireController.instance.getServerTimestamp()
        let timestampReversed = -1 * timestamp
        
        comment["channel_id"] = channelId
        comment["message_id"] = messageId
        comment["created_at"] = timestamp
        comment["created_at_desc"] = timestampReversed
        comment["created_by"] = userId
        comment["modified_at"] = timestamp
        comment["modified_by"] = userId
        
        if let text = self.textInputbar.textView.text, !text.isEmpty {
            comment["text"] = text
        }
        
        ref.setValue(comment)
        Reporting.track("send_comment")
    }
    
    override func canPressRightButton() -> Bool {
        super.canPressRightButton()
        if self.editingComment != nil {
            return (isValid() && isDirty())
        }
        else {
            return isValid()
        }
    }
    
    func isDirty() -> Bool {
        
        if !stringsAreEqual(string1: self.textView.text, string2: self.editingComment.text) {
            return true
        }
        return false
    }

    func isValid() -> Bool {
        
        if (self.textView.text == nil || self.textView.text!.isEmpty) {
            return false
        }
        return true
    }
    
    func stringsAreEqual(string1: String?, string2: String?) -> Bool {
        if isEmptyString(value: string1) != isEmptyString(value: string2) {
            /* We know one is empty and one is not */
            return false
        }
        else if !isEmptyString(value: string1) {
            /* Both have a value */
            return string1 == string2
        }
        return true // Both are empty
    }
    
    func isEmptyString(value : String?) -> Bool {
        return (value == nil || value!.isEmpty)
    }	
}

extension BaseSlackController {
    
    override func ignoreTextInputbarAdjustment() -> Bool {
        return super.ignoreTextInputbarAdjustment()
    }
    
    override func forceTextInputbarAdjustment(for responder: UIResponder!) -> Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    override func didPasteMediaContent(_ userInfo: [AnyHashable: Any]) {
        // Notifies the view controller when the user has pasted a media (image, video, etc) inside of the text view.
        super.didPasteMediaContent(userInfo)
    }
}
