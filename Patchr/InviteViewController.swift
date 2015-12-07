//
//  LobbyViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class InviteViewController: BaseViewController {
	
	var message					= AirLabelTitle()
	var invitePatchrButton   	= AirButton()
	var inviteFacebookButton	= AirButton()
	var inviteViaButton			= AirButton()
	var cancelButton			= AirButtonFeatured()
	var scrollView				= AirScrollView()
	var contentHolder			= UIView()
	
	var inputEntity				: Patch!
	
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
		
		self.message.anchorTopCenterWithTopPadding(0, width: 228, height: messageSize.height)
		self.invitePatchrButton.alignUnder(self.message, matchingCenterWithTopPadding: 24, width: 228, height: 44)
		self.inviteFacebookButton.alignUnder(self.invitePatchrButton, matchingCenterWithTopPadding: 8, width: 228, height: 44)
		self.inviteViaButton.alignUnder(self.inviteFacebookButton, matchingCenterWithTopPadding: 8, width: 228, height: 44)
		self.cancelButton.alignUnder(self.inviteViaButton, matchingCenterWithTopPadding: 8, width: 228, height: 44)
		
		self.contentHolder.resizeToFitSubviews()
		self.scrollView.contentSize = CGSizeMake(self.contentHolder.frame.size.width, self.contentHolder.frame.size.height + CGFloat(32))
		self.contentHolder.anchorTopCenterFillingWidthWithLeftAndRightPadding(16, topPadding: 16, height: self.contentHolder.frame.size.height)
	}
	
	func invitePatchrAction(sender: AnyObject?) {
		shareUsing(.Patchr)
	}
	
	func inviteFacebookAction(sender: AnyObject?) {
		shareUsing(.Facebook)
	}
	
	func inviteViaAction(sender: AnyObject?) {
		shareUsing(.Actions)
	}
	
	func cancelAction(sender: AnyObject?) {
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
		setScreenName("PatchInvite")
		
		let fullScreenRect = UIScreen.mainScreen().applicationFrame
		self.scrollView.frame = fullScreenRect
		self.scrollView.backgroundColor = Theme.colorBackgroundScreen
		self.scrollView.addSubview(self.contentHolder)
		self.view = self.scrollView
		
		self.message.text = "Invite friends to your new patch!"
		self.message.textAlignment = NSTextAlignment.Center
		self.message.numberOfLines = 0
		/*
		 * Invite dialog doesn't show if user is already a member or pending.
		 */
		self.invitePatchrButton.setTitle("PATCHR FRIENDS", forState: .Normal)
		self.inviteFacebookButton.setTitle("FACEBOOK FRIENDS", forState: .Normal)
		self.inviteViaButton.setTitle("MORE", forState: .Normal)
		self.cancelButton.setTitle("FINISHED", forState: .Normal)
		
		self.invitePatchrButton.addTarget(self, action: Selector("invitePatchrAction:"), forControlEvents: .TouchUpInside)
		self.inviteFacebookButton.addTarget(self, action: Selector("inviteFacebookAction:"), forControlEvents: .TouchUpInside)
		self.inviteViaButton.addTarget(self, action: Selector("inviteViaAction:"), forControlEvents: .TouchUpInside)
		self.cancelButton.addTarget(self, action: Selector("cancelAction:"), forControlEvents: .TouchUpInside)
		
		self.contentHolder.addSubview(self.message)
		self.contentHolder.addSubview(self.invitePatchrButton)
		self.contentHolder.addSubview(self.inviteFacebookButton)
		self.contentHolder.addSubview(self.inviteViaButton)
		self.contentHolder.addSubview(self.cancelButton)
		
		/* Navigation bar buttons */
		let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "doneAction:")
		self.navigationItem.leftBarButtonItems = []
		self.navigationItem.hidesBackButton = true
		self.navigationItem.rightBarButtonItems = [doneButton]
	}
		
	func shareUsing(route: ShareRoute) {
		
		if route == .Patchr {
			
			let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
			let controller = storyboard.instantiateViewControllerWithIdentifier("MessageEditViewController") as? MessageEditViewController
			/* viewDidLoad hasn't fired yet but awakeFromNib has */
			controller?.inputShareEntity = self.inputEntity
			controller?.inputShareSchema = Schema.ENTITY_PATCH
			controller?.inputShareId = self.inputEntity.id_!
			controller?.inputMessageType = .Share
			let navController = UINavigationController(rootViewController: controller!)
			navController.navigationBar.tintColor = Colors.brandColorDark
			self.presentViewController(navController, animated: true, completion: nil)
		}
		else if route == .Facebook {
			
			let provider = FacebookProvider()
			if FBSDKAccessToken.currentAccessToken() == nil {
				provider.authorize { response, error in
					if FBSDKAccessToken.currentAccessToken() != nil {
						provider.invite(self.inputEntity)
					}
				}
			}
			else {
				provider.invite(self.inputEntity)
			}
		}
		else if route == .Actions {
			
			let inviterName = UserController.instance.currentUser.id_
			Branch.getInstance().getShortURLWithParams(["entityId":self.inputEntity.id_!, "entitySchema":"patch", "inviterName":inviterName],
				andChannel: "patchr-ios",
				andFeature: BRANCH_FEATURE_TAG_INVITE,
				andCallback: { url, error in
					
					if let error = ServerError(error) {
						UIViewController.topMostViewController()!.handleError(error)
					}
					else {
						Log.d("Branch link created: \(url!)")
						let patch: PatchItem = PatchItem(entity: self.inputEntity, shareUrl: url!)
						
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
			})
		}
	}
}

