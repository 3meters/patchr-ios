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
	var photo				= PhotoView()
	var joinButton			= AirFeaturedButton()
	var loginButton			= AirLinkButton()
	var signupButton		= AirLinkButton()
	var buttonGroup			= UIView()
	var patch				: Patch?
	
	init() {
		super.init(frame: CGRect.zero)
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
		
        let messageSize = self.message.sizeThatFits(CGSize(width:self.width(), height:CGFloat.greatestFiniteMagnitude))
		
		self.photo.anchorTopCenter(withTopPadding: 0, width: 64, height: 64)
		self.message.alignUnder(self.photo, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 8, height: messageSize.height)
		
		if !self.member.isHidden {
			self.buttonGroup.alignUnder(self.message, matchingLeftAndRightWithTopPadding: 8, height: 32)
			self.member.fillSuperview()
		}
		else if !self.joinButton.isHidden {
			self.buttonGroup.alignUnder(self.message, matchingLeftAndRightWithTopPadding: 8, height: 32)
			self.joinButton.anchorInCenter(withWidth: 192, height: 32)
		}
		else if !self.loginButton.isHidden && !self.signupButton.isHidden {
			self.buttonGroup.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 200, height: 32)
			self.loginButton.anchorCenterLeft(withLeftPadding: 0, width: 96, height: 32)
			self.signupButton.align(toTheRightOf: self.loginButton, matchingCenterWithLeftPadding: 8, width: 96, height: 32)
		}
	}
	
	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/

	func initialize() {
		
		/* message */
		self.message.numberOfLines = 3
		self.message.lineBreakMode = .byTruncatingTail
		self.message.textAlignment = .center
		
		self.addSubview(self.photo)
		self.addSubview(self.message)
		
		self.member.text = "You are a member of this patch!"
		self.member.textColor = Colors.accentColorDarker
		self.member.textAlignment = .center
		self.member.numberOfLines = 1
		
		self.joinButton.setTitle("JOIN", for: .normal)
		self.loginButton.setTitle("LOG IN", for: .normal)
		self.signupButton.setTitle("SIGN UP", for: .normal)
		
		self.buttonGroup.addSubview(self.joinButton)
		self.buttonGroup.addSubview(self.loginButton)
		self.buttonGroup.addSubview(self.signupButton)
		self.buttonGroup.addSubview(self.member)
		
		self.addSubview(buttonGroup)
	}
	
	func bind(message: String!, photoUrl: URL?, name: String!) {
		
		self.message.text?.removeAll(keepingCapacity: false)
		self.message.text = message
		self.photo.bindPhoto(photoUrl: photoUrl, name: name)
		self.setNeedsLayout()
	}
}
