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
		
		let tap = UITapGestureRecognizer(target: self, action: #selector(BaseViewController.dismissKeyboard(sender:)));
		tap.delegate = self
		tap.cancelsTouchesInView = false
		self.view.addGestureRecognizer(tap)
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
		
		self.scrollView.frame = UIScreen.main.applicationFrame
		self.scrollView.backgroundColor = Theme.colorBackgroundForm
		self.scrollView.bounces = true
		self.scrollView.alwaysBounceVertical = true
		self.scrollView.addSubview(self.contentHolder)
		
        self.view.addSubview(self.scrollView)
	}
	
	func close(animated: Bool = true) {
		/* Override in subclasses for control of dismiss/pop process */
		if isModal {
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
	
	func nullToNil(value: AnyObject?) -> AnyObject? {
		if value is NSNull {
			return nil
		} else {
			return value
		}
	}
	
	func nilToNull(value: AnyObject?) -> AnyObject? {
		if value == nil {
			return NSNull()
		} else {
			return value
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

extension BaseViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		if (touch.view is UIButton) {
			return false
		}
		return true
	}
}