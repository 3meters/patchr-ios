//
//  RegistrationTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-24.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

enum MessageType: Int {
	case Content
	case Share
}

class MessageEditViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
	
	var inputState			: State? = State.Editing
	var inputMessageType	: MessageType = .Content
	var inputEntity			: Entity?
	var inputToString		: String?     // name of patch this message links to
	var inputPatchId		: String?     // id of patch this message links to
	
	var inputShareId		: String?
	var inputShareSchema	: String = Schema.PHOTO
	var inputShareEntity	: Entity?
	
	var processing			: Bool = false
	var progressStartLabel	: String?
	var progressFinishLabel	: String?
	var cancelledLabel		: String?
	var schema				= Schema.ENTITY_MESSAGE
	var progress			: AirProgress?
	var activeTextField		: UIView?
	var insertedEntity		: Entity?
	var firstAppearance		= true
	
	var imageUploadRequest	: AWSS3TransferManagerUploadRequest?
	var entityPostRequest	: NSURLSessionTask?
	
	var descriptionDefault: String!

	let contactsSelected	: NSMutableArray = NSMutableArray()
	var contactModels		: NSMutableArray = NSMutableArray()
	var contactList			: UITableView?

	var searchInProgress    = false
	var searchTimer			: NSTimer?
	var searchEditing       = false
	var searchText			: String = ""

	var addressGroup		= AirRuleView()
	var addressField		= AirContactPicker()
	var addressLabel		= AirLabelDisplay()

	var userPhoto			= AirImageView(frame: CGRectZero)
	var userName			= AirLabelDisplay()
	var descriptionField	= AirTextView()
	var photoView			= PhotoView()
	
	var messageView			: MessageView?
	var patchView			: PatchView?
	var doneButton			= AirButtonFeatured()
	
	var scrollView			= AirScrollView()
	var contentHolder		= UIView()
	
	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }
	
	override func loadView() {
		super.loadView()
		initialize()
	}
	
	override func viewDidAppear(animated: Bool) {
		if self.inputState == State.Sharing {
			self.addressField.becomeFirstResponder()
		}
		else if self.inputState == State.Creating && self.firstAppearance  {
			self.descriptionField.becomeFirstResponder()
		}
	}
	
	override func viewWillAppear(animated: Bool) {
		let notificationCenter = NSNotificationCenter.defaultCenter()
		notificationCenter.addObserver(self, selector: "dismissKeyboard", name: Events.PhotoViewHasFocus, object: nil)
		notificationCenter.addObserver(self, selector: "keyboardWillBeShown:", name: UIKeyboardWillShowNotification, object: nil)
		notificationCenter.addObserver(self, selector: "keyboardWillBeHidden:", name: UIKeyboardWillHideNotification, object: nil)
		notificationCenter.addObserver(self, selector: "photoDidChange:", name: Events.PhotoDidChange, object: nil)
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		self.firstAppearance = false
	}
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		let statusHeight = UIApplication.sharedApplication().statusBarFrame.size.height
		let navHeight = self.navigationController?.navigationBar.height() ?? 0
		let contentWidth = self.view.bounds.size.width - 32
		let descriptionSize = self.descriptionField.sizeThatFits(CGSizeMake(contentWidth, CGFloat.max))
		
		if self.inputState == .Sharing {
			
			self.userPhoto.anchorTopLeftWithLeftPadding(16, topPadding: 8, width: 48, height: 48)
			self.addressField.setNeedsLayout()
			self.addressField.layoutIfNeeded()
			self.addressField.anchorTopLeftWithLeftPadding(72, topPadding: 12, width: contentWidth - 56, height: self.addressField.height())
			self.contactList!.alignUnder(self.addressField, matchingLeftAndRightWithTopPadding: 0, height: CGFloat(self.contactModels.count * 52))
			self.addressGroup.anchorTopCenterFillingWidthWithLeftAndRightPadding(0, topPadding: 64, height: self.contactList!.height() + self.addressField.height() + 24)
			self.descriptionField.anchorTopCenterFillingWidthWithLeftAndRightPadding(0, topPadding: 0, height: max(96, descriptionSize.height))
			
			if self.inputShareSchema == Schema.ENTITY_PATCH {
				self.patchView!.alignUnder(self.descriptionField, matchingLeftAndRightWithTopPadding: 8, height: 128)
			}
			else {
				self.messageView!.alignUnder(self.descriptionField, matchingRightAndFillingWidthWithLeftPadding: 0, topPadding: 16, height: 400)
			}
		}
		else {			
			self.addressGroup.anchorTopCenterFillingWidthWithLeftAndRightPadding(0, topPadding: CGFloat(statusHeight + navHeight), height: 64)
			self.userPhoto.anchorCenterLeftWithLeftPadding(16, width: 48, height: 48)
			self.addressLabel.fillSuperviewWithLeftPadding(72, rightPadding: 8, topPadding: 0, bottomPadding: 0)
			self.descriptionField.anchorTopCenterFillingWidthWithLeftAndRightPadding(0, topPadding: 0, height: max(96, descriptionSize.height))
			self.photoView.alignUnder(self.descriptionField, matchingLeftAndRightWithTopPadding: 8, height: self.photoView.photoMode == .Empty ? 48 : contentWidth * 0.75)
		}
		
		self.contentHolder.resizeToFitSubviews()
		self.scrollView.contentSize = CGSizeMake(self.contentHolder.frame.size.width, self.contentHolder.frame.size.height + CGFloat(32))
		self.scrollView.alignUnder(self.addressGroup, centeredFillingWidthAndHeightWithLeftAndRightPadding: 0, topAndBottomPadding: 0)
		self.contentHolder.anchorTopCenterFillingWidthWithLeftAndRightPadding(16, topPadding: 8, height: self.contentHolder.height() + 32)
	}
	
	func doneAction(sender: AnyObject){
		
		guard isValid() else { return }
		guard !self.processing else { return }
		
		self.progress = AirProgress.showHUDAddedTo(self.view.window, animated: true)
		self.progress!.mode = MBProgressHUDMode.Indeterminate
		self.progress!.styleAs(.ActivityWithText)
		self.progress!.labelText = self.progressStartLabel
		self.progress!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("userCancelTaskAction:")))
		self.progress!.removeFromSuperViewOnHide = true
		self.progress!.show(true)

		Utils.delay(5.0) {
			self.progress?.detailsLabelText = "Tap to cancel"
		}
		
		let parameters = self.gather(NSMutableDictionary())
		
		post(parameters)
		
	}
	
	func cancelAction(sender: AnyObject){
		
		if !isDirty() {
			self.performBack(true)
			return
		}
		
		ActionConfirmationAlert(
			"Do you want to discard your editing changes?",
			actionTitle: "Discard", cancelTitle: "Cancel", delegate: self) {
				doIt in
				if doIt {
					self.performBack(true)
				}
		}
	}
	
	func deleteAction(sender: AnyObject) {
		
		guard !self.processing else { return }
		
		ActionConfirmationAlert(
			"Confirm Delete",
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
			hud.animationType = MBProgressHUDAnimation.ZoomIn
			hud.hide(true)
			self.imageUploadRequest?.cancel() // Should do nothing if upload already complete or isn't any
			self.entityPostRequest?.cancel()
		}
	}
	
	func photoDidChange(sender: AnyObject) {
		viewWillLayoutSubviews()
	}

	/*--------------------------------------------------------------------------------------------
	 * Methods
	 *--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
		let fullScreenRect = UIScreen.mainScreen().applicationFrame
		self.scrollView.frame = fullScreenRect
		self.scrollView.backgroundColor = Theme.colorBackgroundScreen
		
		self.photoView.photoSchema = Schema.ENTITY_MESSAGE
		self.photoView.setHostController(self)
		self.photoView.configureTo(self.inputEntity?.photo != nil ? .Photo : .Empty)
		
		self.descriptionField = AirTextView()
		self.descriptionField.placeholderLabel.text = "What\'s happening?"
		self.descriptionField.placeholderLabel.insets = UIEdgeInsetsMake(0, 0, 0, 0)
		self.descriptionField.initialize()
		self.descriptionField.delegate = self
		
		self.userPhoto.contentMode = UIViewContentMode.ScaleAspectFill
		self.userPhoto.clipsToBounds = true
		self.userPhoto.layer.cornerRadius = 24
		
		self.addressGroup.backgroundColor = UIColor(red: CGFloat(0.98), green: CGFloat(0.98), blue: CGFloat(0.98), alpha: CGFloat(1))
		self.addressGroup.thickness = 0.5
		
		self.addressGroup.addSubview(self.addressLabel)
		self.addressGroup.addSubview(self.addressField)
		self.addressGroup.addSubview(self.userPhoto)
		self.contentHolder.addSubview(self.descriptionField)
		self.contentHolder.addSubview(self.photoView)
		self.scrollView.addSubview(self.contentHolder)
		
		self.view.addSubview(self.addressGroup)
		self.view.addSubview(self.scrollView)
		
		if self.inputState == State.Sharing {
			
			self.photoView.hidden = true
			self.addressLabel.hidden = true
			
			self.addressField.setPlaceholderLabelText("Who would you like to invite?")
			self.addressField.setPromptLabelText("To: ")
			self.addressField.delegate = self
			
			self.contactList = UITableView(frame: CGRectZero, style: .Plain)
			self.contactList!.delegate = self;
			self.contactList!.dataSource = self;
			self.contactList!.rowHeight = 52
			self.addressGroup.addSubview(self.contactList!)
			
			if self.inputShareSchema == Schema.ENTITY_PATCH {
				
				setScreenName("PatchInvite")
				
				self.progressStartLabel = "Inviting"
				self.progressFinishLabel = "Invites sent"
				self.cancelledLabel = "Invites cancelled"
				
				self.patchView = PatchView()
				self.patchView!.borderColor = Theme.colorButtonBorder
				self.patchView!.borderWidth = Theme.dimenButtonBorderWidth
				self.patchView!.cornerRadius = 6
				self.patchView!.shadow.backgroundColor = Colors.clear
				
				self.contentHolder.addSubview(self.patchView!)
				
				self.descriptionField.placeholderLabel.text = "Add a message to your invite..."
				self.navigationItem.title = "Invite to patch"
				self.descriptionDefault = "\(UserController.instance.currentUser.name) invited you to the \'\(self.inputShareEntity!.name!)\' patch."
			}
				
			else if self.inputShareSchema == Schema.ENTITY_MESSAGE {
				
				setScreenName("MessageShare")
				
				self.progressStartLabel = "Sharing"
				self.progressFinishLabel = "Shared"
				self.cancelledLabel = "Sharing cancelled"
				
				var cellType: CellType = .TextAndPhoto
				if self.inputShareEntity!.photo == nil {
					cellType = .Text
				}
				else if self.inputShareEntity!.description_ == nil {
					cellType = .Photo
				}
				
				self.messageView = MessageView(cellType: cellType)
				self.contentHolder.addSubview(self.messageView!)
				
				self.descriptionField.placeholderLabel.text = "Add a message..."
				self.navigationItem.title = Utils.LocalizedString("Share message")
				if let message = self.inputShareEntity as? Message {
					if message.patch != nil {
						self.descriptionDefault = "\(UserController.instance.currentUser.name) shared \(message.creator.name!)\'s message to the \'\(message.patch.name)\' patch."
					}
					else {
						self.descriptionDefault = "\(UserController.instance.currentUser.name) shared \(message.creator.name!)\'s message to a patch."
					}
				}
			}
			
			/* Navigation bar buttons */
			let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancelAction:")
			let doneButton = UIBarButtonItem(title: "Send", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("doneAction:"))
			self.navigationItem.leftBarButtonItems = [cancelButton]
			self.navigationItem.rightBarButtonItems = [doneButton]
		}
		else {
			
			self.addressField.hidden = true
			
			self.descriptionField.placeholderLabel.text = "What\'s happening?"
			
			if self.inputState == State.Creating {
				setScreenName("MessageNew")
				self.progressStartLabel = "Sending"
				self.progressFinishLabel = "Sent"
				self.cancelledLabel = "Send cancelled"
				
				/* Navigation bar buttons */
				let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancelAction:")
				let doneButton = UIBarButtonItem(title: "Send", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("doneAction:"))
				self.navigationItem.leftBarButtonItems = [cancelButton]
				self.navigationItem.rightBarButtonItems = [doneButton]
			}
			else {
				setScreenName("MessageEdit")
				self.progressStartLabel = "Updating"
				self.progressFinishLabel = "Updated"
				self.cancelledLabel = "Update cancelled"
				
				self.doneButton.hidden = true
				
				/* Navigation bar buttons */
				self.navigationItem.title = "Edit message"
				let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancelAction:")
				let deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: "deleteAction:")
				let doneButton = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: "doneAction:")
				self.navigationItem.leftBarButtonItems = [cancelButton]
				self.navigationItem.rightBarButtonItems = [doneButton, Utils.spacer, deleteButton]
			}
		}
	}
	
    func bind() {
		
		if let message = self.inputEntity as? Message {
			self.userPhoto.setImageWithPhoto(message.creator.getPhotoManaged())
			self.userName.text = message.creator.name
		}
		else if let user = UserController.instance.currentUser {
			self.userPhoto.setImageWithPhoto(user.getPhotoManaged())
			self.userName.text = user.name
		}

		if self.inputState == .Editing {
			self.addressLabel.text = (self.inputEntity as! Message).patch?.name
			self.descriptionField.text = self.inputEntity!.description_
			self.photoView.bindPhoto(self.inputEntity!.photo)
			textViewDidChange(self.descriptionField)
		}
		else if self.inputState == .Creating {
			self.addressLabel.text = self.inputToString! + " Patch"
		}
		else if self.inputState == .Sharing {
			if self.inputShareSchema == Schema.ENTITY_PATCH {
				self.patchView!.bindToEntity(self.inputShareEntity!, location: nil)

			}
			else {
				self.messageView!.bindToEntity(self.inputShareEntity!)
				self.messageView!.setNeedsLayout()
				self.messageView!.layoutIfNeeded()
			}
		}
    }
	
	func post(parameters: NSMutableDictionary) -> TaskQueue {
		/*
		 * Has external dependencies: progress, tasks, processing flag.
		 */
		
		self.processing = true
		var cancelled = false
		let queue = TaskQueue()
		
		/* Process image if any */
		
		if var image = parameters["photo"] as? UIImage {
			queue.tasks +=~ { _, next in
				
				/* Ensure image is resized/rotated before upload */
				image = Utils.prepareImage(image)
				
				/* Generate image key */
				let imageKey = "\(Utils.genImageKey()).jpg"
				
				/* Upload */
				self.imageUploadRequest = S3.sharedService.uploadImageToS3(image, imageKey: imageKey) {
					task in
					
					if let error = task.error {
						if error.domain == AWSS3TransferManagerErrorDomain as String {
							if let errorCode = AWSS3TransferManagerErrorType(rawValue: error.code) {
								if errorCode == .Cancelled {
									cancelled = true
								}
							}
						}
						queue.skip()
						next(Result(response: nil, error: error))
					}
					else {
						let photo = [
							"width": Int(image.size.width), // width/height are in points...should be pixels?
							"height": Int(image.size.height),
							"source": S3.sharedService.imageSource,
							"prefix": imageKey
						]
						parameters["photo"] = photo
						next(nil)
					}
				}
			}
		}
		
		/* Upload entity */
		
		queue.tasks +=~ { _, next in
			let endpoint = self.inputEntity == nil ? "data/messages" : "data/messages/\(self.inputEntity!.id_!)"
			self.entityPostRequest = DataController.proxibase.postEntity(endpoint, parameters: parameters) {
				response, error in
				if error == nil {
					self.progress!.progress = 1.0
				}
				else if error!.code == NSURLErrorCancelled {
					cancelled = true
				}
				next(Result(response: response, error: error))
			}
		}
		
		/* Update Ui */
		
		queue.tasks +=! {
			self.processing = false
			
			if cancelled {
				Shared.Toast(self.cancelledLabel)
				return
			}
			
			self.progress?.hide(true)
			
			if let result: Result = queue.lastResult as? Result {
				if let error = ServerError(result.error) {
					self.handleError(error)
					return
				}
				else {
					if self.inputState == .Creating || self.inputState == .Sharing {
						
						/* Update recent patch list when a user sends a message */
						if self.inputState == .Creating {
							if let patch = DataController.instance.currentPatch {
								var recent: [String:AnyObject] = [
									"id_":patch.id_,
									"name":patch.name,
									"recentDate": NSNumber(longLong: Int64(NSDate().timeIntervalSince1970 * 1000)) // Only way to store Int64 as AnyObject
								]
								if patch.photo != nil {
									recent["photo"] = patch.photo.asMap()
								}
								Utils.updateRecents(recent)
							}
						}
						
						let serverResponse = ServerResponse(result.response)
						if serverResponse.resultCount == 1 {
							Log.d("Inserted message \(serverResponse.resultID)")
							DataController.instance.activityDateInsertDeleteMessage = Int64(NSDate().timeIntervalSince1970 * 1000)
						}
					}
					else {
						Log.d("Updated message \(self.inputEntity!.id_)")
					}
				}
			}
			
			self.performBack(true)
			Shared.Toast(self.progressFinishLabel)
		}
		
		/* Start tasks */
		
		queue.run()
		return queue
	}
	
	func delete() {
		
		self.processing = true
		
		let entityPath = "data/messages/\((self.inputEntity!.id_)!)"
		
		DataController.proxibase.deleteObject(entityPath) {
			response, error in
			
			NSOperationQueue.mainQueue().addOperationWithBlock {
				self.processing = false
				
				if let error = ServerError(error) {
					self.handleError(error)
				}
				else {
					DataController.instance.mainContext.deleteObject(self.inputEntity!)
					DataController.instance.saveContext(false)
					DataController.instance.activityDateInsertDeleteMessage = Int64(NSDate().timeIntervalSince1970 * 1000)
					self.performBack()
				}
			}
		}
	}
	
	func suggest() {
		
		guard !self.searchInProgress else {
			return
		}
		
		self.searchInProgress = true
		let searchString = self.searchText
		
		Log.d("Suggest call: \(searchString)")
		
		let endpoint: String = "https://api.aircandi.com/v1/suggest"
		let request = NSMutableURLRequest(URL: NSURL(string: endpoint)!)
		let session = NSURLSession.sharedSession()
		request.HTTPMethod = "POST"
		
		let body = [
			"users": true,
			"input": searchString.lowercaseString,
			"limit":10 ] as [String:AnyObject]
		
		do {
			request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(body, options: [])
			request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			request.addValue("application/json", forHTTPHeaderField: "Accept")
			
			let task = session.dataTaskWithRequest(request, completionHandler: {
				data, response, error -> Void in
				
				self.searchInProgress = false
				self.contactModels.removeAllObjects()
				
				if error == nil {
					let json:JSON = JSON(data: data!)
					let results = json["data"]
					
					for (index: _, subJson) in results {
						let model = SuggestionModel()
						model.contactTitle = subJson["name"].string
						model.contactImage = UIImage(named: "imgDefaultUser")
						model.entityId = (subJson["_id"] != nil) ? subJson["_id"].string : subJson["id_"].string
						
						if subJson["photo"] != nil {
							
							let prefix = subJson["photo"]["prefix"].string
							let source = subJson["photo"]["source"].string
							let photoUrl = PhotoUtils.url(prefix!, source: source!, category: SizeCategory.profile)
							model.contactImageUrl = photoUrl
							model.contactImage = UIImage(named: "imgDefaultUser")
						}
						self.contactModels.addObject(model)
					}
					
					dispatch_async(dispatch_get_main_queue(), {
						self.viewWillLayoutSubviews()
						self.contactList?.reloadData()
					})
				}
			})
			
			task.resume()
		}
		catch let error as NSError {
			print("json error: \(error.localizedDescription)")
		}
	}
	
    func gather(parameters: NSMutableDictionary) -> NSMutableDictionary {
		
		if self.inputState == State.Creating {
			
			parameters["description"] = nilToNull(self.descriptionField.text)
			parameters["photo"] = nilToNull(self.photoView.imageButton.imageForState(.Normal))
			parameters["links"] = [["type": "content", "_to": self.inputPatchId!]]
		}
		else if self.inputState == State.Editing {
			
			if self.descriptionField.text != self.inputEntity!.description_  {
				parameters["description"] = nilToNull(self.descriptionField.text)
			}
			if self.photoView.photoDirty {
				parameters["photo"] = nilToNull(self.photoView.imageButton.imageForState(.Normal))
			}
		}
		else if self.inputState == .Sharing {
			
			let links = NSMutableArray()
			links.addObject(["type": "share", "_to": self.inputShareEntity!.id_!])
			for contact in self.contactsSelected {
				if let contact = contact as? SuggestionModel {
					links.addObject(["type": "share", "_to": contact.entityId])
				}
			}
			parameters["links"] = links
			parameters["type"] = "share"
			
			if self.descriptionField.text == nil || self.descriptionField.text.isEmpty {
				parameters["description"] = self.descriptionDefault
			}
			else {
				parameters["description"] = self.descriptionField.text
			}
		}
		
        return parameters
    }

    func isDirty() -> Bool {
		
		if self.inputState == .Creating {
			if !self.descriptionField.text!.isEmpty {
				return true
			}
			if self.photoView.photoDirty {
				return true
			}
		}
		else if self.inputState == .Sharing {
			if !self.descriptionField.text!.isEmpty {
				return true
			}
		}
		else if self.inputState == .Editing {
			if !stringsAreEqual(self.descriptionField.text, string2: self.inputEntity?.description_) {
				return true
			}
			if self.photoView.photoDirty {
				return true
			}
		}
		return false
	}
	
    func isValid() -> Bool {
		
		/* Share */
		if self.inputState == .Sharing {
			if self.contactsSelected.count == 0 {
				Alert("Please add recipient(s)", message: nil, cancelButtonTitle: "OK")
				return false
			}
		}
		else {
			if ((self.descriptionField.text == nil || self.descriptionField.text!.isEmpty)
				&& self.photoView.imageButton.imageForState(.Normal) == nil) {
					Alert("Add message or photo", message: nil, cancelButtonTitle: "OK")
					return false
			}
		}
        return true
    }
	
	func performBack(animated: Bool = true) {
		/* Override in subclasses for control of dismiss/pop process */
		if isModal {
			self.dismissViewControllerAnimated(animated, completion: nil)
		}
		else {
			self.navigationController?.popViewControllerAnimated(true)
		}
	}
	
	func keyboardWillBeShown(sender: NSNotification) {
		/* 
		 * Called when the UIKeyboardDidShowNotification is sent. 
		 */
		let info: NSDictionary = sender.userInfo!
		let value = info.valueForKey(UIKeyboardFrameBeginUserInfoKey) as! NSValue
		let keyboardSize = value.CGRectValue().size
		
		self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, keyboardSize.height, 0)
		self.scrollView.scrollIndicatorInsets = self.scrollView.contentInset
		/* 
		 * If active text field is hidden by keyboard, scroll it so it's visible
		 */
		if self.activeTextField != nil {
			var visibleRect = self.scrollView.frame
			visibleRect.size.height -= keyboardSize.height
			
			let activeTextFieldRect = self.activeTextField?.frame
			let activeTextFieldOrigin = activeTextFieldRect?.origin
			
			if (!CGRectContainsPoint(visibleRect, activeTextFieldOrigin!)) {
				self.scrollView.scrollRectToVisible(activeTextFieldRect!, animated:true)
			}
		}
	}
 
	func keyboardWillBeHidden(sender: NSNotification) {
		/* 
		 * Called when the UIKeyboardWillHideNotification is sent.
		 */
		self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
		self.scrollView.scrollIndicatorInsets = scrollView.contentInset
	}
}

