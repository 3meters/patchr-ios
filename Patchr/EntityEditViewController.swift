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
    
	var processing: Bool = false
    var firstAppearance: Bool = true
	var backClicked = false
	var keyboardVisible = false
    
    var usingPhotoDefault: Bool = true
	var photoDirty: Bool = false
    var photoActive: Bool = false
    var photoChosen: Bool = false

	var editMode: Bool {
		return entity != nil
	}
    
    var spacer: UIBarButtonItem {
        var space = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
        space.width = SPACER_WIDTH
        return space
    }

    lazy var photoChooser: PhotoChooserUI = PhotoChooserUI(hostViewController: self)
    
    var photoView: PhotoView?
    
	// UI outlets and views

	@IBOutlet weak var nameField:        UITextField!
	@IBOutlet weak var descriptionField: GCPlaceholderTextView!
    @IBOutlet weak var photoHolder:      UIView?
	@IBOutlet weak var doneButton:       UIBarButtonItem!
    @IBOutlet weak var cancelButton:     UIBarButtonItem!

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
	override func viewDidLoad() {
		super.viewDidLoad()
        
        var tap = UITapGestureRecognizer(target: self, action: "dismissKeyboard");
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
            var photo: Photo = Entity.getDefaultPhoto(entity!.schema, id: entity!.id_);
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
            [weak self] image, imageResult in
            self?.photoChosen(image, imageResult: imageResult)
        }
    }
    
	@IBAction func doneAction(sender: AnyObject){
		save()
	}

    @IBAction func cancelAction(sender: AnyObject){
        
        if !isDirty() {
            self.performBack(animated: true)
            return
        }
        
        ActionConfirmationAlert(
            title: "Do you want to discard your editing changes?",
            actionTitle: "Discard", cancelTitle: "Cancel", delegate: self) {
                doIt in
                if doIt {
                    self.performBack(animated: true)
                }
            }
    }
    
    @IBAction func deleteAction(sender: AnyObject) {
        
        if self.entity is User {
            self.ActionConfirmationAlert(
                title: "Confirm account delete",
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
            self.ActionConfirmationAlert(
                title: "Confirm Delete",
                message: "Are you sure you want to delete this?",
                actionTitle: "Delete", cancelTitle: "Cancel", delegate: self) {
                    doIt in
                    if doIt {
                        self.delete()
                    }
                }
        }
    }
    
    func alertTextFieldDidChange(sender: AnyObject) {
        if let alertController: UIAlertController = self.presentedViewController as? UIAlertController {
            let confirm = alertController.textFields![0] as! UITextField
            let okAction = alertController.actions[0] as! UIAlertAction
            okAction.enabled = confirm.text == "YES"
        }
    }

    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/
    
    func bind() {
        
        if let entity = self.entity {
            
            /* Name and description */
            name = entity.name
            if descriptionField != nil {
                description_ = entity.description_
            }
            
            /* Photo */
            if entity.photo != nil {
                self.photoView?.imageView?.setImageWithPhoto(entity.photo!)
                usingPhotoDefault = false
                photoActive = true
            }
            else {
                if self.collection == "patches" || self.collection == "users" {
                    var photo: Photo = Entity.getDefaultPhoto(entity.schema, id: entity.id_);
                    self.photoView?.imageView?.setImageWithPhoto(photo)
                }
                usingPhotoDefault = true
                photoActive = false
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

		if editMode {
			update()
		}
		else {
			insert()
		}
	}
    
    func gather(parameters: NSMutableDictionary) -> NSMutableDictionary {
        
        if editMode {
            if name != entity!.name {
                parameters["name"] = nilToNull(name)
            }
            if descriptionField != nil && description_ != entity!.description_ {
                parameters["description"] = nilToNull(description_)
            }
            if photoDirty {
                parameters["photo"] = nilToNull(photo)
            }
        }
        else {
            parameters["name"] = nilToNull(name)
            parameters["photo"] = nilToNull(photo)
            parameters["description"] = nilToNull(description_)
        }
        return parameters
    }
    
    func insert() {
        
        if processing {
            return
        }
        
        processing = true
        
        let progress = MBProgressHUD.showHUDAddedTo(self.view.window, animated: true)
        progress.mode = MBProgressHUDMode.Indeterminate
        progress.labelText = progressStartLabel
        progress.square = true
        progress.show(true)
        
        var parameters = NSMutableDictionary()
        parameters = self.gather(parameters)
        
        DataController.proxibase.insertObject("data/\(collection!)", parameters: parameters) {
            response, error in
            
            self.processing = false

            dispatch_async(dispatch_get_main_queue()) {
                
                progress.hide(true, afterDelay: 1.0)
                if let error = ServerError(error) {
                    self.handleError(error)
                }
                else {
                    
                    /* Update recent patch list when a user sends a message */
                    if self.collection! == "messages" {
                        if let patch = DataController.instance.currentPatch {
                            
                            var recent: [String:AnyObject] = ["id_":patch.id_, "name":patch.name]
                            recent["recentDate"] = NSNumber(longLong: Int64(NSDate().timeIntervalSince1970 * 1000)) // Only way to store Int64 as AnyObject
                            if patch.photo != nil {
                                var photo: [String:AnyObject] = [
                                    "prefix":patch.photo.prefix,
                                    "source":patch.photo.source,
                                    "width":Int(patch.photo.widthValue),
                                    "height":Int(patch.photo.heightValue)]
                                recent["photo"] = photo
                            }
                            
                            Utils.updateRecents(recent)
                        }
                    }
                    
                    let serverResponse = ServerResponse(response)
                    if serverResponse.resultCount == 1 {
                        Log.d("Created entity \(serverResponse.resultID)")
                        DataController.instance.activityDate = Int64(NSDate().timeIntervalSince1970 * 1000)
                    }
                    
                    self.performBack(animated: true)
                    progress.mode = MBProgressHUDMode.Text
                    progress.labelText = self.progressFinishLabel
                }
            }
        }
    }
    
    func update() {
        
        if processing {
            return
        }
        processing = true
        
        let progress = MBProgressHUD.showHUDAddedTo(self.view.window, animated: true)
        progress.mode = MBProgressHUDMode.Indeterminate
        progress.labelText = self.progressStartLabel
        progress.square = true
        progress.show(true)
        
        var parameters = NSMutableDictionary()
        parameters = self.gather(parameters)
        
        let path = "data/\(self.collection!)/\(entity!.id_)"
        
        DataController.proxibase.updateObject(path, parameters: parameters) {
            response, error in
            
            self.processing = false

            dispatch_async(dispatch_get_main_queue()) {
                
                progress.hide(true, afterDelay: 1.0)
                if let error = ServerError(error) {
                    self.handleError(error)
                }
                else {
                    Log.d("Update entity successful")
                    DataController.instance.activityDate = Int64(NSDate().timeIntervalSince1970 * 1000)
                    self.performBack(animated: true)
                    progress.mode = MBProgressHUDMode.Text
                    progress.labelText = self.progressFinishLabel
                }
            }
        }
    }
    
    func delete() {
        
        if processing {
            return
        }
        processing = true
        
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
                if let controller = storyboard.instantiateViewControllerWithIdentifier("LobbyNavigationController") as? UIViewController {
                    appDelegate.window?.setRootViewController(controller, animated: true)
                    Shared.Toast("User \(userName) erased", controller: controller)
                }
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
                    if DataController.instance.managedObjectContext.save(nil) {
                        self.performBack()
                    }
                }
            }
        }
    }
    
    func performBack(animated: Bool = true) {
        /* Override in subclasses for control of dismiss/pop process */
        self.dismissViewControllerAnimated(animated, completion: nil)
    }
    
	func isDirty() -> Bool {
        
		if editMode {
            if entity!.name != name {
                return true
            }
            if photoDirty {
                return true
            }
            if (descriptionField != nil && entity!.description_ != description_) {
                return true
            }
            return false
		}
		else {
            if nameField != nil && name != nil {
                return true
            }
            if descriptionField != nil && description_ != nil {
                return true
            }
            if photoDirty {
                return true
            }
            return false
		}
	}

	func isValid() -> Bool {
        preconditionFailure("This method must be overridden")
    }
    
    /*--------------------------------------------------------------------------------------------
    * Helpers
    *--------------------------------------------------------------------------------------------*/
    
    func endFieldEditing(){ }
    
    func scrollToCursorForTextView(textView: UITextView) -> Void {
        /* Supports fancy dynamic editing for the description */
        var cursorRect: CGRect = descriptionField.caretRectForPosition(descriptionField.selectedTextRange?.start)
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
        keyboardVisible = false
        
        if backClicked {
            
            if !isDirty() {
                self.performBack(animated: true)
                return
            }
            
            ActionConfirmationAlert(title: "Do you want to discard your editing changes?",
                actionTitle: "Discard", cancelTitle: "Cancel", delegate: self) {
                action in
                if action {
                    self.performBack(animated: true)
                }
            }
            backClicked = false
        }
    }
    
    func keyboardWillHide(sender: NSNotification){
        keyboardVisible = false
    }
    
    func keyboardDidShow(sender: NSNotification){
        keyboardVisible = true
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
            return (nameField == nil || nameField.text == "") ? nil : nameField.text
        }
        set {
            if nameField != nil {
                nameField.text = newValue
            }
        }
    }
    
    var description_: String? {
        get {
            return (descriptionField == nil || descriptionField.text == "") ? nil : descriptionField.text
        }
        set {
            if descriptionField != nil {
                descriptionField.text = newValue
            }
        }
    }
    
    var photo: UIImage? {
        get {
            return (self.photoView?.imageView?.imageForState(.Normal) == nil || usingPhotoDefault) ? nil : self.photoView?.imageView?.imageForState(.Normal)
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

extension EntityEditViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool    {
        if (touch.view is UIButton) {
            return false
        }
        return true
    }
}

extension EntityEditViewController: UIAlertViewDelegate {
    /* Used by ActionConfirmationAlert for ios7 */
    
    func alertViewShouldEnableFirstOtherButton(alertView: UIAlertView) -> Bool {
        let inputView: UITextField = alertView.textFieldAtIndex(0)!
        return inputView.text == "YES"
    }
    
    /* Just here to support ios7 */
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if alertView.buttonTitleAtIndex(buttonIndex).lowercaseString == "delete" {
            self.delete()
        }
        else if alertView.buttonTitleAtIndex(buttonIndex).lowercaseString == "discard" {
            self.performBack(animated: true)
        }
    }
}

extension EntityEditViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(textView: UITextView) {
        self.scrollToCursorForTextView(textView)
    }
    
    func textViewDidChange(textView: UITextView) {
        tableView.beginUpdates()
        tableView.endUpdates()
        self.scrollToCursorForTextView(textView)
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        self.descriptionField.placeholderColor = UIColor.lightGrayColor()
    }    
}