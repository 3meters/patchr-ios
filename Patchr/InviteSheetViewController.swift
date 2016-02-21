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
		self.buttonCancel.anchorBottomRightWithRightPadding(28, bottomPadding: 28, width: 48, height: 48)
	}
	
	override func viewWillAppear(animated: Bool) {
		self.inviteView.willAppear()
	}
	
	override func viewDidAppear(animated: Bool) {
		self.inviteView.didAppear()
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
		
		setScreenName("InviteSheet")
		
		self.view.backgroundColor = Colors.clear
		self.view.accessibilityIdentifier = View.Invitation
		self.inviteHolder.backgroundColor = Theme.colorBackgroundForm
		self.inviteHolder.layer.masksToBounds = false
		self.inviteHolder.layer.shadowOffset = CGSizeMake(0, -3)
		self.inviteHolder.layer.shadowRadius = 3
		self.inviteHolder.layer.shadowOpacity = 0.3
		
		self.buttonCancel.setImage(UIImage(named: "imgCancelDark"), forState: .Normal)
		self.buttonCancel.tintColor = Colors.brandColor
		self.buttonCancel.accessibilityIdentifier = "cancel_button"
		self.buttonCancel.addTarget(self, action: Selector("cancelAction:"), forControlEvents: .TouchUpInside)
		
		self.inviteHolder.addSubview(self.inviteView)
		self.view.addSubview(self.inviteHolder)
		self.view.addSubview(self.buttonCancel)
	}
}

