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

class PatchEditViewController: BaseViewController {
	
	var processing: Bool = false
	var progressStartLabel: String?
	var progressFinishLabel: String?
	var cancelledLabel: String?
	
	var schema = Schema.ENTITY_PATCH
	
	var imageUploadRequest	 : AWSS3TransferManagerUploadRequest?
	var entityPostRequest	 : NSURLSessionTask?
	
	var inputState			 : State?	= State.Editing
	var inputPatch			 : Patch?

	var photoView            = PhotoView()
	var nameField            = AirTextField()
	var descriptionField     = AirTextView()
	
	var visibilityGroup		 = AirRuleView()
	var visibilitySwitch	 = UISwitch()
	var visibilityLabel		 = AirLabelDisplay()
	
	var locationGroup		 = AirRuleView()
	var locationLabel		 = AirLabelDisplay()
	var locationAddress		 = AirLinkButton()
	var locationValue		 : CLLocation? = nil
	
	var doneButton           = AirFeaturedButton()
	var message				 = AirLabelTitle()
	var scrollView			 = AirScrollView()
	var contentHolder		 = UIView()
	
	var typeGroup			 = UIView()
	var typeLabel			 = AirLabelDisplay()
	var typeButtonGroup		 = AirRadioButton()
	var typeButtonPlace		 = AirRadioButton()
	var typeButtonEvent		 = AirRadioButton()
	var typeButtonProject	 = AirRadioButton()
	
	var typeValue			 : String? = nil
	var visibilityValue		 = "public"

	var progress			 : AirProgress?
	var activeTextField		 : UIView?
	var insertedEntity		 : Entity?
	
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
	
	override func viewWillAppear(animated: Bool) {
		let notificationCenter = NSNotificationCenter.defaultCenter()
		notificationCenter.addObserver(self, selector: "dismissKeyboard", name: Events.PhotoViewHasFocus, object: nil)
		notificationCenter.addObserver(self, selector: "keyboardWillBeShown:", name: UIKeyboardWillShowNotification, object: nil)
		notificationCenter.addObserver(self, selector: "keyboardWillBeHidden:", name: UIKeyboardWillHideNotification, object: nil)
	}
	
	override func viewDidDisappear(animated: Bool) {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		let messageSize = self.message.sizeThatFits(CGSizeMake(288, CGFloat.max))
		let descriptionSize = self.descriptionField.sizeThatFits(CGSizeMake(288, CGFloat.max))
		
		self.locationLabel.sizeToFit()
		self.locationAddress.sizeToFit()
		self.visibilityLabel.sizeToFit()
		self.typeLabel.sizeToFit()
		
		self.message.anchorTopCenterWithTopPadding(0, width: 288, height: messageSize.height)
		self.nameField.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 288, height: 48)
		self.descriptionField.alignUnder(self.nameField, matchingCenterWithTopPadding: 8, width: 288, height: max(48, descriptionSize.height))
		self.photoView.alignUnder(self.descriptionField, matchingCenterWithTopPadding: 16, width: 288, height: 288 * 0.56)
		self.visibilityGroup.alignUnder(self.photoView, matchingCenterWithTopPadding: 8, width: 288, height: 48)
		self.locationGroup.alignUnder(self.visibilityGroup, matchingCenterWithTopPadding: 8, width: 288, height: 48)
		self.typeGroup.alignUnder(self.locationGroup, matchingCenterWithTopPadding: 8, width: 288, height: 96)
		
		self.visibilityLabel.anchorCenterLeftWithLeftPadding(0, width: 144, height: self.visibilityLabel.height())
		self.visibilitySwitch.anchorCenterRightWithRightPadding(0, width: self.visibilitySwitch.width(), height: self.visibilitySwitch.height())
		
		self.locationLabel.anchorCenterLeftWithLeftPadding(0, width: self.locationLabel.width(), height: self.locationLabel.height())
		self.locationAddress.anchorCenterRightWithRightPadding(0, width: min(288 - self.locationLabel.width() + 8, self.locationAddress.width()), height: self.locationAddress.height())
		
