//
//  LobbyViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

enum InviteWelcomeResult: Int {
	case Join
	case Login
	case Signup
	case Cancel
}

protocol InviteWelcomeProtocol {
	func inviteResult(result: InviteWelcomeResult)
}

class InviteViewController: BaseViewController {

	var delegate: InviteWelcomeProtocol? = nil
	
	var message      	= AirLabelTitle()
	var joinButton   	= AirButtonFeatured()
	var loginButton		= AirButton()
	var signupButton 	= AirButton()
	var cancelButton	= AirButton()
	var dialog: UIVisualEffectView!
	
	var inputMessage: String?
	var inputPublic: Bool = true
	
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

		let messageSize = self.message.sizeThatFits(CGSizeMake(228, CGFloat.max))
		self.message.anchorTopCenterWithTopPadding(24, width: 228, height: messageSize.height)
		
		if UserController.instance.authenticated {
			self.joinButton.alignUnder(self.message, matchingCenterWithTopPadding: 24, width: 228, height: 44)
			self.cancelButton.alignUnder(self.joinButton, matchingCenterWithTopPadding: 8, width: 228, height: 44)
			self.dialog.anchorInCenterWithWidth(288, height: 48 + messageSize.height + 24 + 88 + 8)
		}
		else {
			self.loginButton.alignUnder(self.message, matchingCenterWithTopPadding: 24, width: 228, height: 44)
			self.signupButton.alignUnder(self.loginButton, matchingCenterWithTopPadding: 8, width: 228, height: 44)
			self.cancelButton.alignUnder(self.signupButton, matchingCenterWithTopPadding: 8, width: 228, height: 44)
			self.dialog.anchorInCenterWithWidth(288, height: 48 + messageSize.height + 24 + 132 + 16)
		}
	}
	
	func joinAction(sender: AnyObject?) {
		self.delegate?.inviteResult(.Join)
	}
	
	func loginAction(sender: AnyObject?) {
		self.delegate?.inviteResult(.Login)
	}
	
	func signupAction(sender: AnyObject?) {
		self.delegate?.inviteResult(.Signup)
	}
	
	func cancelAction(sender: AnyObject?) {
		self.delegate?.inviteResult(.Cancel)
	}
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
		setScreenName("InvitePrompt")
		
		self.view.backgroundColor = Colors.clear
		
		let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.ExtraLight)
		self.dialog = UIVisualEffectView(effect: blurEffect)
		self.dialog.cornerRadius = Theme.dimenButtonCornerRadius
		self.dialog.clipsToBounds = true

		self.view.addSubview(self.dialog)

		self.message.text = self.inputMessage!
		self.message.textColor = Theme.colorTextTitle
		self.message.textAlignment = NSTextAlignment.Center
		self.message.numberOfLines = 0
		self.dialog.addSubview(self.message)
		/*
		 * Invite dialog doesn't show if user is already a member or pending.
		 */
		if UserController.instance.authenticated {
			self.joinButton.setTitle("JOIN", forState: .Normal)
			self.cancelButton.setTitle("NOT NOW", forState: .Normal)
			self.joinButton.addTarget(self, action: Selector("joinAction:"), forControlEvents: .TouchUpInside)
			self.dialog.addSubview(self.joinButton)
		}
		else {
			self.loginButton.setTitle("LOG IN", forState: .Normal)
			self.signupButton.setTitle("SIGN UP", forState: .Normal)
			self.cancelButton.setTitle("NOT NOW", forState: .Normal)
			self.loginButton.addTarget(self, action: Selector("loginAction:"), forControlEvents: .TouchUpInside)
			self.signupButton.addTarget(self, action: Selector("signupAction:"), forControlEvents: .TouchUpInside)
			self.dialog.addSubview(self.loginButton)
			self.dialog.addSubview(self.signupButton)
		}
		self.dialog.addSubview(self.cancelButton)
		self.cancelButton.addTarget(self, action: Selector("cancelAction:"), forControlEvents: .TouchUpInside)
	}
}
