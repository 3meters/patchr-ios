//
//  BaseViewController.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import AWSS3
import SlackTextViewController
import Photos
import Firebase
import FirebaseDatabaseUI

class BaseSlackController: SLKTextViewController {
	
    var controllerIsActive = false
    var authHandle: FIRAuthStateDidChangeListenerHandle!
    
    var queryController: DataSourceController!
    var channel: FireChannel!
    var searchResult: [String]?
    var editingMessage: FireMessage!
    var messageId: String!
    
    var photoEditView: PhotoEditView!
    var photoDirty: Bool = false
    var photoActive: Bool = false
    var photoChosen: Bool = false
    var photoHolder	: UIVisualEffectView!
    var rule = UIView()
	
    var array: FUIArray!

    override var tableView: UITableView {
        get {
            return super.tableView!
        }
    }
    
	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
    
    override class func tableViewStyle(for decoder: NSCoder) -> UITableViewStyle {
        return .plain
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.controllerIsActive = (UIApplication.shared.applicationState == .active)
    }
    
    override func viewWillLayoutSubviews() {
        let holderWidth = self.view.width()
        let holderHeight = CGFloat((288 * 0.56) + 32)
        self.photoHolder.frame.size = CGSize(width: holderWidth, height: holderHeight)
        self.photoHolder.frame.origin.x = 0
        self.photoEditView.anchorInCenter(withWidth: 288, height: CGFloat(288 * 0.56))
        self.rule.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 0.5)
        super.viewWillLayoutSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
        NotificationCenter.default.addObserver(self.tableView, selector: #selector(UITableView.reloadData), name: NSNotification.Name.UIContentSizeCategoryDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(textInputbarDidMove(_:)), name: NSNotification.Name.SLKTextInputbarDidMove, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIContentSizeCategoryDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.SLKTextInputbarDidMove, object: nil)
    }
    
    deinit {
        Log.d("BaseSlackController released")
    }
	
	/*--------------------------------------------------------------------------------------------
	* Events
	*--------------------------------------------------------------------------------------------*/

    func editPhotoAction(sender: AnyObject) {
        hidePhotoEdit()
        self.photoEditView.editPhotoAction(sender: sender)
    }
    
    override func didPressLeftButton(_ sender: Any!) {
        super.didPressLeftButton(sender)
        
        if let controller = self as? ChannelViewController {
            controller.isTyping = true
        }
        
        self.dismissKeyboard(true)
        self.photoEditView.photoChooser?.choosePhoto(sender: sender as AnyObject) { [weak self] image, imageResult, asset, cancelled in
            if let controller = self as? ChannelViewController {
                controller.isTyping = false
            }
            if !cancelled {
                if image != nil || imageResult != nil {
                    DispatchQueue.main.async {
                        self?.photoEditView.photoChosen(image: image, imageResult: imageResult, asset: asset)
                        self?.showPhotoEdit()
                    }
                }
            }
        }
    }
    
    override func didPressRightButton(_ sender: Any!) {
        self.textView.refreshFirstResponder()
        
        sendMessage()
        
        hidePhotoEdit()
        self.photoEditView.reset()
        
        if self.queryController.items.count > 0 {
            let indexPath = IndexPath(row: 0, section: 0)
            let scrollPosition: UITableViewScrollPosition = self.isInverted ? .bottom : .bottom
            self.tableView.scrollToRow(at: indexPath, at: scrollPosition, animated: true)
        }
        
        if let controller = self as? ChannelViewController {
            controller.isTyping = false
        }
        
        super.didPressRightButton(sender)
    }
    
    override func didCommitTextEditing(_ sender: Any) {
        self.textView.refreshFirstResponder()
        dismissKeyboard(true)
        updateMessage()
        hidePhotoEdit()
        self.photoEditView.reset()
        super.didCommitTextEditing(sender)
    }
    
    override func didCancelTextEditing(_ sender: Any) {
        super.didCancelTextEditing(sender)
        self.editingMessage = nil
        self.textInputbar.endTextEdition()
        dismissKeyboard(true)
        hidePhotoEdit()
        self.photoEditView.reset()
    }

    /*--------------------------------------------------------------------------------------------
     * Notifications
     *--------------------------------------------------------------------------------------------*/

    func photoDidChange(sender: NSNotification) {
        textDidUpdate(true)
        showPhotoEdit()
    }
    
    func photoRemoved(sender: NSNotification) {
        textDidUpdate(true)
        hidePhotoEdit()
    }