		self.typeLabel.anchorTopLeftWithLeftPadding(0, topPadding: 0, width: 96, height: 48)
		self.typeButtonEvent.alignToTheRightOf(self.typeLabel, matchingCenterWithLeftPadding: 8, width: 88, height: 24)
		self.typeButtonGroup.alignToTheRightOf(self.typeButtonEvent, matchingCenterWithLeftPadding: 8, width: 88, height: 24)
		self.typeButtonPlace.alignUnder(self.typeButtonEvent, matchingLeftWithTopPadding: 8, width: 88, height: 24)
		self.typeButtonProject.alignUnder(self.typeButtonGroup, matchingLeftWithTopPadding: 8, width: 88, height: 24)
		
		self.contentHolder.resizeToFitSubviews()
		self.scrollView.contentSize = CGSizeMake(self.contentHolder.frame.size.width, self.contentHolder.frame.size.height + CGFloat(32))
		self.contentHolder.anchorTopCenterFillingWidthWithLeftAndRightPadding(16, topPadding: 16, height: self.contentHolder.frame.size.height)
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
	
	func userCancelTaskAction(sender: AnyObject) {
		if let gesture = sender as? UIGestureRecognizer, let hud = gesture.view as? MBProgressHUD {
			hud.animationType = MBProgressHUDAnimation.ZoomIn
			hud.hide(true)
			self.imageUploadRequest?.cancel() // Should do nothing if upload already complete or isn't any
			self.entityPostRequest?.cancel()
		}
	}
	
	func cancelAction(sender: AnyObject){
		
		if !isDirty() {
			self.performBack(true)
			return
		}
		
		DeleteConfirmationAlert(
			"Do you want to discard your editing changes?",
			actionTitle: "Discard", cancelTitle: "Cancel", delegate: self) {
				doIt in
				if doIt {
					self.performBack(true)
				}
		}
	}
	
	func locationAction(sender: AnyObject) {
		let controller = PatchMapViewController()
		controller.locationDelegate = self
		self.navigationController?.pushViewController(controller, animated: true)
	}
	
	func deleteAction(sender: AnyObject) {
		
		guard !self.processing else { return }
		
		DeleteConfirmationAlert(
			"Confirm Delete",
			message: "Are you sure you want to delete this?",
			actionTitle: "Delete", cancelTitle: "Cancel", delegate: self) {
				doIt in
				if doIt {
					self.delete()
				}
		}
	}
	
	func visibilityChanged(sender: AnyObject) {
		if let switchView = sender as? UISwitch {
			self.visibilityValue = (switchView.on) ? "private" : "public"
		}
	}
	
	func typeSelected(sender: AnyObject) {
		if let button = sender as? AirRadioButton {
			if button == self.typeButtonEvent {
				self.typeValue = "event"
			}
			if button == self.typeButtonGroup {
				self.typeValue = "group"
			}
			if button == self.typeButtonPlace {
				self.typeValue = "place"
			}
			if button == self.typeButtonProject {
				self.typeValue = "project"
			}
		}
	}
	
