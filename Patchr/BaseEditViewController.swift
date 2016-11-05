//
//  BaseViewController.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import AWSS3
import Firebase

class BaseEditViewController: BaseViewController, UITextFieldDelegate {
	
    var imageUploadRequest: AWSS3TransferManagerUploadRequest?    
	var activeTextField		: UIView?
	
	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
    
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
        NotificationCenter.default.addObserver(self, selector: #selector(photoViewHasFocus(sender:)), name: NSNotification.Name(rawValue: Events.PhotoViewHasFocus), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeShown(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Events.PhotoViewHasFocus), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
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
    
    func photoRemoved(sender: NSNotification) {
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
		let info: NSDictionary = sender.userInfo! as NSDictionary
		let value = info.value(forKey: UIKeyboardFrameBeginUserInfoKey) as! NSValue
		let keyboardSize = value.cgRectValue.size
		
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
			
			if (!visibleRect.contains(activeTextFieldOrigin!)) {
				self.scrollView.scrollRectToVisible(activeTextFieldRect!, animated:true)
			}
		}
	}
 
	func keyboardWillBeHidden(sender: NSNotification) {
		/*
		* Called when the UIKeyboardWillHideNotification is sent.
		*/
		self.scrollView.contentInset = UIEdgeInsetsMake(self.scrollView.contentInset.top, 0, 0, 0)
		self.scrollView.scrollIndicatorInsets = scrollView.contentInset
	}
}

extension BaseEditViewController {
	/*
	 * UITextFieldDelegate
	 */
	func textFieldDidBeginEditing(_ textField: UITextField) {
		self.activeTextField = textField
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		if self.activeTextField == textField {
			self.activeTextField = nil
		}
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		return true
	}
}
