//
//  InviteViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
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
		
        let messageSize = self.message.sizeThatFits(CGSize(width:228, height:CGFloat.greatestFiniteMagnitude))
		
		self.message.anchorTopCenter(withTopPadding: 0, width: 228, height: messageSize.height)
		self.invitePatchrButton.alignUnder(self.message, matchingCenterWithTopPadding: 24, width: 228, height: 44)
		self.inviteFacebookButton.alignUnder(self.invitePatchrButton, matchingCenterWithTopPadding: 8, width: 228, height: 44)
		self.inviteViaButton.alignUnder(self.inviteFacebookButton, matchingCenterWithTopPadding: 8, width: 228, height: 44)
		self.doneButton.alignUnder(self.inviteViaButton, matchingCenterWithTopPadding: 8, width: 228, height: 44)
		
		self.contentHolder.resizeToFitSubviews()
        self.scrollView.contentSize = CGSize(width:self.contentHolder.frame.size.width, height:self.contentHolder.frame.size.height + CGFloat(32))
        self.contentHolder.anchorTopCenterFillingWidth(withLeftAndRightPadding: 16, topPadding: 16, height: self.contentHolder.frame.size.height)
	}
	
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
	func invitePatchrAction(sender: AnyObject?) {
		shareUsing(route: .Patchr)
	}
	
	func inviteFacebookAction(sender: AnyObject?) {
		shareUsing(route: .Facebook)
	}
	
	func inviteViaAction(sender: AnyObject?) {
		shareUsing(route: .Actions)
	}
	
	func doneAction(sender: AnyObject?) {
		self.dismiss(animated: true, completion: nil)
	}
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
		Reporting.screen("PatchInvite")
		
		self.message.text = "Invite people to your new patch."
		self.message.textAlignment = NSTextAlignment.center
		self.message.numberOfLines = 0
		/*
		 * Invite dialog doesn't show if user is already a member or pending.
		 */
		self.invitePatchrButton.setTitle("PATCHR FRIENDS", for: .normal)
		self.inviteFacebookButton.setTitle("FACEBOOK FRIENDS", for: .normal)
		self.inviteViaButton.setTitle("MORE", for: .normal)
		self.doneButton.setTitle("FINISHED", for: .normal)
		
		self.invitePatchrButton.addTarget(self, action: #selector(InviteViewController.invitePatchrAction(sender:)), for: .touchUpInside)
		self.inviteFacebookButton.addTarget(self, action: #selector(InviteViewController.inviteFacebookAction(sender:)), for: .touchUpInside)
		self.inviteViaButton.addTarget(self, action: #selector(InviteViewController.inviteViaAction(sender:)), for: .touchUpInside)
		self.doneButton.addTarget(self, action: #selector(InviteViewController.doneAction(sender:)), for: .touchUpInside)
		
		self.contentHolder.addSubview(self.message)
		self.contentHolder.addSubview(self.invitePatchrButton)
		self.contentHolder.addSubview(self.inviteFacebookButton)
		self.contentHolder.addSubview(self.inviteViaButton)
		self.contentHolder.addSubview(self.doneButton)
		
		/* Navigation bar buttons */
		let submitButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(InviteViewController.doneAction(sender:)))
		self.navigationItem.leftBarButtonItems = []
		self.navigationItem.hidesBackButton = true
		self.navigationItem.rightBarButtonItems = [submitButton]
	}
		
	func shareUsing(route: ShareRoute) {
		
		if route == .Patchr {
			
			let controller = MessageEditViewController()
			let navController = AirNavigationController()
//			controller.inputShareEntity = self.inputEntity
//			controller.inputShareSchema = Schema.ENTITY_PATCH
//			controller.inputShareId = self.inputEntity.id_!
//			controller.inputMessageType = .Share
//			controller.inputState = .Sharing
			navController.viewControllers = [controller]
			self.present(navController, animated: true, completion: nil)
		}
		else if route == .Actions {
			
			BranchProvider.invite(entity: self.inputEntity!, referrer: ZUserController.instance.currentUser) {
				response, error in
				
				if let error = ServerError(error) {
					UIViewController.topMostViewController()!.handleError(error)
				}
				else {
					let patch = response as! PatchItem
					let activityViewController = UIActivityViewController(
						activityItems: [patch],
						applicationActivities: nil)
					
					if UIDevice.current.userInterfaceIdiom == .phone {
						self.present(activityViewController, animated: true, completion: nil)
					}
					else {
						let popup: UIPopoverController = UIPopoverController(contentViewController: activityViewController)
                        popup.present(from: CGRect(x:self.view.frame.size.width/2, y:self.view.frame.size.height/4, width:0, height:0), in: self.view, permittedArrowDirections: UIPopoverArrowDirection.any, animated: true)
					}
				}
			}
		}
	}
}