	/*--------------------------------------------------------------------------------------------
	 * Methods
	 *--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
		self.schema = Schema.ENTITY_PATCH
		
		let fullScreenRect = UIScreen.mainScreen().applicationFrame
		self.scrollView.frame = fullScreenRect
		self.scrollView.backgroundColor = Theme.colorBackgroundForm
		self.scrollView.addSubview(self.contentHolder)
		self.view = self.scrollView
		
		self.message.textColor = Theme.colorTextTitle
		self.message.numberOfLines = 0
		self.message.textAlignment = .Center
		
		self.photoView.photoSchema = Schema.ENTITY_PATCH
		self.photoView.setHostController(self)
		self.photoView.configureTo(self.inputPatch?.photo != nil ? .Photo : .Placeholder)
		
		self.nameField.placeholder = "Title"
		self.nameField.delegate = self
		self.nameField.autocapitalizationType = .Words
		self.nameField.autocorrectionType = .No
		self.nameField.keyboardType = UIKeyboardType.Default
		self.nameField.returnKeyType = UIReturnKeyType.Next
		
		self.descriptionField = AirTextView()
		self.descriptionField.placeholderLabel.text = "Tell people about your patch"
		self.descriptionField.initialize()
		self.descriptionField.delegate = self
		
		self.visibilityLabel.text = "Private Patch"
		self.visibilitySwitch.addTarget(self, action: Selector("visibilityChanged:"), forControlEvents: .TouchUpInside)
		
		self.locationLabel.text = "Location"
		self.locationAddress.titleLabel!.font = Theme.fontTextDisplay
		self.locationAddress.addTarget(self, action: Selector("locationAction:"), forControlEvents: .TouchUpInside)
		
		self.typeLabel.text = "Patch Type"
		self.typeButtonEvent.setTitle("Event", forState: .Normal)		
		self.typeButtonGroup.setTitle("Group", forState: .Normal)
		self.typeButtonPlace.setTitle("Place", forState: .Normal)
		self.typeButtonProject.setTitle("Project", forState: .Normal)
		self.typeButtonEvent.otherButtons = [self.typeButtonGroup, self.typeButtonPlace, self.typeButtonProject]
		
		self.typeButtonEvent.addTarget(self, action: Selector("typeSelected:"), forControlEvents: .TouchUpInside)
		self.typeButtonGroup.addTarget(self, action: Selector("typeSelected:"), forControlEvents: .TouchUpInside)
		self.typeButtonPlace.addTarget(self, action: Selector("typeSelected:"), forControlEvents: .TouchUpInside)
		self.typeButtonProject.addTarget(self, action: Selector("typeSelected:"), forControlEvents: .TouchUpInside)
		
		self.visibilityGroup.addSubview(self.visibilityLabel)
		self.visibilityGroup.addSubview(self.visibilitySwitch)
		
		self.locationGroup.addSubview(self.locationLabel)
		self.locationGroup.addSubview(self.locationAddress)
		
		self.typeGroup.addSubview(self.typeLabel)
		self.typeGroup.addSubview(self.typeButtonEvent)
		self.typeGroup.addSubview(self.typeButtonGroup)
		self.typeGroup.addSubview(self.typeButtonPlace)
		self.typeGroup.addSubview(self.typeButtonProject)
		
		self.contentHolder.addSubview(self.message)
		self.contentHolder.addSubview(self.nameField)
		self.contentHolder.addSubview(self.descriptionField)
		self.contentHolder.addSubview(self.photoView)
		self.contentHolder.addSubview(self.visibilityGroup)
		self.contentHolder.addSubview(self.locationGroup)
		self.contentHolder.addSubview(self.typeGroup)
		
		if self.inputState == State.Creating {
			setScreenName("PatchNew")
			self.message.text = "New Patch"
			self.progressStartLabel = "Patching"
			self.progressFinishLabel = "Activated"
			self.cancelledLabel = "Activation cancelled"
			
			/* Navigation bar buttons */
			let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancelAction:")
			let nextButton = UIBarButtonItem(title: "Next", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("doneAction:"))
			self.navigationItem.leftBarButtonItems = [cancelButton]
			self.navigationItem.rightBarButtonItems = [nextButton]
		}
		else {
			setScreenName("PatchEdit")
			self.message.text = "Patch"
			self.progressStartLabel = "Updating"
			self.progressFinishLabel = "Updated"
			self.cancelledLabel = "Update cancelled"
			self.doneButton.hidden = true
			
			/* Navigation bar buttons */
			let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancelAction:")
			let deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: "deleteAction:")
			let saveButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: "doneAction:")
			self.navigationItem.leftBarButtonItems = [cancelButton]
			self.navigationItem.rightBarButtonItems = [saveButton, Utils.spacer, deleteButton]
		}
	}
	
    func bind() {
		
		if self.inputState == State.Editing {
			
			self.nameField.text = self.inputPatch?.name
			self.descriptionField.text = self.inputPatch?.description_
			self.photoView.bindPhoto(self.inputPatch?.photo)
			
			textViewDidChange(self.descriptionField)
			
			/* Visibility */
			self.visibilitySwitch.on = (self.inputPatch?.visibility == "private")
			self.visibilityValue = (self.inputPatch?.visibility)!
			
			/* Location */
			if let loc = self.inputPatch?.location {
				updateLocation(loc.cllocation)
			}
			
			/* Type */
			if self.inputPatch?.type == "event" {
				self.typeButtonEvent.selected = true
				self.typeValue = "event"
			}
			else if self.inputPatch?.type == "group" {
				self.typeButtonGroup.selected = true
				self.typeValue = "group"
			}
			else if self.inputPatch?.type == "place" {
				self.typeButtonPlace.selected = true
				self.typeValue = "place"
			}
			else if self.inputPatch?.type == "project" {
				self.typeButtonProject.selected = true
				self.typeValue = "project"
			}
		}
		else {
			
			/* Use location managers last location fix */
			if let lastLocation = LocationController.instance.lastLocationFromManager() {
				updateLocation(lastLocation)
			}
			
			/* Public by default */
			self.visibilitySwitch.on = false
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
			let endpoint = self.inputState == State.Creating ? "data/patches" : "data/patches/\(self.inputPatch!.id_!)"
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
		
		/* Download entity */
		
		if self.inputState == .Creating {
			queue.tasks +=~ { _, next in
				if let result: Result = queue.lastResult as? Result where result.error == nil {
					let serverResponse = ServerResponse(result.response)
					DataController.instance.withEntityId(serverResponse.resultID, strategy: .UseCacheAndVerify) { objectId, error in
						if error == nil && objectId != nil {
							self.insertedEntity = DataController.instance.mainContext.objectWithID(objectId!) as? Entity
						}
						next(queue.lastResult)
					}
				}
				else {
					next(queue.lastResult)
				}
			}
		}
		
		/* Update Ui */
		
		queue.tasks +=! {
			self.processing = false
			
			if cancelled {
				UIShared.Toast(self.cancelledLabel)
				return
			}
			
			self.progress?.hide(true)
			
			if let result: Result = queue.lastResult as? Result {
				if let error = ServerError(result.error) {
					self.handleError(error)
					return
				}
				else {
					if self.inputState == State.Creating {
						let serverResponse = ServerResponse(result.response)
						if serverResponse.resultCount == 1 {
							Log.d("Inserted entity \(serverResponse.resultID)")
							DataController.instance.activityDateInsertDeletePatch = Utils.now()
							DataController.instance.activityDateWatching = DataController.instance.activityDateInsertDeletePatch
							let controller = InviteViewController()
							controller.inputEntity = self.insertedEntity as! Patch
							self.navigationController?.pushViewController(controller, animated: true)
						}
						return
					}
					else {
						Log.d("Updated entity \(self.inputPatch!.id_)")
					}
				}
			}
			
			self.performBack(true)
			UIShared.Toast(self.progressFinishLabel)
		}
		
		/* Start tasks */
		
		queue.run()
		return queue
	}
	
	func delete() {
		
		self.processing = true
		
		let entityPath = "data/patches/\((self.inputPatch?.id_)!)"
		
		DataController.proxibase.deleteObject(entityPath) {
			response, error in
			
			NSOperationQueue.mainQueue().addOperationWithBlock {
				self.processing = false
				
				if let error = ServerError(error) {
					self.handleError(error)
				}
				else {
					DataController.instance.mainContext.deleteObject(self.inputPatch!)
					DataController.instance.saveContext(false)
					DataController.instance.activityDateInsertDeletePatch = Utils.now()
					self.performBack()
				}
			}
		}
	}
	
    func gather(parameters: NSMutableDictionary) -> NSMutableDictionary {
		
		if self.inputState == State.Creating {
			parameters["name"] = nilToNull(self.nameField.text)
			parameters["description"] = nilToNull(self.descriptionField.text)
			parameters["photo"] = nilToNull(self.photoView.imageButton.imageForState(.Normal))
			parameters["visibility"] = nilToNull(self.visibilityValue)
			parameters["location"] = nilToNull(self.locationValue)
			parameters["type"] = nilToNull(self.typeValue)
		}
		else {
			if self.nameField.text != self.inputPatch?.name  {
				parameters["name"] = nilToNull(self.nameField.text)
			}
			if self.descriptionField.text != self.inputPatch?.description_  {
				parameters["description"] = nilToNull(self.descriptionField.text)
			}
			if self.photoView.photoDirty {
				parameters["photo"] = nilToNull(self.photoView.imageButton.imageForState(.Normal))
			}
			if self.visibilityValue != self.inputPatch?.visibility {
				parameters["visibility"] = nilToNull(self.visibilityValue)
			}
			if self.typeValue != self.inputPatch?.type {
				parameters["type"] = nilToNull(self.typeValue)
			}
			parameters["location"] = nilToNull(self.locationValue)
		}
		
        return parameters
    }
	
	func updateLocation(loc: CLLocation) {
		/* Gets calls externally from map view */
		self.locationValue = loc
		
		CLGeocoder().reverseGeocodeLocation(loc) {  // Requires network
			placemarks, error in
			
			if let error = ServerError(error) {
				self.handleError(error)
			}
			else if placemarks != nil && placemarks!.count > 0 {
				let placemark = placemarks!.first
				self.locationAddress.setTitle(placemark!.name, forState: .Normal)
				self.viewWillLayoutSubviews()
			}
		}
	}

    func isDirty() -> Bool {
		
		if self.inputState == .Creating {
			if !self.nameField.text!.isEmpty {
				return true
			}
			if !self.descriptionField.text!.isEmpty {
				return true
			}
			if self.photoView.photoDirty {
				return true
			}
			if self.typeValue != nil {
				return true
			}
		}
		else {
			if !stringsAreEqual(self.nameField.text, string2: self.inputPatch?.name) {
				return true
			}
			if !stringsAreEqual(self.descriptionField.text, string2: self.inputPatch?.description_) {
				return true
			}
			if self.photoView.photoDirty {
				return true
			}
			if self.visibilityValue != self.inputPatch?.visibility {
				return true
			}
			if self.locationValue !=  self.inputPatch?.location {
				if (self.locationValue?.coordinate)! != (self.inputPatch?.location.coordinate)! {
					return true
				}
			}
			if self.typeValue != self.inputPatch?.type {
				return true
			}
		}
		return false
	}
	
    func isValid() -> Bool {
		
		if self.nameField.isEmpty {
			Alert("Enter a name for the patch.", message: nil, cancelButtonTitle: "OK")
			return false
		}
		
		if self.typeValue == nil {
			Alert("Select a patch type.", message: nil, cancelButtonTitle: "OK")
			return false
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
		if let scrollView = self.view as? UIScrollView {
			
			let info: NSDictionary = sender.userInfo!
			let value = info.valueForKey(UIKeyboardFrameBeginUserInfoKey) as! NSValue
			let keyboardSize = value.CGRectValue().size
			
			scrollView.contentInset = UIEdgeInsetsMake(64, 0, keyboardSize.height, 0)
			scrollView.scrollIndicatorInsets = scrollView.contentInset
			
			/* 
			 * If active text field is hidden by keyboard, scroll it so it's visible
			 */
			if self.activeTextField != nil {
				var visibleRect = self.view.frame
				visibleRect.size.height -= keyboardSize.height
				
				let activeTextFieldRect = self.activeTextField?.frame
				let activeTextFieldOrigin = activeTextFieldRect?.origin
				
				if (!CGRectContainsPoint(visibleRect, activeTextFieldOrigin!)) {
					scrollView.scrollRectToVisible(activeTextFieldRect!, animated:true)
				}
			}
		}
	}
 
	func keyboardWillBeHidden(sender: NSNotification) {
		/* 
		 * Called when the UIKeyboardWillHideNotification is sent.
		 */
		if let scrollView = self.view as? UIScrollView {
			scrollView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0)
			scrollView.scrollIndicatorInsets = scrollView.contentInset
		}
	}
}

