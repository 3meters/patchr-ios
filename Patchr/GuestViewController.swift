//
//  LobbyViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class GuestViewController: BaseViewController {
	
	var appName			= AirLabelBanner()
	var buttonLogin		= AirButton()
	var buttonSignup	= AirButton()
	var message			= AirLabel()
	var buttonCancel	= AirButtonLink()
	var buttonGroup		= UIView()
	
	var inputMessage: String?
	
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		super.loadView()
		initialize()
	}
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()

		let messageSize = self.message.sizeThatFits(CGSizeMake(288, CGFloat.max))

		self.buttonGroup.anchorInCenterWithWidth(228, height: 96)
		self.buttonLogin.anchorTopCenterFillingWidthWithLeftAndRightPadding(0, topPadding: 0, height: 44)
		self.buttonSignup.anchorBottomCenterFillingWidthWithLeftAndRightPadding(0, bottomPadding: 0, height: 44)
		self.message.alignAbove(self.buttonGroup, matchingCenterWithBottomPadding: 20, width: 228, height: messageSize.height + 24)
		self.appName.alignAbove(self.message, matchingCenterWithBottomPadding: 20, width: 228, height: 48)
		self.buttonCancel.anchorTopLeftWithLeftPadding(24, topPadding: 24, width: 48, height: 48)
	}
	
	func loginAction(sender: AnyObject?) {
		let controller = LoginViewController()
		let navController = UINavigationController()
		navController.viewControllers = [controller]
		controller.onboardMode = OnboardMode.Login

		self.dismissViewControllerAnimated(true) {
			UIViewController.topMostViewController()!.presentViewController(navController, animated: true) {}
		}
	}
	
	func signupAction(sender: AnyObject?) {
		let controller = LoginViewController()
		let navController = UINavigationController()
		navController.viewControllers = [controller]
		controller.onboardMode = OnboardMode.Signup
		
		self.dismissViewControllerAnimated(true) {
			UIViewController.topMostViewController()!.presentViewController(navController, animated: true) {}
		}
	}
	
	func cancelAction(sender: AnyObject?) {
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
		self.view.backgroundColor = Theme.colorBackgroundOverlay

		setScreenName("GuestPrompt")
		
		self.appName.text = "Patchr"
		self.appName.textAlignment = NSTextAlignment.Center
		self.view.addSubview(self.appName)
		
		self.buttonCancel.setImage(UIImage(named: "imgCancelDark"), forState: .Normal)
		self.buttonCancel.tintColor = Colors.white
		self.view.addSubview(self.buttonCancel)
		
		self.message.text = self.inputMessage ?? "Sign up for a free account to post messages, create patches, and more!"
		self.message.textAlignment = NSTextAlignment.Center
		self.message.textColor = Colors.white
		self.message.numberOfLines = 0
		self.view.addSubview(self.message)
		
		self.buttonLogin.setTitle("LOG IN", forState: .Normal)
		self.buttonLogin.setTitleColor(UIColor.whiteColor(), forState: .Normal)
		self.buttonLogin.setTitleColor(Colors.brandColor, forState: .Highlighted)
		self.buttonLogin.borderColor = UIColor.whiteColor()
		self.buttonLogin.borderWidth = Theme.dimenButtonBorderWidth
		self.buttonLogin.cornerRadius = Theme.dimenButtonCornerRadius
		
		self.buttonSignup.setTitle("SIGN UP", forState: .Normal)
		self.buttonSignup.setTitleColor(UIColor.whiteColor(), forState: .Normal)
		self.buttonSignup.setTitleColor(Colors.brandColor, forState: .Highlighted)
		self.buttonSignup.borderColor = UIColor.whiteColor()
		self.buttonSignup.borderWidth = Theme.dimenButtonBorderWidth
		self.buttonSignup.cornerRadius = Theme.dimenButtonCornerRadius
		
		self.buttonGroup.addSubview(self.buttonLogin)
		self.buttonGroup.addSubview(self.buttonSignup)
		self.view.addSubview(self.buttonGroup)
		
		self.buttonLogin.addTarget(self, action: Selector("loginAction:"), forControlEvents: .TouchUpInside)
		self.buttonSignup.addTarget(self, action: Selector("signupAction:"), forControlEvents: .TouchUpInside)
		self.buttonCancel.addTarget(self, action: Selector("cancelAction:"), forControlEvents: .TouchUpInside)
	}
	
	override func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool    {
		if (touch.view is UIButton) {
			return false
		}
		self.cancelAction(nil)
		return true
	}
}

