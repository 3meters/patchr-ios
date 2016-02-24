//
//  UserDetailView.swift
//  Patchr
//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

//enum InviteResult: Int {
//	case Join
//	case Login
//	case Signup
//	case Finished
//}
//
//protocol InviteProtocol {
//	func inviteResult(result: InviteResult)
//}

class UserInviteViewOld: BaseDetailView {
	
	var delegate			: InviteProtocol?

	var message				= AirLabelDisplay()
	var photo				= UserPhotoView()
	var joinButton			= AirLinkButton()
	var loginButton			= AirLinkButton()
	var signupButton		= AirLinkButton()
	var userGroup			= UIView()
	var buttonGroup			= UIView()
	var patch				: Patch?
	
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
		
		let columnLeft = CGFloat(48 + 8)
		let columnWidth = self.width() - columnLeft
		let messageSize = self.message.sizeThatFits(CGSizeMake(columnWidth, CGFloat.max))
		
		self.photo.anchorTopLeftWithLeftPadding(8, topPadding: 8, width: 48, height: 48)
		self.message.alignToTheRightOf(self.photo, matchingTopAndFillingWidthWithLeftAndRightPadding: 8, height: messageSize.height)
		self.userGroup.anchorTopCenterFillingWidthWithLeftAndRightPadding(0, topPadding: 0, height: 96)
		
		if !self.joinButton.hidden {
			self.buttonGroup.alignUnder(self.userGroup, matchingLeftAndRightWithTopPadding: 8, height: 44)
			self.joinButton.anchorInCenterWithWidth(192, height: 44)
		}
		else if !self.loginButton.hidden && !self.signupButton.hidden {
			self.buttonGroup.alignUnder(self.userGroup, matchingCenterWithTopPadding: 8, width: 200, height: 44)
			self.loginButton.anchorCenterLeftWithLeftPadding(0, width: 96, height: 44)
			self.signupButton.alignToTheRightOf(self.loginButton, matchingCenterWithLeftPadding: 8, width: 96, height: 44)
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