extension MessageEditViewController: UITextFieldDelegate {
	
	func textFieldDidBeginEditing(textField: UITextField) {
		self.activeTextField = textField
	}
	
	func textFieldDidEndEditing(textField: UITextField) {
		if self.activeTextField == textField {
			self.activeTextField = nil
		}
	}
	
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        return true
    }
}

extension MessageEditViewController: UITextViewDelegate {
	
	func textViewDidBeginEditing(textView: UITextView) {
		if let textView = textView as? AirTextView {
			self.activeTextField = textView
		}
	}
	
	func textViewDidEndEditing(textView: UITextView) {
		if self.activeTextField == textView {
			self.activeTextField = nil
		}
	}
	
	func textViewDidChange(textView: UITextView) {
		if let textView = textView as? AirTextView {
			textView.placeholderLabel.hidden = !self.descriptionField.text.isEmpty
			self.viewWillLayoutSubviews()
		}
	}
}

extension MessageEditViewController {
	/*
	* UITableViewDelegate
	*/
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		
		var cell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER) as? SearchViewCell
		
		if cell == nil {
			cell = SearchViewCell(style: .Default, reuseIdentifier: CELL_IDENTIFIER)
		}
		
		if let model = self.contactModels[indexPath.row] as? SuggestionModel {
			cell!.title.text = model.contactTitle
			if model.contactImageUrl != nil {
				cell!.photo.sd_setImageWithURL(model.contactImageUrl)
			}
			else {
				cell!.photo.image = model.contactImage
			}
		}
		return cell!
	}
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.contactModels.count
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		
		if let model = self.contactModels[indexPath.row] as? SuggestionModel {
			if !self.contactsSelected.containsObject(model) {
				let style = THContactViewStyle(textColor: Theme.colorTextTitle, backgroundColor: Colors.white, cornerRadiusFactor: 6)
				let styleSelected = THContactViewStyle(textColor: Colors.white, backgroundColor: Theme.colorBackgroundContactSelected, cornerRadiusFactor: 6)
				self.contactsSelected.addObject(model)
				self.addressField.addContact(model, withName: model.contactTitle, withStyle: style, andSelectedStyle: styleSelected )
			}
		}
		self.contactModels.removeAllObjects()
		self.viewWillLayoutSubviews()
		self.contactList?.reloadData()
		self.addressField.becomeFirstResponder()
	}
}

