//
//  BaseViewController.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class BaseEditViewController: BaseViewController, UITextFieldDelegate {
	
	var activeTextField		: UIView?
	
	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		let notificationCenter = NSNotificationCenter.defaultCenter()
		notificationCenter.addObserver(self, selector: "photoDidChange:", name: Events.PhotoDidChange, object: nil)
		notificationCenter.addObserver(self, selector: "photoViewHasFocus:", name: Events.PhotoViewHasFocus, object: nil)
		notificationCenter.addObserver(self, selector: "keyboardWillBeShown:", name: UIKeyboardWillShowNotification, object: nil)
		notificationCenter.addObserver(self, selector: "keyboardWillBeHidden:", name: UIKeyboardWillHideNotification, object: nil)
	}
	
	override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)
		
		let notificationCenter = NSNotificationCenter.defaultCenter()
		notificationCenter.removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
		notificationCenter.removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
	}

	/*--------------------------------------------------------------------------------------------
	* Events
	*--------------------------------------------------------------------------------------------*/
	
	func photoViewHasFocus(sender: NSNotification) {
		self.view.endEditing(true)
	}
	
	func photoDidChange(sender: NSNotification) {
		viewWillLayoutSubviews()
	}
	
	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
	}
	
	func keyboardWillBeShown(sender: NSNotification) {
		/*
		* Called when the UIKeyboardDidShowNotification is sent.
		*/
		let info: NSDictionary = sender.userInfo!
		let value = info.valueForKey(UIKeyboardFrameBeginUserInfoKey) as! NSValue
		let keyboardSize = value.CGRectValue().size
		
		self.scrollView.contentInset = UIEdgeInsetsMake(self.scrollView.contentInset.top, 0, keyboardSize.height, 0)
		self.scrollView.scrollIndicatorInsets = scrollView.contentInset
		
		/*
		* If active text field is hidden by keyboard, scroll it so it's visible
		*/
		if self.activeTextField != nil {
			var visibleRect = self.view.frame
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
		self.scrollView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0)
		self.scrollView.scrollIndicatorInsets = scrollView.contentInset
	}
}

extension BaseEditViewController {
	/*
	 * UITextFieldDelegate
	 */
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