extension PatchEditViewController: MapViewDelegate {
	
	func locationForMap() -> CLLocation? {
		return self.locationValue
	}
	
	func locationChangedTo(location: CLLocation) -> Void {
		self.locationValue = location
		updateLocation(location)
	}
	
	func locationEditable() -> Bool {
		return true
	}
	
	var locationTitle: String? {
		get {
			return self.nameField.text
		}
	}
	
	var locationSubtitle: String? {
		
		get {
			if self.typeValue != nil {
				return "\(self.typeValue!.uppercaseString) PATCH"
			}
			return "PATCH"
		}
	}
	
	var locationPhoto: AnyObject? {
		get {
			return self.photoView.imageButton.imageForState(.Normal)
		}
	}
}

extension PatchEditViewController: UITextFieldDelegate {
	
	func textFieldDidBeginEditing(textField: UITextField) {
		self.activeTextField = textField
	}
	
	func textFieldDidEndEditing(textField: UITextField) {
		if self.activeTextField == textField {
			self.activeTextField = nil
		}
	}
	
    func textFieldShouldReturn(textField: UITextField) -> Bool {
		
		if self.inputState == .Creating {
			if textField == self.nameField {
				self.descriptionField.becomeFirstResponder()
				return false
			}
		}
        return true
    }
}

extension PatchEditViewController: UITextViewDelegate {
	
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