extension MessageEditViewController: THContactPickerDelegate {
	
	func contactPickerDidRemoveContact(contact: AnyObject!) {
		self.contactsSelected.removeObject(contact)
	}
	
	func contactPickerDidResize(contactPickerView: THContactPickerView!) {
		self.viewWillLayoutSubviews()
	}
	
	func contactPickerTextFieldShouldReturn(textField: UITextField!) -> Bool {
		return true
	}
	
	func contactPickerTextViewDidChange(textViewText: String!) {
		let text = textViewText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
		Log.d("contactPicker: entry text did change: \(text)")
		self.searchEditing = (text.length > 0)
		
		if text.length >= 2 {
			self.searchText = text
			/* To limit network activity, reload half a second after last key press. */
			if let timer = self.searchTimer {
				timer.invalidate()
			}
			self.searchTimer = NSTimer(timeInterval:0.2, target:self, selector:Selector("suggest"), userInfo:nil, repeats:false)
			NSRunLoop.currentRunLoop().addTimer(self.searchTimer!, forMode: "NSDefaultRunLoopMode")
		}
		else {
			if self.contactModels.count > 0 {
				self.contactModels.removeAllObjects()
				self.viewWillLayoutSubviews()
				self.contactList?.reloadData()
			}
		}
	}
}

class SuggestionModel {
	var entityId: String!
	var contactTitle: String?
	var contactSubtitle: String?
	var contactImage: UIImage?
	var contactImageUrl: NSURL?
}