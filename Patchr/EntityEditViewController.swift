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
    var usingPhotoDefault: Bool = true
	var backClicked = false
	var keyboardVisible = false
	var photoDirty: Bool = false

	var editMode: Bool {
		return entity != nil
	}
    
    var spacer: UIBarButtonItem {
        var space = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
        space.width = 20
        return space
    }

    lazy var photoChooser: PhotoChooserUI = PhotoChooserUI(hostViewController: self)
    
	// UI outlets and views

	@IBOutlet weak var nameField:        UITextField!
	@IBOutlet weak var descriptionField: GCPlaceholderTextView!
    
    @IBOutlet weak var photoGroup:   	 UIView?
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

        if self.descriptionField != nil {
            self.descriptionField!.placeholderColor = AirUi.hintColor
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
        UIAlertView(title: "Will launch photo editor when implemented", message: nil, delegate: nil, cancelButtonTitle: "OK").show()
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
        self.draw()
    }
    
    @IBAction func setPhotoAction(sender: AnyObject) {
        photoChooser.choosePhoto() {
            [unowned self] image in
            
            self.photo = image
            self.usingPhotoDefault = false
            self.photoDirty = true
            self.draw()
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
                self.dismissViewControllerAnimated(true, completion: nil)
                return
            }            
            
            var alert = UIAlertView()
            alert.title = "Do want to discard your editing changes?"
            alert.addButtonWithTitle("Discard")
            alert.addButtonWithTitle("Cancel")
            alert.delegate = self
            alert.show()
        }
    }
    
    @IBAction func deleteAction(sender: AnyObject) {
        
        self.ActionConfirmationAlert(LocalizedString("Confirm Delete"),
            message: LocalizedString("Are you sure you want to delete this?"),
            actionTitle: LocalizedString("Delete"),
            cancelTitle: LocalizedString("Cancel")) {
                doIt in
                
                self.delete()
        }
    }

    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/
    
    func bind() {
        
        /* Name and description */
        name = entity!.name
        if descriptionField != nil {
            description_ = entity!.description_
        }
        
        /* Photo */
        if entity!.photo != nil {
            photoImage.setImageWithPhoto(entity!.photo)
            usingPhotoDefault = false
        }
        else if self.collection != "messages" {
            photo = UIImage(named: self.defaultPhotoName!)!
            usingPhotoDefault = true
        }
    }

    func draw() {
        
        /* Any ui updates required based on current state */
        
        /* Photo buttons */
        var hasImage = (photo != nil)
        editPhotoButton.hidden = !hasImage
        clearPhotoButton.hidden = !hasImage
        setPhotoButton.hidden = hasImage
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
        
        let proxibase = DataController.proxibase
        var parameters = NSMutableDictionary()
        parameters = self.gather(parameters)
        
        proxibase.insertObject("data/\(collection!)", parameters: parameters) {
            response, error in
            
            self.processing = false
            progress.hide(true, afterDelay: 1.0)

            dispatch_async(dispatch_get_main_queue()) {
                if let error = ServerError(error) {
                    println("Insert entity error")
                    println(error)
                    println(parameters)
                    self.ErrorNotificationAlert(LocalizedString("Error"), message: error.message) { }
                }
                else {
                    println("Insert entity successful")
                    let serverResponse = ServerResponse(response)
                    if serverResponse.resultCount == 1 {
                        println("Created entity \(serverResponse.resultID)")
                        DataController.instance.activityDate = Int(floor(NSDate().timeIntervalSince1970 * 1000))
                    }
                    
                    self.dismissViewControllerAnimated(true, completion: nil)
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
        
        let proxibase  = DataController.proxibase
        var parameters = NSMutableDictionary()
        parameters = self.gather(parameters)
        
        let path = "data/\(self.collection!)/\(entity!.id_)"
        
        proxibase.updateObject(path, parameters: parameters) {
            response, error in
            
            self.processing = false
            progress.hide(true, afterDelay: 1.0)

            dispatch_async(dispatch_get_main_queue()) {
                if error != nil && error?.domain == "Proxibase" {
                    println("Update entity error")
                    println(error)
                    println(parameters)
                    if let userInfoDictionary = (error!.userInfo as NSDictionary?) {
                        self.ErrorNotificationAlert(LocalizedString("Error"), message: userInfoDictionary["message"] as! String) { }
                    }
                }
                else if let error = ServerError(error) {
                    println("Update entity error")
                    println(error)
                    println(parameters)
                    self.ErrorNotificationAlert(LocalizedString("Error"), message: error.message) { }
                }
                else {
                    println("Update entity successful")
                    DataController.instance.activityDate = Int(floor(NSDate().timeIntervalSince1970 * 1000))
                    self.dismissViewControllerAnimated(true, completion: nil)
                    progress.mode = MBProgressHUDMode.Text
                    progress.labelText = self.progressFinishLabel
                }
            }
        }
    }
    
    func delete() {
        
        let entityPath = "data/\(self.collection!)/\((self.entity?.id_)!)"
        DataController.proxibase.deleteObject(entityPath) {
            response, error in
            if let serverError = ServerError(error) {
                println(error)
                self.ErrorNotificationAlert(LocalizedString("Error"), message: serverError.message) { }
            }
            else {
                DataController.instance.managedObjectContext.deleteObject(self.entity!)
                if DataController.instance.managedObjectContext.save(nil) {
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            }
        }
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
            if nameField != nil && !name!.isEmpty {
                return true
            }
            if descriptionField != nil && !description_!.isEmpty {
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
                self.dismissViewControllerAnimated(true, completion: nil)
                return
            }
            
            var alert = UIAlertView()
            alert.title = "Do you want to discard your editing changes?"
            alert.addButtonWithTitle("Discard")
            alert.addButtonWithTitle("Cancel")
            alert.delegate = self
            alert.show()
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
            return (nameField == nil) ? nil : nameField.text
        }
        set {
            if nameField != nil {
                nameField.text = newValue
            }
        }
    }
    
    var description_: String? {
        get {
            return (descriptionField == nil) ? nil : descriptionField.text
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
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if (buttonIndex == 0) {
            self.dismissViewControllerAnimated(true, completion: nil)
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