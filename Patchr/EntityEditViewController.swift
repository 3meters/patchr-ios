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
    
	// UI outlets and views

	@IBOutlet weak var nameField:        UITextField!
	@IBOutlet weak var descriptionField: GCPlaceholderTextView!
    
    @IBOutlet weak var photoGroup:   	 UIView?
    @IBOutlet weak var buttonScrim:      UIView?
	@IBOutlet weak var photoImage:   	 UIButton!
	@IBOutlet weak var setPhotoButton:   UIButton!
    @IBOutlet weak var editPhotoButton:  UIButton!
    @IBOutlet weak var clearPhotoButton: UIButton!
    
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
        
        photoImage.contentVerticalAlignment = UIControlContentVerticalAlignment.Fill
        photoImage.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Fill
        photoImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFill

        self.setPhotoButton.alpha = 0
        self.editPhotoButton.alpha = 0
        self.clearPhotoButton.alpha = 0
        self.photoGroup?.alpha = 0
        
        if entity?.photo != nil {
            self.editPhotoButton.fadeIn()
            self.clearPhotoButton.fadeIn()
            self.photoGroup?.fadeIn()
        }
        else {
            if self.collection == "patches" || self.collection == "users" {
                self.photoGroup?.fadeIn()
            }
            self.setPhotoButton.fadeIn()
        }
    
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
        Alert("Will launch photo editor when implemented")
    }
    
    @IBAction func clearPhotoAction(sender: AnyObject) {

        if self.collection == "messages" {
            photo = nil
        }
        else {
            photo = UIImage(named: self.defaultPhotoName!)!
            usingPhotoDefault = true
        }
        
        if !editMode {
            self.photoDirty = (photo != nil)
        }
		else {
			self.photoDirty = (entity!.photo != photo)
		}
        
        self.editPhotoButton.fadeOut()
        self.clearPhotoButton.fadeOut()
        if self.collection == "messages" {
            self.photoGroup?.fadeOut()
        }
        self.setPhotoButton.fadeIn()
        
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
        
        if (keyboardVisible) {
            backClicked = true
            dismissKeyboard()
        }
        else {
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
    }
    
    @IBAction func deleteAction(sender: AnyObject) {
        
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

    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/
    
    func bind() {
        
        /* Name and description */
        name = entity?.name
        if descriptionField != nil {
            description_ = entity?.description_
        }
        
        /* Photo */
        if entity?.photo != nil {
            photoImage.setImageWithPhoto(entity!.photo!)
            usingPhotoDefault = false
            photoActive = true
        }
        else {
            if self.collection == "patches" || self.collection == "users" {
                photo = UIImage(named: self.defaultPhotoName!)! // Sets photoImage
            }
            usingPhotoDefault = true
            photoActive = false
        }
    }
    
    func photoChosen(image: UIImage?, imageResult: ImageResult?) -> Void {
        
        if image != nil {
            self.photo = image
        }
        else {
            self.photoImage.setImageWithImageResult(imageResult!, animate: true)
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
        
        self.editPhotoButton.fadeIn()
        self.clearPhotoButton.fadeIn()
        self.setPhotoButton.fadeOut()
        self.photoGroup?.fadeIn()
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
                    let serverResponse = ServerResponse(response)
                    if serverResponse.resultCount == 1 {
                        println("Created entity \(serverResponse.resultID)")
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
                    println("Update entity successful")
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
            return (self.photoImage.imageForState(.Normal) == nil || usingPhotoDefault) ? nil : photoImage.imageForState(.Normal)
        }
        set {
            UIView.transitionWithView(self.photoImage, duration: 1.0, options: UIViewAnimationOptions.TransitionCrossDissolve,
                animations: { () -> Void in
                    self.photoImage.setImage(newValue, forState: .Normal)
                }, completion: nil)
        }
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
}