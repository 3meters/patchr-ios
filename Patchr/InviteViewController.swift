//
//  LobbyViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import Branch

class InviteViewController: BaseViewController {
	
	var message					= AirLabelTitle()
	var invitePatchrButton   	= AirButton()
	var inviteFacebookButton	= AirButton()
	var inviteViaButton			= AirButton()
	var doneButton				= AirFeaturedButton()
	
	var inputEntity				: Patch!
	
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		super.loadView()
		initialize()
	}
    
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		let messageSize = self.message.sizeThatFits(CGSizeMake(228, CGFloat.max))
		
		self.message.anchorTopCenterWithTopPadding(0, width: 228, height: messageSize.height)
		self.invitePatchrButton.alignUnder(self.message, matchingCenterWithTopPadding: 24, width: 228, height: 44)
		self.inviteFacebookButton.alignUnder(self.invitePatchrButton, matchingCenterWithTopPadding: 8, width: 228, height: 44)
		self.inviteViaButton.alignUnder(self.inviteFacebookButton, matchingCenterWithTopPadding: 8, width: 228, height: 44)
		self.doneButton.alignUnder(self.inviteViaButton, matchingCenterWithTopPadding: 8, width: 228, height: 44)
		
		self.contentHolder.resizeToFitSubviews()
		self.scrollView.contentSize = CGSizeMake(self.contentHolder.frame.size.width, self.contentHolder.frame.size.height + CGFloat(32))
		self.contentHolder.anchorTopCenterFillingWidthWithLeftAndRightPadding(16, topPadding: 16, height: self.contentHolder.frame.size.height)
	}
	
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
	func invitePatchrAction(sender: AnyObject?) {
		shareUsing(.Patchr)
	}
	
	func inviteFacebookAction(sender: AnyObject?) {
		shareUsing(.Facebook)
	}
	
	func inviteViaAction(sender: AnyObject?) {
		shareUsing(.Actions)
	}
	
	func doneAction(sender: AnyObject?) {
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
		setScreenName("PatchInvite")
		self.view.accessibilityIdentifier = View.Invite
		
		self.message.text = "Invite friends to your new patch."
		self.message.textAlignment = NSTextAlignment.Center
		self.message.numberOfLines = 0
		/*
		 * Invite dialog doesn't show if user is already a member or pending.
		 */
		self.invitePatchrButton.setTitle("PATCHR FRIENDS", forState: .Normal)
		self.inviteFacebookButton.setTitle("FACEBOOK FRIENDS", forState: .Normal)
		self.inviteViaButton.setTitle("MORE", forState: .Normal)
		self.doneButton.setTitle("FINISHED", forState: .Normal)
		
		self.invitePatchrButton.addTarget(self, action: #selector(InviteViewController.invitePatchrAction(_:)), forControlEvents: .TouchUpInside)
		self.inviteFacebookButton.addTarget(self, action: #selector(InviteViewController.inviteFacebookAction(_:)), forControlEvents: .TouchUpInside)
		self.inviteViaButton.addTarget(self, action: #selector(InviteViewController.inviteViaAction(_:)), forControlEvents: .TouchUpInside)
		self.doneButton.addTarget(self, action: #selector(InviteViewController.doneAction(_:)), forControlEvents: .TouchUpInside)
		
		self.contentHolder.addSubview(self.message)
		self.contentHolder.addSubview(self.invitePatchrButton)
		self.contentHolder.addSubview(self.inviteFacebookButton)
		self.contentHolder.addSubview(self.inviteViaButton)
		self.contentHolder.addSubview(self.doneButton)
		
		/* Navigation bar buttons */
		let submitButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: #selector(InviteViewController.doneAction(_:)))
		self.navigationItem.leftBarButtonItems = []
		self.navigationItem.hidesBackButton = true
		self.navigationItem.rightBarButtonItems = [submitButton]
	}
		
	func shareUsing(route: ShareRoute) {
		
		if route == .Patchr {
			
			let controller = MessageEditViewController()
			let navController = UINavigationController()
			controller.inputShareEntity = self.inputEntity
			controller.inputShareSchema = Schema.ENTITY_PATCH
			controller.inputShareId = self.inputEntity.id_!
			controller.inputMessageType = .Share
			controller.inputState = .Sharing
			navController.viewControllers = [controller]
			self.presentViewController(navController, animated: true, completion: nil)
		}
		else if route == .Facebook {
			
			let provider = FacebookProvider()
			provider.invite(self.inputEntity)
		}
		else if route == .Actions {
			
			BranchProvider.invite(self.inputEntity!, referrer: UserController.instance.currentUser) {
				response, error in
				
				if let error = ServerError(error) {
					UIViewController.topMostViewController()!.handleError(error)
				}
				else {
					let patch = response as! PatchItem
					let activityViewController = UIActivityViewController(
						activityItems: [patch],
						applicationActivities: nil)
					
					if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
						self.presentViewController(activityViewController, animated: true, completion: nil)
					}
					else {
						let popup: UIPopoverController = UIPopoverController(contentViewController: activityViewController)
						popup.presentPopoverFromRect(CGRectMake(self.view.frame.size.width/2, self.view.frame.size.height/4, 0, 0), inView: self.view, permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)
					}
				}
			}
		}
	}
}

