//
//  UserDetailView.swift
//  Patchr
//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class UserInviteView: BaseDetailView {
	
	var message				= AirLabelDisplay()
	var member				= AirLabelDisplay()
	var photo				= UserPhotoView()
	var joinButton			= AirFeaturedButton()
	var loginButton			= AirLinkButton()
	var signupButton		= AirLinkButton()
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
		
		let messageSize = self.message.sizeThatFits(CGSizeMake(self.width(), CGFloat.max))
		
		self.photo.anchorTopCenterWithTopPadding(0, width: 64, height: 64)
		self.message.alignUnder(self.photo, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 8, height: messageSize.height)
		
		if !self.member.hidden {
			self.buttonGroup.alignUnder(self.message, matchingLeftAndRightWithTopPadding: 8, height: 32)
			self.member.fillSuperview()
		}
		else if !self.joinButton.hidden {
			self.buttonGroup.alignUnder(self.message, matchingLeftAndRightWithTopPadding: 8, height: 32)
			self.joinButton.anchorInCenterWithWidth(192, height: 32)
		}
		else if !self.loginButton.hidden && !self.signupButton.hidden {
			self.buttonGroup.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 200, height: 32)
			self.loginButton.anchorCenterLeftWithLeftPadding(0, width: 96, height: 32)
			self.signupButton.alignToTheRightOf(self.loginButton, matchingCenterWithLeftPadding: 8, width: 96, height: 32)
		}
	}
	
	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/

	func initialize() {
		
		/* message */
		self.message.numberOfLines = 3
		self.message.lineBreakMode = .ByTruncatingTail
		self.message.textAlignment = .Center
		
		self.addSubview(self.photo)
		self.addSubview(self.message)
		
		self.member.text = "You are a member of this patch!"
		self.member.textColor = Colors.accentColorDarker
		self.member.textAlignment = .Center
		self.member.numberOfLines = 1
		
		self.joinButton.setTitle("JOIN", forState: .Normal)
		self.loginButton.setTitle("LOG IN", forState: .Normal)
		self.signupButton.setTitle("SIGN UP", forState: .Normal)
		
		self.buttonGroup.addSubview(self.joinButton)
		self.buttonGroup.addSubview(self.loginButton)
		self.buttonGroup.addSubview(self.signupButton)
		self.buttonGroup.addSubview(self.member)
		
		self.addSubview(buttonGroup)
	}
	
	func bind(message: String!, photoUrl: NSURL?, name: String!) {
		
		self.message.text?.removeAll(keepCapacity: false)
		self.message.text = message
		self.photo.bindPhoto(photoUrl, name: name)
		self.setNeedsLayout()
	}
}
