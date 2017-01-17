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
    var controllerIsActive = false
    var statusBarHidden: Bool = false {
        didSet {
            UIView.animate(withDuration: 0.5) { () -> Void in
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    
    var presentedShallow: Bool {
        return self.presentingViewController?.presentedViewController == self
            || (self.navigationController?.presentingViewController?.presentedViewController == self.navigationController)
    }
    
	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.controllerIsActive = (UIApplication.shared.applicationState == .active)
    }
    
    override func viewWillLayoutSubviews() {
        //self.activity.anchorInCenter(withWidth: 20, height: 20)
    }
	
	/*--------------------------------------------------------------------------------------------
	* Notifications
	*--------------------------------------------------------------------------------------------*/
    
    func viewDidBecomeActive(sender: NSNotification) {
        /* User either switched to app, launched app, or turned their screen back on with app in foreground. */
        self.controllerIsActive = true
    }
    
    func viewWillResignActive(sender: NSNotification) {
        /* User either switched away from app or turned their screen off. */
        self.controllerIsActive = false
    }

	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	func initialize() {
        self.view.backgroundColor = Theme.colorBackgroundForm
        self.activity.color = Theme.colorActivityIndicator
        self.activity.hidesWhenStopped = true
        NotificationCenter.default.addObserver(self, selector: #selector(viewWillResignActive(sender:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(viewDidBecomeActive(sender:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
	}
	
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }
    
    override var prefersStatusBarHidden: Bool {
        return self.statusBarHidden
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
