//
//  EntityEditViewController.swift
//  Patchr
//
//  Created by Jay on 2015-06-07.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import MapKit

class EntityEditViewController: UITableViewController {

	var entity: Entity?
    var collection: String?
    var defaultPhotoName: String?
    var progressStartLabel: String?
    var progressFinishLabel: String?
    var cancelledLabel: String?
    
	var processing: Bool = false
    var firstAppearance: Bool = true
	var backClicked = false
	var keyboardVisible = false
	var lastResponder: UIResponder?
    
    var usingPhotoDefault: Bool = true
	var photoDirty: Bool = false
    var photoActive: Bool = false
    var photoChosen: Bool = false
    
    var imageUploadRequest: AWSS3TransferManagerUploadRequest?
    var entityPostRequest: NSURLSessionTask?
    
	var editMode: Bool {
		return entity != nil
	}
    
    var spacer: UIBarButtonItem {
        let space = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
        space.width = SPACER_WIDTH
        return space
    }

    lazy var photoChooser: PhotoChooserUI = PhotoChooserUI(hostViewController: self)
    
    var photoView: PhotoView?
    
	// UI outlets and views

	@IBOutlet weak var nameField:        UITextField!
	@IBOutlet weak var descriptionField: GCPlaceholderTextView!
    @IBOutlet weak var photoHolder:      UIView?

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
	override func viewDidLoad() {
		super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: "dismissKeyboard");
        tap.delegate = self
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        let array = NSBundle.mainBundle().loadNibNamed("PhotoView", owner: self, options: nil)
        self.photoView = array[0] as? PhotoView
        self.photoHolder?.addSubview(self.photoView!)
        
        if entity?.photo != nil {
            self.photoView?.configureTo(.Photo)
        }
        else {
            if self.collection == "patches" || self.collection == "users" {
                self.photoView?.configureTo(.Placeholder)
            }
            else {
                self.photoView?.configureTo(.Empty)
            }
        }
        
        self.photoView?.editPhotoButton?.addTarget(self, action: Selector("editPhotoAction:"), forControlEvents: .TouchUpInside)
        self.photoView?.clearPhotoButton?.addTarget(self, action: Selector("clearPhotoAction:"), forControlEvents: .TouchUpInside)
        self.photoView?.setPhotoButton?.addTarget(self, action: Selector("setPhotoAction:"), forControlEvents: .TouchUpInside)
    
