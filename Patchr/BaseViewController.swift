//
//  BaseViewController.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {
	
	var spacer: UIBarButtonItem {
		let space = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
		space.width = SPACER_WIDTH
		return space
	}
	
	var isModal: Bool {
		return self.presentingViewController?.presentedViewController == self
			|| (self.navigationController != nil && self.navigationController?.presentingViewController?.presentedViewController == self.navigationController)
			|| self.tabBarController?.presentingViewController is UITabBarController
	}
	
	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

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
		self.view.backgroundColor = Theme.colorBackgroundScreen
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
	
	func rectVisible(rect: CGRect) -> Bool {
		var visibleRect: CGRect = CGRect()
		if let scrollView = self.view as? UIScrollView {
			visibleRect.origin = scrollView.contentOffset;
			visibleRect.origin.y += scrollView.contentInset.top;
			visibleRect.size = scrollView.bounds.size;
			visibleRect.size.height -= scrollView.contentInset.top + scrollView.contentInset.bottom;
		}
		return CGRectContainsRect(visibleRect, rect);
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