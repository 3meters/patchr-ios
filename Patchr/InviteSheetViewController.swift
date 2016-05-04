//
//  LobbyViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class InviteSheetViewController: UIViewController {

	var inviteView				= UserInviteView()
	var inviteHolder			= UIView()
	var buttonCancel			= AirLinkButton()
	var patch					: Patch?
	
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		super.loadView()
		initialize()
	}
    
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		self.inviteHolder.anchorBottomCenterFillingWidthWithLeftAndRightPadding(0, bottomPadding: 0, height: 180)
		self.inviteView.fillSuperviewWithLeftPadding(16, rightPadding: 16, topPadding: 16, bottomPadding: 16)
		self.buttonCancel.anchorTopRightWithRightPadding(0, topPadding: 0, width: 48, height: 48)
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		if UserController.instance.authenticated {
			if self.patch != nil && self.patch?.userWatchStatusValue == .Member {
				self.dismissViewControllerAnimated(true, completion: nil)
				UIShared.Toast("You are already a member of this patch!")
			}
			else {
				self.inviteView.joinButton.hidden = false
				self.inviteView.loginButton.hidden = true
				self.inviteView.signupButton.hidden = true
				self.inviteView.setNeedsLayout()
			}
		}
		else {
			self.inviteView.joinButton.hidden = true
			self.inviteView.loginButton.hidden = false
			self.inviteView.signupButton.hidden = false
			self.inviteView.setNeedsLayout()
		}
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		if UserController.instance.authenticated {
			Utils.delay(0.5) {
				Animation.bounce(self.inviteView.joinButton)
			}
		}
	}
	
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
	
	func cancelAction(sender: AnyObject?) {
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		
		Reporting.screen("InviteSheet")
		
		self.view.backgroundColor = Theme.colorScrimInvite
		self.view.accessibilityIdentifier = View.Invitation
		self.inviteHolder.backgroundColor = Theme.colorBackgroundForm
		self.inviteHolder.layer.masksToBounds = false
		self.inviteHolder.layer.shadowOffset = CGSizeMake(0, -3)
		self.inviteHolder.layer.shadowRadius = 3
		self.inviteHolder.layer.shadowOpacity = 0.3
		
		self.buttonCancel.setImage(UIImage(named: "imgCancelDark"), forState: .Normal)
		self.buttonCancel.tintColor = Colors.brandColor
		self.buttonCancel.accessibilityIdentifier = "cancel_button"
		self.buttonCancel.addTarget(self, action: #selector(InviteSheetViewController.cancelAction(_:)), forControlEvents: .TouchUpInside)
		
		self.inviteHolder.addSubview(self.inviteView)
		self.inviteHolder.addSubview(self.buttonCancel)
		self.view.addSubview(self.inviteHolder)
	}
}
