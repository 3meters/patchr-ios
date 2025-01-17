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
    var controllerIsActive = false

	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(sender:)));
        tap.delegate = self
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        self.controllerIsActive = (UIApplication.shared.applicationState == .active)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        self.contentHolder.resizeToFitSubviews()
        Log.v("contentHolder width:\(self.contentHolder.frame.size.width), height: \(self.contentHolder.frame.size.height)")
        self.scrollView.contentSize = CGSize(width: self.contentHolder.frame.size.width, height: self.contentHolder.frame.size.height + CGFloat(32))
        self.scrollView.fillSuperview()
        self.contentHolder.anchorTopCenterFillingWidth(withLeftAndRightPadding: 16, topPadding: 16, height: self.contentHolder.frame.size.height)
    }
    
    deinit {
        Log.v("\(self.className) released")
    }
	
	/*--------------------------------------------------------------------------------------------
	* Notifications
	*--------------------------------------------------------------------------------------------*/

    @objc func viewDidBecomeActive(sender: NSNotification) {
        /* User either switched to app, launched app, or turned their screen back on with app in foreground. */
        self.controllerIsActive = true
    }
    
    @objc func viewWillResignActive(sender: NSNotification) {
        /* User either switched away from app or turned their screen off. */
        self.controllerIsActive = false
    }

	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		self.view.backgroundColor = Theme.colorBackgroundForm
		
		self.scrollView.backgroundColor = Theme.colorBackgroundForm
		self.scrollView.bounces = true
		self.scrollView.alwaysBounceVertical = true
        
		self.scrollView.addSubview(self.contentHolder)		
        self.view.addSubview(self.scrollView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(viewWillResignActive(sender:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(viewDidBecomeActive(sender:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
	}
	
	@objc func dismissKeyboard(sender: NSNotification) {
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

extension BaseViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		if (touch.view is UIButton) {
			return false
		}
		return true
	}
}