        if self.descriptionField != nil {
            self.descriptionField!.placeholderColor = Colors.hintColor
            self.descriptionField!.scrollEnabled = false
            self.descriptionField!.delegate = self
            self.descriptionField!.textContainer.lineFragmentPadding = 0
            self.descriptionField!.textContainerInset = UIEdgeInsetsZero
        }
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancelAction:")
        self.navigationItem.leftBarButtonItems = [cancelButton]
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: "keyboardDidHide:", name: UIKeyboardDidHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: "keyboardDidShow:", name: UIKeyboardDidShowNotification, object: nil)
	}

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
        self.firstAppearance = false
		self.endFieldEditing()
	}
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    @IBAction func editPhotoAction(sender: AnyObject){
        let controller = AdobeUXImageEditorViewController(image: self.photo)
        controller.delegate = self
        presentViewController(controller, animated: true, completion: nil)
    }
    
    @IBAction func clearPhotoAction(sender: AnyObject) {

        if self.collection == "messages" {
            photo = nil
        }
        else {            
            let photo: Photo = Entity.getDefaultPhoto(entity!.schema, id: entity!.id_);
            self.photoView?.imageView?.setImageWithPhoto(photo)
            usingPhotoDefault = true
        }
        
        if !editMode {
            self.photoDirty = (photo != nil)
        }
		else {
			self.photoDirty = (entity!.photo != photo)
		}
        
        if self.collection == "messages" {
            self.photoView?.configureTo(.Empty)
        }
        else {
            self.photoView?.configureTo(.Placeholder)
        }
        
        photoActive = false
    }
    
    @IBAction func setPhotoAction(sender: AnyObject) {
        photoChooser.choosePhoto() {
            [weak self] image, imageResult, cancelled in
			
			if cancelled {
				if self?.lastResponder != nil {
					self?.lastResponder?.becomeFirstResponder()
				}
				return
			}
            self?.photoChosen(image, imageResult: imageResult)
        }
		
		if let responder = gimmeFirstResponder(inView: self.view) {
			self.lastResponder = responder
			responder.resignFirstResponder()
		}
    }
	
    @IBAction func deleteAction(sender: AnyObject) {
        
        if self.entity is User {
            ActionConfirmationAlert(
                "Confirm account delete",
                message: "Deleting your user account will erase all patches and messages you have created and cannot be undone. Enter YES to confirm.",
                actionTitle: "Delete",
                cancelTitle: "Cancel",
                destructConfirmation: true,
                delegate: self) {
                    doIt in
                    if doIt {
                       self.delete()
                    }
            }
        }
        else {
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
    }
    
    func doneAction(sender: AnyObject){
        save()
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
    
    func alertTextFieldDidChange(sender: AnyObject) {
		if let alertController: AirAlertController = self.presentedViewController as? AirAlertController {
			let confirm = alertController.textFields![0] 
			let okAction = alertController.actions[0] 
			okAction.enabled = confirm.text == "YES"
		}
    }

    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/
    
    func bind() {
		
        if let entity = self.entity {
            
            /* Name and description */
            self.name = entity.name
            if self.descriptionField != nil {
                self.description_ = entity.description_
            }
            
            /* Photo */
            if entity.photo != nil {
                self.photoView?.imageView?.setImageWithPhoto(entity.photo!)
                self.usingPhotoDefault = false
                self.photoActive = true
            }
            else {
                if self.collection == "patches" || self.collection == "users" {
                    let photo: Photo = Entity.getDefaultPhoto(entity.schema, id: entity.id_);
                    self.photoView?.imageView?.setImageWithPhoto(photo)
                }
                self.usingPhotoDefault = true
                self.photoActive = false
            }
        }
    }
    
    func photoChosen(image: UIImage?, imageResult: ImageResult?) -> Void {
        
        if image != nil {
            self.photo = image // Image ready so pushes into photoImage
        }
        else {
            self.photoView?.imageView?.setImageWithImageResult(imageResult!)  // Downloads and pushes into photoImage
        }
        
        if !self.editMode {
            self.photoDirty = (self.photo != nil)
        }
        else {
            self.photoDirty = (self.entity!.photo != self.photo)
        }
        
        self.usingPhotoDefault = false
        
        self.photoDirty = true
        self.photoActive = true
        self.photoChosen = true
        
        self.photoView?.configureTo(.Photo)
    }

	func save() {
		if !isValid() { return }
		post(self.editMode)
	}
    
    func gather(parameters: NSMutableDictionary) -> NSMutableDictionary {
        
        if self.editMode {
            if self.name != entity!.name {
                parameters["name"] = nilToNull(self.name)
            }
            if self.descriptionField != nil && self.description_ != self.entity!.description_ {
                parameters["description"] = nilToNull(self.description_)
            }
            if self.photoDirty {
                parameters["photo"] = nilToNull(self.photo)
            }
        }
        else {
            parameters["name"] = nilToNull(self.name)
            parameters["photo"] = nilToNull(self.photo)
            parameters["description"] = nilToNull(self.description_)
        }
        
        return parameters
    }
    
    func post(editing: Bool) {
        
        if self.processing { return }
        
        self.processing = true
        
        var progress = AirProgress.showHUDAddedTo(self.view.window, animated: true)
        progress.mode = MBProgressHUDMode.Indeterminate
        progress.styleAs(.ActivityLight)
        progress.labelText = self.progressStartLabel
        progress.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("progressWasCancelled:")))
		progress.removeFromSuperViewOnHide = true
        progress.show(true)
        
        let parameters: NSMutableDictionary = self.gather(NSMutableDictionary())
        var cancelled = false

        let queue = TaskQueue()
        
        Utils.delay(5.0, closure: {
            () -> () in
            progress?.detailsLabelText = "Tap to cancel"
        })
        
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
            let endpoint = editing ? "data/\(self.collection!)/\(self.entity!.id_)" : "data/\(self.collection!)"
            self.entityPostRequest = DataController.proxibase.postEntity(endpoint, parameters: parameters) {
                response, error in
                if error == nil {
                    progress!.progress = 1.0
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
            
            progress!.hide(true)
            progress = nil
            
            if let result: Result = queue.lastResult as? Result {
                if let error = ServerError(result.error) {
                    self.handleError(error)
                    return
                }
                else {
                    if !editing {
                        
                        /* Update recent patch list when a user sends a message */
                        if self.collection! == "messages" {
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
                            Log.d("Inserted entity \(serverResponse.resultID)")
                            DataController.instance.activityDate = Int64(NSDate().timeIntervalSince1970 * 1000)
                        }
                    }
                    else {
                        Log.d("Updated entity \(self.entity!.id_)")
                    }
                }
            }
            
            self.performBack(true)
            Shared.Toast(self.progressFinishLabel)
        }
        
        /* Start tasks */
        
        queue.run()
    }
    
    func delete() {
        
        if self.processing {
            return
        }
        self.processing = true
        
        if let user = self.entity as? User {
            
            let entityPath = "user/\((self.entity?.id_)!)?erase=true"
            let userName: String = user.name
            
            DataController.proxibase.deleteObject(entityPath) {
                response, error in
                
                if let error = ServerError(error) {
                    self.handleError(error)
                }
                
                /* Return to the lobby even if there was an error since we signed out */
                UserController.instance.discardCredentials()
                NSUserDefaults.standardUserDefaults().setObject(nil, forKey: PatchrUserDefaultKey("userEmail"))
                NSUserDefaults.standardUserDefaults().synchronize()
                
                LocationController.instance.clearLastLocationAccepted()
                
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                let storyboard: UIStoryboard = UIStoryboard(name: "Lobby", bundle: NSBundle.mainBundle())
                let controller = storyboard.instantiateViewControllerWithIdentifier("LobbyNavigationController")
                appDelegate.window?.setRootViewController(controller, animated: true)
                Shared.Toast("User \(userName) erased", controller: controller)
            }
        }
        else  {
            
            let entityPath = "data/\(self.collection!)/\((self.entity?.id_)!)"
            
            DataController.proxibase.deleteObject(entityPath) {
                response, error in
                
                self.processing = false
                
                if let error = ServerError(error) {
                    self.handleError(error)
                }
                else {
					DataController.instance.managedObjectContext.deleteObject(self.entity!)
					DataController.instance.saveContext()
					self.performBack()
                }
            }
        }
    }
    
    func progressWasCancelled(sender: AnyObject) {
        if let gesture = sender as? UIGestureRecognizer, let hud = gesture.view as? MBProgressHUD {
			hud.animationType = MBProgressHUDAnimation.ZoomIn
            hud.hide(true)
            self.imageUploadRequest?.cancel() // Should do nothing if upload already complete or isn't any
            self.entityPostRequest?.cancel()
        }
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
    
	func isDirty() -> Bool {
        
		if self.editMode {
            if self.entity!.name != self.name {
                return true
            }
            if self.photoDirty {
                return true
            }
            if (self.descriptionField != nil && self.entity!.description_ != self.description_) {
                return true
            }
            return false
		}
		else {
            if self.nameField != nil && self.name != nil {
                return true
            }
            if self.descriptionField != nil && self.description_ != nil {
                return true
            }
            if self.photoDirty {
                return true
            }
            return false
		}
	}

	func isValid() -> Bool {
        preconditionFailure("This method must be overridden")
    }
    
    var isModal: Bool {
        return self.presentingViewController?.presentedViewController == self
            || (self.navigationController != nil && self.navigationController?.presentingViewController?.presentedViewController == self.navigationController)
            || self.tabBarController?.presentingViewController is UITabBarController
    }
    
    /*--------------------------------------------------------------------------------------------
    * Helpers
    *--------------------------------------------------------------------------------------------*/
    
    func endFieldEditing(){ }

	func gimmeFirstResponder(inView view: UIView) -> UIResponder? {
		for subView in view.subviews {
			if subView.isFirstResponder() {
				return subView
			}
			if let recursiveSubView = self.gimmeFirstResponder(inView: subView) {
				return recursiveSubView
			}
		}
		return nil
	}
	
    func scrollToCursorForTextView(textView: UITextView) -> Void {
        /* Supports fancy dynamic editing for the description */
        var cursorRect: CGRect = descriptionField.caretRectForPosition((descriptionField.selectedTextRange?.start)!)
        cursorRect = self.tableView.convertRect(cursorRect, fromView:descriptionField)
        if !self.rectVisible(cursorRect) {
            cursorRect.size.height += 8; // To add some space underneath the cursor
            self.tableView.scrollRectToVisible(cursorRect, animated: true)
        }
    }
    
    private func rectVisible(rect: CGRect) -> Bool {
        var visibleRect: CGRect = CGRect()
        visibleRect.origin = self.tableView.contentOffset;
        visibleRect.origin.y += self.tableView.contentInset.top;
        visibleRect.size = self.tableView.bounds.size;
        visibleRect.size.height -= self.tableView.contentInset.top + self.tableView.contentInset.bottom;
        return CGRectContainsRect(visibleRect, rect);
    }
    
    override func disablesAutomaticKeyboardDismissal() -> Bool {
        return false
    }
    
    func keyboardDidHide(sender: NSNotification){
        self.keyboardVisible = false
        
        if self.backClicked {
            
            if !self.isDirty() {
                self.performBack(true)
                return
            }
            
            ActionConfirmationAlert("Do you want to discard your editing changes?",
                actionTitle: "Discard", cancelTitle: "Cancel", delegate: self) {
                action in
                if action {
                    self.performBack(true)
                }
            }
            self.backClicked = false
        }
    }
    
    func keyboardWillHide(sender: NSNotification){
        self.keyboardVisible = false
    }
    
    func keyboardDidShow(sender: NSNotification){
        self.keyboardVisible = true
    }
    
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    func nullToNil(value : AnyObject?) -> AnyObject? {
        if value is NSNull {
            return nil
        } else {
            return value
        }
    }
    
    func nilToNull(value : AnyObject?) -> AnyObject? {
        if value == nil {
            return NSNull()
        } else {
            return value
        }
    }
    
    /*--------------------------------------------------------------------------------------------
     * Field wrappers
     *--------------------------------------------------------------------------------------------*/
    
    var name: String? {
        get {
            return (self.nameField == nil || self.nameField.text == "") ? nil : self.nameField.text
        }
        set {
            if self.nameField != nil {
                self.nameField.text = newValue
            }
        }
    }
    
    var description_: String? {
        get {
            return (self.descriptionField == nil || self.descriptionField.text == "") ? nil : self.descriptionField.text
        }
        set {
            if self.descriptionField != nil {
                self.descriptionField.text = newValue
            }
        }
    }
    
    var photo: UIImage? {
        get {
            return (self.photoView?.imageView?.imageForState(.Normal) == nil || self.usingPhotoDefault) ? nil : self.photoView?.imageView?.imageForState(.Normal)
        }
        set {
            if let imageView = self.photoView?.imageView {
                UIView.transitionWithView(imageView, duration: 1.0, options: UIViewAnimationOptions.TransitionCrossDissolve,
                    animations: { () -> Void in
                        imageView.setImage(newValue, forState: .Normal)
                    }, completion: nil)
            }
        }
    }
}

extension EntityEditViewController: AdobeUXImageEditorViewControllerDelegate {
    
    func photoEditor(editor: AdobeUXImageEditorViewController!, finishedWithImage image: UIImage!) {
        self.photoChosen(image, imageResult: nil)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func photoEditorCanceled(editor: AdobeUXImageEditorViewController!) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

class Result {
    var response: AnyObject?
    var error: NSError?
    init(response: AnyObject?, error: NSError?) {
        self.response = response
        self.error = error
    }
}

extension EntityEditViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool    {
        if (touch.view is UIButton) {
            return false
        }
        return true
    }
}

extension EntityEditViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(textView: UITextView) {
        self.scrollToCursorForTextView(textView)
    }
    
    func textViewDidChange(textView: UITextView) {
		/* Begin/end triggers the tableview to pickup UI changes */
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
		self.scrollToCursorForTextView(textView)	// Make sure we keep the cursor visible as lines wrap
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        self.descriptionField.placeholderColor = UIColor.lightGrayColor()
    }    
}