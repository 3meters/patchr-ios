//
//  BaseViewController.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {
	
	var scrollView		= AirScrollView()
	var contentHolder	= UIView()
		
	var isModal: Bool {
		return self.presentingViewController?.presentedViewController == self
			|| (self.navigationController != nil && self.navigationController?.presentingViewController?.presentedViewController == self.navigationController)
			|| self.tabBarController?.presentingViewController is UITabBarController
	}
	
	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		let tap = UITapGestureRecognizer(target: self, action: "dismissKeyboard");
		tap.delegate = self
		tap.cancelsTouchesInView = false
		self.view.addGestureRecognizer(tap)
    }
	
	/*--------------------------------------------------------------------------------------------
	* Events
	*--------------------------------------------------------------------------------------------*/

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		self.view.backgroundColor = Theme.colorBackgroundForm
		
		let fullScreenRect = UIScreen.mainScreen().applicationFrame
		self.scrollView.frame = fullScreenRect
		self.scrollView.backgroundColor = Theme.colorBackgroundForm
		self.scrollView.bounces = true
		self.scrollView.alwaysBounceVertical = true
		self.scrollView.addSubview(self.contentHolder)
		self.view = self.scrollView
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
	
	func stringsAreEqual(string1: String?, string2: String?) -> Bool {
		if isEmptyString(string1) != isEmptyString(string2) {
			/* We know one is empty and one is not */
			return false
		}
		else if !isEmptyString(string1) {
			/* Both have a value */
			return string1 == string2
		}
		return true // Both are empty
	}
	
	func isEmptyString(value : String?) -> Bool {
		return (value == nil || value!.isEmpty)
	}	
}

extension BaseViewController: UIGestureRecognizerDelegate {
	
	func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool    {
		if (touch.view is UIButton) {
			return false
		}
		return true
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

enum State: Int {
	case Editing
	case Creating
	case Onboarding
	case Sharing
	case Searching
}