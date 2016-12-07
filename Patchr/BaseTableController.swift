//
//  BaseViewController.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class BaseTableController: UIViewController {
	
    var activity = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    
	var presented: Bool {
		return self.presentingViewController?.presentedViewController == self
			|| (self.navigationController != nil && self.navigationController?.presentingViewController?.presentedViewController == self.navigationController)
			|| self.tabBarController?.presentingViewController is UITabBarController
	}
	
	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
    
    override func viewWillLayoutSubviews() {
        self.activity.anchorInCenter(withWidth: 20, height: 20)
    }
    
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	/*--------------------------------------------------------------------------------------------
	* Events
	*--------------------------------------------------------------------------------------------*/

	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	func initialize() {
        self.view.backgroundColor = Theme.colorBackgroundForm
        self.activity.color = Theme.colorActivityIndicator
        self.activity.hidesWhenStopped = true
	}
	
	func close(animated: Bool = true) {
		/* Override in subclasses for control of dismiss/pop process */
		if self.presented {
			if self.navigationController != nil {
				self.navigationController!.dismiss(animated: animated, completion: nil)
			}
			else {
				self.dismiss(animated: animated, completion: nil)
			}
		}
		else {
			let _ = self.navigationController?.popViewController(animated: true)
		}
	}
	
	func dismissKeyboard(sender: NSNotification) {
		self.view.endEditing(true)
	}
    
    func emptyToNull(_ value: String?) -> NSObject {
        if value == nil || value!.isEmpty {
            return NSNull()
        }
        return (value! as NSString)
    }
	
    func emptyToNil(_ value: String?) -> String? {
        if value == nil || value!.isEmpty {
            return nil
        }
        return value
    }
    
	func nullToNil(_ value: AnyObject?) -> AnyObject? {
		if value is NSNull {
			return nil
		} else {
			return value
		}
	}
	
	func nilToNull(_ value: Any?) -> NSObject {
		if value == nil {
			return NSNull()
		} else {
			return value as! NSObject
		}
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