    func textInputbarDidMove(_ note: Notification) {
        
        guard let userInfo = (note as NSNotification).userInfo
            , let value = userInfo["origin"] as? NSValue else { return }
        
        /* Keep photo edit view positioned above the input bar.*/
        var frame = self.photoHolder.frame
        frame.origin.y = value.cgPointValue.y - (self.photoHolder.height() - 1)
        self.photoHolder.frame = frame
    }
    
    func viewDidBecomeActive(sender: NSNotification) {
        /* User either switched to app, launched app, or turned their screen back on with app in foreground. */
        self.controllerIsActive = true
    }
    
    func viewWillResignActive(sender: NSNotification) {
        /* User either switched away from app or turned their screen off. */
        self.controllerIsActive = false
    }

	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	func initialize() {
        
		self.view.backgroundColor = Theme.colorBackgroundForm
        
        self.photoHolder = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        self.photoHolder.isHidden = true
        self.photoHolder.alpha = 0.0
        
        self.photoEditView = PhotoEditView()
        self.photoEditView.setHost(controller: self, view: self.leftButton)
        self.photoEditView.configureTo(photoMode: .photo)
        
        self.rule.backgroundColor = Theme.colorRule
        
        self.photoHolder.contentView.addSubview(self.rule)
        self.photoHolder.contentView.addSubview(self.photoEditView)
        self.view.addSubview(self.photoHolder)
        
        self.bounces = true
        self.isKeyboardPanningEnabled = true
        self.shouldScrollToBottomAfterKeyboardShows = false
        self.isInverted = false
        
        self.leftButton.setImage(#imageLiteral(resourceName: "UIButtonCamera"), for: UIControlState())
        self.leftButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
        
        self.rightButton.setTitle(NSLocalizedString("Send", comment: ""), for: UIControlState())
        
        self.textInputbar.autoHideRightButton = false
        self.textInputbar.showLeftButtonWhenEditing = true
        self.textInputbar.editorTitle.textColor = UIColor.darkGray
        
        self.typingIndicatorView!.canResignByTouch = true
        
        self.tableView.separatorStyle = .none
        self.registerPrefixes(forAutoCompletion: ["@",  "#", ":", "+:", "/"])

        self.photoEditView.editPhotoButton.addTarget(self, action: #selector(editPhotoAction(sender:)), for: .touchUpInside)
        
        NotificationCenter.default.addObserver(self, selector: #selector(photoDidChange(sender:)), name: NSNotification.Name(rawValue: Events.PhotoDidChange), object: self.photoEditView)
        NotificationCenter.default.addObserver(self, selector: #selector(photoRemoved(sender:)), name: NSNotification.Name(rawValue: Events.PhotoRemoved), object: self.photoEditView)
        NotificationCenter.default.addObserver(self, selector: #selector(viewWillResignActive(sender:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(viewDidBecomeActive(sender:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
	}
    
    func editMessage(message: FireMessage) {
        self.editingMessage = message
        self.textInputbar.beginTextEditing()
        if message.text != nil {
            self.editText(message.text!)
        }
        
        if let photo = message.attachments?.values.first?.photo {
            let photoUrl = Cloudinary.url(prefix: photo.filename)
            self.photoEditView.configureTo(photoMode: .photo)
            self.photoEditView.bind(url: photoUrl, uploading: photo.uploading)
            showPhotoEdit()
        }
    }
    
    func sendMessage() {
        
        guard let userId = UserController.instance.userId
            , let groupId = StateController.instance.groupId
            , let channelId = StateController.instance.channelId
            , let username = UserController.instance.user!.username
            , let channelName = self.channel.name else {
                fatalError("Tried to send a message without complete state available")
        }
        
        let attachmentId = "at-\(Utils.genRandomId())"
        let ref = FireController.db.child("group-messages/\(groupId)/\(channelId)").childByAutoId()
        
        var photoMap: [String: Any]?
        if let image = self.photoEditView.imageButton.image {
            let asset = self.photoEditView.imageButton.asset
            photoMap = postPhoto(image: image, asset: asset, progress: self.photoEditView.progressBlock, next: { error in
                if error == nil {
                    photoMap!["uploading"] = NSNull()
                    ref.child("attachments/\(attachmentId)").setValue(["photo": photoMap!])
                    Log.d("*** Cleared uploading: \(photoMap!["filename"]!)")
                }
            })
        }
        
        let timestamp = FireController.instance.getServerTimestamp()
        let timestampReversed = -1 * timestamp
        
        var task: [String: Any] = [:]
        task["channel_id"] = channelId
        task["channelName"] = channelName
        task["created_at"] = timestamp
        task["created_by"] = userId
        task["group_id"] = groupId
        task["id"] = ref.key
        task["state"] = "waiting"
        task["username"] = username
        
        var message: [String: Any] = [:]
        message["channel_id"] = channelId
        message["created_at"] = timestamp
        message["created_at_desc"] = timestampReversed
        message["created_by"] = userId
        message["group_id"] = groupId
        message["modified_at"] = timestamp
        message["modified_by"] = userId
        message["source"] = "user"
        
        if let text = self.textInputbar.textView.text, !text.isEmpty {
            message["text"] = text
            task["text"] = text
        }
        
        if photoMap != nil {
            message["attachments"] = [attachmentId: ["photo": photoMap!]]
            task["photo"] = photoMap!
        }
        
        ref.setValue(message)
        
        let path = "queue/notifications/\(ref.key)"
        FireController.db.child(path).setValue(task) { error, ref in
            if error != nil {
                Log.w("Permission denied: \(path)")
            } else {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.MessageDidUpdate), object: self, userInfo: ["message_id":ref.key])
            }
        }
    }
    
    func updateMessage() {
        
        let timestamp = FireController.instance.getServerTimestamp()
        var updateMap: [String: Any] = ["modified_at": timestamp]
        let path = self.editingMessage.path
        
        if self.photoEditView.photoDirty {
            var photoMap: [String: Any]?
            let attachmentId = "at-\(Utils.genRandomId())"
            if let image = self.photoEditView.imageButton.image {
                let asset = self.photoEditView.imageButton.asset
                photoMap = postPhoto(image: image, asset: asset, progress: self.photoEditView.progressBlock, next: { error in
                    if error == nil {
                        photoMap!["uploading"] = NSNull()
                        FireController.db.child(path).child("attachments/\(attachmentId)").setValue(["photo": photoMap!])
                    }
                })
            }
            
            if photoMap != nil {
                updateMap["attachments"] = [attachmentId: ["photo": photoMap!]]
            }
            else {
                updateMap["attachments"] = NSNull()
            }
        }
        
        let text = self.textInputbar.textView.text
        updateMap["text"] = (text == nil || text!.isEmpty) ? NSNull() : text
        
        FireController.db.child(path).updateChildValues(updateMap)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.MessageDidUpdate), object: self, userInfo: ["message_id":self.editingMessage.id!])
    }
    
    func postPhoto(image: UIImage
        , asset: Any?
        , progress: AWSS3TransferUtilityProgressBlock? = nil
        , next: ((Any?) -> Void)? = nil) -> [String: Any] {
        
        /* Ensure image is resized/rotated before upload */
        let preparedImage = ImageUtils.prepareImage(image: image)
        
        /* Generate image key */
        let imageKey = "\(Utils.genImageKey()).jpg"
        
        var photoMap = [
            "filename": imageKey,
            "height": Int(preparedImage.size.height),
            "source": S3.instance.imageSource,
            "width": Int(preparedImage.size.width), // width/height are in points...should be pixels?
            "uploading": true] as [String: Any]
        
        if let asset = asset as? PHAsset {
            if let takenDate = asset.creationDate {
                photoMap["taken_at"] = takenDate.milliseconds
                Log.d("Photo taken: \(takenDate)")
            }
            if let coordinate = asset.location?.coordinate {
                photoMap["location"] = ["lat": coordinate.latitude, "lng": coordinate.longitude]
                Log.d("Photo lat/lng: \(coordinate)")
            }
        }
        else if let asset = asset as? [String: Any] {
            if let takenDate = asset["taken_at"] as? Int {
                photoMap["taken_at"] = takenDate
                Log.d("Photo taken: \(takenDate)")
            }
        }
        
        let imageData = UIImageJPEGRepresentation(image, /*compressionQuality*/ 0.70)!
        
        /* Prime the cache so offline has something to work with */
        let photoUrlStandard = Cloudinary.url(prefix: imageKey, category: SizeCategory.standard)
        let photoUrlProfile = Cloudinary.url(prefix: imageKey, category: SizeCategory.profile)
        ImageUtils.storeImageDataToCache(imageData: imageData, key: photoUrlProfile.absoluteString)
        ImageUtils.storeImageDataToCache(imageData: imageData, key: photoUrlStandard.absoluteString)
        
        /* Upload */
        DispatchQueue.global(qos: .userInitiated).async {
            S3.instance.upload(imageData: imageData, imageKey: imageKey, progress: progress) { task, error in
                Log.w(error != nil
                    ? "*** S3 image upload stopped with error: \(error!.localizedDescription)"
                    : "*** S3 image upload complete: \(imageKey)")
                next?(error)
            }
        }
        
        return photoMap
    }

    func showPhotoEdit() {
        
        if self.photoHolder.isHidden {
            self.photoHolder.frame.origin.y = (self.textInputbar.frame.minY - (self.photoHolder.height() - 1))
            self.photoHolder.isHidden = false
            self.photoHolder.alpha = 0.0
            
            UIView.animate(withDuration: 0.25, animations: { [unowned self] () -> Void in
                self.photoHolder.alpha = 1.0
            })
        }
    }
    
    func hidePhotoEdit() {
        if !self.photoHolder.isHidden {
            UIView.animate(withDuration: 0.3, animations: { [unowned self] () -> Void in
                self.photoHolder.alpha = 0.0
                }, completion: { [unowned self] (finished) -> Void in
                    self.photoHolder.isHidden = true
            })
        }
    }
    
    override func canPressRightButton() -> Bool {
        super.canPressRightButton()
        if self.editingMessage != nil {
            return (isValid() && isDirty())
        }
        else {
            return isValid()
        }
    }
    
    func isDirty() -> Bool {
        
        if !stringsAreEqual(string1: self.textView.text, string2: self.editingMessage.text) {
            return true
        }
        if self.photoEditView.photoDirty {
            return true
        }
        return false
    }

    func isValid() -> Bool {
        
        if ((self.textView.text == nil || self.textView.text!.isEmpty)
            && self.photoEditView.imageButton.image == nil) {
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
    
    func hideOrShowTextInputbar() {
        let hide = !self.isTextInputbarHidden
        self.setTextInputbarHidden(hide, animated: true)
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }
    
    override var prefersStatusBarHidden: Bool {
        return UserDefaults.standard.bool(forKey: Prefs.statusBarHidden)
    }
}

extension BaseSlackController {
    
    override func ignoreTextInputbarAdjustment() -> Bool {
        return super.ignoreTextInputbarAdjustment()
    }
    
    override func forceTextInputbarAdjustment(for responder: UIResponder!) -> Bool {
        
        if #available(iOS 8.0, *) {
            guard let _ = responder as? UIAlertController else {
                // On iOS 9, returning YES helps keeping the input view visible when the keyboard if presented from another app when using multi-tasking on iPad.
                return UIDevice.current.userInterfaceIdiom == .pad
            }
            return true
        }
        else {
            return UIDevice.current.userInterfaceIdiom == .pad
        }
    }
    
    override func didPasteMediaContent(_ userInfo: [AnyHashable: Any]) {
        // Notifies the view controller when the user has pasted a media (image, video, etc) inside of the text view.
        super.didPasteMediaContent(userInfo)
        
        let mediaType = (userInfo[SLKTextViewPastedItemMediaType] as? NSNumber)?.intValue
        let contentType = userInfo[SLKTextViewPastedItemContentType]
        let data = userInfo[SLKTextViewPastedItemData]
        
        print("didPasteMediaContent : \(contentType) (type = \(mediaType) | data : \(data))")
    }
    
    override func didChangeAutoCompletionPrefix(_ prefix: String, andWord word: String) {
        
        let array:Array<String> = []
        //let wordPredicate = NSPredicate(format: "self BEGINSWITH[c] %@", word);
        
        self.searchResult = nil
        
        if prefix == "@" {
            if word.characters.count > 0 {
                //array = self.users.filter { wordPredicate.evaluate(with: $0) };
            }
            else {
                //array = self.users
            }
        }
        else if prefix == "#" {
            
            if word.characters.count > 0 {
                //array = self.channels.filter { wordPredicate.evaluate(with: $0) };
            }
            else {
                //array = self.channels
            }
        }
        else if (prefix == ":" || prefix == "+:") && word.characters.count > 0 {
            //array = self.emojis.filter { wordPredicate.evaluate(with: $0) };
        }
        else if prefix == "/" && self.foundPrefixRange.location == 0 {
            if word.characters.count > 0 {
                //array = self.commands.filter { wordPredicate.evaluate(with: $0) };
            }
            else {
                //array = self.commands
            }
        }
        
        var show = false
        
        if array.count > 0 {
            let sortedArray = array.sorted { $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending }
            self.searchResult = sortedArray
            show = sortedArray.count > 0
        }
        
        self.showAutoCompletionView(show)
    }
    
    override func heightForAutoCompletionView() -> CGFloat {
        
        guard let searchResult = self.searchResult else {
            return 0
        }
        
        let cellHeight = self.autoCompletionView.delegate?.tableView!(self.autoCompletionView, heightForRowAt: IndexPath(row: 0, section: 0))
        guard let height = cellHeight else {
            return 0
        }
        
        return height * CGFloat(searchResult.count)
    }
}
