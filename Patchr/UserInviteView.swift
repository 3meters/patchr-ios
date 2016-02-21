//
//  UserDetailView.swift
//  Patchr
//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

enum InviteResult: Int {
	case Join
	case Login
	case Signup
}

protocol InviteProtocol {
	func inviteResult(result: InviteResult)
}

class UserInviteView: BaseDetailView {
	
	var delegate			: InviteProtocol?

	var message				= AirLabelDisplay()
	var photo				= UserPhotoView()
	var joinButton			= AirFeaturedButton()
	var loginButton			= AirButton()
	var signupButton		= AirButton()
	var userGroup			= UIView()
	var buttonGroup			= UIView()
	
	init() {
		super.init(frame: CGRectZero)
		initialize()
	}
	
	override init(frame: CGRect) {
		/* Called when instantiated from code */
		super.init(frame: frame)
		initialize()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("This view should never be loaded from storyboard")
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		let columnLeft = CGFloat(96 + 8)
		let columnWidth = self.width() - columnLeft
		let messageSize = self.message.sizeThatFits(CGSizeMake(columnWidth, CGFloat.max))
		
		self.photo.anchorTopLeftWithLeftPadding(0, topPadding: 0, width: 96, height: 96)
		self.message.alignToTheRightOf(self.photo, matchingCenterAndFillingWidthWithLeftAndRightPadding: 8, height: messageSize.height)
		self.userGroup.anchorTopCenterFillingWidthWithLeftAndRightPadding(0, topPadding: 0, height: 96)
		
		if UserController.instance.authenticated {
			self.buttonGroup.alignUnder(self.userGroup, matchingLeftAndRightWithTopPadding: 8, height: 44)
			self.joinButton.anchorInCenterWithWidth(192, height: 44)
		}
		else {
			self.buttonGroup.alignUnder(self.userGroup, matchingCenterWithTopPadding: 8, width: 200, height: 44)
			self.loginButton.anchorCenterLeftWithLeftPadding(0, width: 96, height: 44)
			self.signupButton.alignToTheRightOf(self.loginButton, matchingCenterWithLeftPadding: 8, width: 96, height: 44)
		}
	}
	
	func willAppear() {
		if UserController.instance.authenticated {
			self.joinButton.hidden = false
			self.loginButton.hidden = true
			self.signupButton.hidden = true
		}
		else {
			self.joinButton.hidden = true
			self.loginButton.hidden = false
			self.signupButton.hidden = false
		}
		self.setNeedsLayout()
	}
	
	func didAppear() {
		if UserController.instance.authenticated {
			Utils.delay(0.5) {
				Animation.bounce(self.joinButton)
			}
		}
	}
	
	/*--------------------------------------------------------------------------------------------
	* Events
	*--------------------------------------------------------------------------------------------*/
	
	func joinAction(sender: AnyObject?) {
		self.delegate?.inviteResult(.Join)
	}
	
	func loginAction(sender: AnyObject?) {
		let controller = LoginViewController()
		let navController = UINavigationController()
		navController.viewControllers = [controller]
		controller.onboardMode = OnboardMode.Login
		controller.inputRouteToMain = false
		UIViewController.topMostViewController()!.presentViewController(navController, animated: true) {}
	}
	
	func signupAction(sender: AnyObject?) {
		let controller = LoginViewController()
		let navController = UINavigationController()
		navController.viewControllers = [controller]
		controller.onboardMode = OnboardMode.Signup
		controller.inputRouteToMain = false
		UIViewController.topMostViewController()!.presentViewController(navController, animated: true) {}
	}
	
	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/

	func initialize() {
		
		/* message */
		self.message.numberOfLines = 3
		
		self.userGroup.addSubview(self.photo)
		self.userGroup.addSubview(self.message)
		
		self.joinButton.setTitle("JOIN", forState: .Normal)
		self.loginButton.setTitle("LOG IN", forState: .Normal)
		self.signupButton.setTitle("SIGN UP", forState: .Normal)
		self.joinButton.addTarget(self, action: Selector("joinAction:"), forControlEvents: .TouchUpInside)
		self.loginButton.addTarget(self, action: Selector("loginAction:"), forControlEvents: .TouchUpInside)
		self.signupButton.addTarget(self, action: Selector("signupAction:"), forControlEvents: .TouchUpInside)
		
		self.buttonGroup.addSubview(self.joinButton)
		self.buttonGroup.addSubview(self.loginButton)
		self.buttonGroup.addSubview(self.signupButton)
		
		self.addSubview(self.userGroup)
		self.addSubview(buttonGroup)
	}
	
	func bind(message: String!, photoUrl: NSURL?, name: String!) {
		
		self.message.text?.removeAll(keepCapacity: false)
		self.message.text = message
		self.photo.bindPhoto(photoUrl, name: name)
		self.setNeedsLayout()
	}
}
