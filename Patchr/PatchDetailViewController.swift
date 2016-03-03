//
//  PatchDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import Branch
import MessageUI
import iRate

class PatchDetailViewController: BaseDetailViewController {

    private var contextAction			: ContextAction = .SharePatch
	private var originalRect			: CGRect?
    private var originalScrollTop		= CGFloat(-64.0)
	
	var inputReferrerName		: String?
	var inputReferrerPhotoUrl	: String?
	var inviteView				: UserInviteView?
	var inviteActive			= false
	
	var autoWatchOnAppear		= false

	/*--------------------------------------------------------------------------------------------
	 * Lifecycle
	 *--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		/*
		* Inputs are already available.
		*/
		super.loadView()
		initialize()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		if self.showEmptyLabel {
			self.emptyLabel.layer.borderWidth = 0
		}
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.width())
		let header = self.header as! PatchDetailView
		let viewHeight = (viewWidth * 0.625) + header.contextGroup.height()
		self.tableView.tableHeaderView?.bounds.size = CGSizeMake(viewWidth, viewHeight)	// Triggers layoutSubviews on header
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)		// calls bind if we have cached entity
		if self.invalidated {
			Log.d("Resetting patch and messages because user logged in")
			fetch(strategy: .IgnoreCache, resetList: true)
		}
		else {
			fetch(strategy: .UseCacheAndVerify , resetList: self.firstAppearance)
		}
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)	// Clears firstAppearance
		
		if self.autoWatchOnAppear {
			self.autoWatchOnAppear = false
			let header = self.header as! PatchDetailView
			header.watchButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
			Utils.delay(1.0) {
				UIShared.Toast("You are now a member of this patch", controller: self, addToWindow: false)
			}
		}
		else {
			iRate.sharedInstance().promptIfAllCriteriaMet()
		}
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
	}
	
	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/
    
	func watchersAction(sender: AnyObject) {
		let controller = UserTableViewController()
		controller.patch = self.entity as! Patch
		controller.filter = .PatchWatchers
		self.navigationController?.pushViewController(controller, animated: true)
	}

	func contextButtonAction(sender: UIButton) {
		
		let header = self.header as! PatchDetailView
		
        if self.contextAction == .CreateMessage {
            if !UserController.instance.authenticated {
				UserController.instance.showGuestGuard(nil, message: "Sign up for a free account to post messages and more.")
                return
            }
            addAction()
        }
        else if self.contextAction == .SharePatch {
            shareAction(sender)
        }
        else if self.contextAction == .CancelJoinRequest {
            header.watchButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
        }
        else if self.contextAction == .SubmitJoinRequest || self.contextAction == .JoinPatch {
            if !UserController.instance.authenticated {
				UserController.instance.showGuestGuard(nil, message: "Sign up for a free account to join patches and more.")
                return
            }
            header.watchButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
        }
        else if self.contextAction == .BrowseUsersWatching {
            watchersAction(self)
        }
	}

    func mapAction(sender: AnyObject) {
		let controller = PatchMapViewController()
		controller.locationDelegate = self
		self.navigationController?.pushViewController(controller, animated: true)
    }
	
    func dismissAction(sender: AnyObject) {
		self.dismissViewControllerAnimated(true) {
			if UserController.instance.authenticated {
				let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
				let controller = MainTabBarController()
				controller.selectedIndex = 0
				appDelegate.window!.setRootViewController(controller, animated: true)
			}
		}
    }
	
    func addAction() {
        if !UserController.instance.authenticated {
			UserController.instance.showGuestGuard(nil, message: "Sign up for a free account to post messages and more.")
            return
        }
        /* Has its own nav because we segue modally and it needs its own stack */
		let controller = MessageEditViewController()
		let navController = UINavigationController()
		controller.inputToString = self.entity!.name
		controller.inputPatchId = self.entityId
		controller.inputState = .Creating
		navController.viewControllers = [controller]
		self.navigationController?.presentViewController(navController, animated: true, completion: nil)
    }
    
    func editAction() {
		let controller = PatchEditViewController()
		let navController = UINavigationController()
		controller.inputPatch = self.entity as? Patch
		navController.viewControllers = [controller]
		self.navigationController?.presentViewController(navController, animated: true, completion: nil)
    }
    
	func shareAction(sender: AnyObject?) {
		
		if !UserController.instance.authenticated {
			UserController.instance.showGuestGuard(nil, message: "Sign up for a free account to invite people to patches and more.")
			return
		}
		
        if self.entity != nil {
			
			let sheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
			
			let patchr = UIAlertAction(title: "Invite using Patchr", style: .Default) { action in
				self.shareUsing(.Patchr)
			}
			let facebook = UIAlertAction(title: "Invite using Facebook", style: .Default) { action in
				self.shareUsing(.Facebook)
			}
			let airdrop = UIAlertAction(title: "AirDrop", style: .Default) { action in
				self.shareUsing(.AirDrop)
			}
			let android = UIAlertAction(title: "More...", style: .Default) { action in
				self.shareUsing(.Actions)
			}
			let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { action in
				sheet.dismissViewControllerAnimated(true, completion: nil)
			}
			
			sheet.addAction(patchr)
			sheet.addAction(facebook)
			sheet.addAction(airdrop)
			sheet.addAction(android)
			sheet.addAction(cancel)
			
			if let presenter = sheet.popoverPresentationController {
				if let button = sender as? UIBarButtonItem {
					presenter.barButtonItem = button
				}
				else if let button = sender as? UIView {
					presenter.sourceView = button;
					presenter.sourceRect = button.bounds;
				}
			}
			
			presentViewController(sheet, animated: true, completion: nil)
        }
    }
	
	func reportAction(sender: AnyObject?) {
		
		let email = "report@3meters.com"
		let subject = "Report on Patchr content"
		let body = "Report on patch id: \(self.entityId!)\n\nPlease add some detail on why you are reporting this patch.\n"
		
		if MFMailComposeViewController.canSendMail() {
			MailComposer!.view.accessibilityIdentifier = View.Report
			MailComposer!.mailComposeDelegate = self
			MailComposer!.setToRecipients([email])
			MailComposer!.setSubject(subject)
			MailComposer!.setMessageBody(body, isHTML: false)
			
			self.presentViewController(MailComposer!, animated: true, completion: nil)
		}
		else {
			let queryURL = "subject=\(subject)&body=\(body)"
			let emailURL = "mailto:\(email)?\(queryURL.stringByAddingPercentEncodingWithAllowedCharacters(NSMutableCharacterSet.URLQueryAllowedCharacterSet()) ?? queryURL)"
			if let url = NSURL(string: emailURL) {
				UIApplication.sharedApplication().openURL(url)
			}
		}
	}

	func moreAction(sender: AnyObject?) {
		
		if !UserController.instance.authenticated {
			return
		}
		
		if self.entity != nil {
			
			let sheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
			
			if let patch = self.entity as? Patch {
				if patch.userWatchStatusValue == .Member {
					let leave = UIAlertAction(title: "Leave patch", style: .Destructive) { action in
						let header = self.header as! PatchDetailView
						header.watchButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
						Utils.delay(1.0) {
							UIShared.Toast("You have left this patch", controller: self, addToWindow: false)
						}
					}
					sheet.addAction(leave)
				}
			}

			let report = UIAlertAction(title: "Report patch", style: .Default) { action in
				self.reportAction(self)
			}
			let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { action in
				sheet.dismissViewControllerAnimated(true, completion: nil)
			}
			sheet.addAction(report)
			sheet.addAction(cancel)
			
			if let presenter = sheet.popoverPresentationController {
				if let button = sender as? UIBarButtonItem {
					presenter.barButtonItem = button
				}
				else if let button = sender as? UIView {
					presenter.sourceView = button;
					presenter.sourceRect = button.bounds;
				}
			}
			
			presentViewController(sheet, animated: true, completion: nil)
		}
	}
	
	func joinAction(sender: AnyObject?) {
		let header = self.header as! PatchDetailView
		header.watchButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside) // Should trigger fetch via watch notification
		AudioController.instance.play(Sound.pop.rawValue)
	}
	
	func cancelRequestAction(sender: AnyObject?) {
		let header = self.header as! PatchDetailView
		header.watchButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside) // Should trigger fetch via watch notification
		AudioController.instance.play(Sound.pop.rawValue)
	}
	
	func loginAction(sender: AnyObject?) {
		let controller = LoginViewController()
		let navController = UINavigationController()
		navController.viewControllers = [controller]
		controller.onboardMode = OnboardMode.Login
		controller.inputRouteToMain = false
		self.presentViewController(navController, animated: true) {}
	}
	
	func signupAction(sender: AnyObject?) {
		let controller = LoginViewController()
		let navController = UINavigationController()
		navController.viewControllers = [controller]
		controller.onboardMode = OnboardMode.Signup
		controller.inputRouteToMain = false
		self.presentViewController(navController, animated: true) {}
	}

	/*--------------------------------------------------------------------------------------------
	* Notifications
	*--------------------------------------------------------------------------------------------*/

	func didFetch(notification: NSNotification) {
		/*
		 * Called after fetch is complete for form entity. bind() is called
		 * just before this notification.
		 */
		bindContextView()
	}
	
	func didInsertMessage(sender: NSNotification) {
		if let patch = self.entity as? Patch {
			if patch.visibility != nil && !patch.userHasMessagedValue && patch.visibility == "public" {
				self.autoWatchOnAppear = true
			}
		}
	}
	
	func handleRemoteNotification(notification: NSNotification) {
		
		if let userInfo = notification.userInfo {
			let parentId = userInfo["parentId"] as? String
			let targetId = userInfo["targetId"] as? String
			
			let impactedByNotification = self.entityId == parentId || self.entityId == targetId
			
			// Only refresh notifications if view has already been loaded
			// and the notification is related to this Patch
			if self.isViewLoaded() && impactedByNotification {
				self.pullToRefreshAction(self.refreshControl)
			}
		}
	}
	
	func watchDidChange(sender: NSNotification) {
		Log.d("Resetting patch and messages because watch status changed")
		fetch(strategy: .IgnoreCache, resetList: true)
	}
	
	func applicationDidEnterBackground(sender: NSNotification) {
		if self.inputReferrerName != nil {
			self.dismissViewControllerAnimated(true, completion: nil)
		}
	}

	/*--------------------------------------------------------------------------------------------
	 * Methods
	 *--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		
		setScreenName("PatchDetail")
		self.view.accessibilityIdentifier = View.PatchDetail

		self.queryName = DataStoreQueryName.MessagesForPatch.rawValue
		
		self.header = PatchDetailView()
		self.tableView = AirTableView(frame: self.tableView.frame, style: .Plain)
		self.tableView.estimatedRowHeight = 0	// Zero turns off estimates
		self.tableView.rowHeight = 0			// Actual height is handled in heightForRowAtIndexPath
		
		let header = self.header as! PatchDetailView
		
		header.mapButton.addTarget(self, action: Selector("mapAction:"), forControlEvents: .TouchUpInside)
		header.watchersButton.addTarget(self, action: Selector("watchersAction:"), forControlEvents: UIControlEvents.TouchUpInside)
		header.moreButton.addTarget(self, action: Selector("moreAction:"), forControlEvents: .TouchUpInside)
		header.infoMoreButton.addTarget(self, action: Selector("moreAction:"), forControlEvents: .TouchUpInside)
		
		if let contextButton = header.contextView as? AirFeaturedButton {
			contextButton.addTarget(self, action: Selector("contextButtonAction:"), forControlEvents: .TouchUpInside)
			contextButton.setTitle("", forState: .Normal)
		}

		NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleRemoteNotification:", name: PAApplicationDidReceiveRemoteNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "didFetch:", name: Events.DidFetch, object: self)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "watchDidChange:", name: Events.WatchDidChange, object: header.watchButton)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "didInsertMessage:", name: Events.DidInsertMessage, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidEnterBackground:", name: UIApplicationDidEnterBackgroundNotification, object: nil)

		/* UI prep */
		self.patchNameVisible = false
		if self.inputReferrerName != nil {
			self.inviteActive = true
		}
		
		self.showEmptyLabel = true
		self.showProgress = true
		self.progressOffsetY = 80
		self.loadMoreMessage = "LOAD MORE MESSAGES"
		
		/* Navigation bar buttons */
		drawButtons()
	}
	
	override func bind() {
        
        if let patch = self.entity as? Patch {
			
			self.disableCells = (patch.visibility == "private" && !patch.userIsMember())
			
			let header = self.header as! PatchDetailView

			header.bindToEntity(patch)
			bindContextView()

			self.emptyMessage = (patch.visibility == "private") ? "Only members can see messages" : "Be the first to post a message to this patch"
			self.emptyLabel.text = self.emptyMessage
			
			if self.tableView.tableHeaderView == nil {
				let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.width())
				let viewHeight = (viewWidth * 0.625) + 48
				header.frame = CGRectMake(0, 0, viewWidth, viewHeight)
				header.setNeedsLayout()
				header.layoutIfNeeded()
				header.photo.frame = CGRectMake(-24, -36, header.bannerGroup.width() + 48, header.bannerGroup.height() + 72)
				self.originalRect = header.photo.frame
				self.tableView.tableHeaderView = self.header
				self.tableView.reloadData()
			}
        }
	}

	override func drawButtons() {
		
		let shareButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: Selector("shareAction:"))
		let addButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: Selector("addAction"))
		let editButton = UIBarButtonItem(image: Utils.imageEdit, style: UIBarButtonItemStyle.Plain, target: self, action: Selector("editAction"))
		
		if isUserOwner() {
			self.navigationItem.setRightBarButtonItems([addButton, Utils.spacer, shareButton, Utils.spacer, editButton], animated: true)
		}
		else {
			self.navigationItem.setRightBarButtonItems([addButton, Utils.spacer, shareButton], animated: true)
		}
	}
	
	func bindContextView() {
		
		if let patch = self.entity as? Patch {
			
			let header = self.header as! PatchDetailView
			
			/* Do we have an active invite and a non-member? */
			if self.inviteActive  {
					
				if !(header.contextView is UserInviteView) {
					header.contextView.removeFromSuperview()
					let url = self.inputReferrerPhotoUrl != nil ? NSURL(string: self.inputReferrerPhotoUrl!) : nil
					let inviteView = UserInviteView()
					inviteView.bind("\(self.inputReferrerName!) has invited you to join this patch.", photoUrl: url, name: self.inputReferrerName)
					self.inviteView = inviteView
					header.contextView = inviteView
					header.contextGroup.addSubview(header.contextView)
					
				}

				self.inviteView!.joinButton.hidden = true
				self.inviteView!.loginButton.hidden = true
				self.inviteView!.signupButton.hidden = true
				self.inviteView!.member.hidden = true

				if patch.userIsMember() {
					self.inviteView?.member.hidden = false
				}
				else if patch.userWatchStatusValue == .Pending {
					self.inviteView!.joinButton.hidden = false
					self.inviteView!.joinButton.setTitle("Requested".uppercaseString, forState: .Normal)
					self.inviteView!.joinButton.removeTarget(nil, action: nil, forControlEvents: .TouchUpInside)
					self.inviteView!.joinButton.addTarget(self, action: Selector("cancelRequestAction:"), forControlEvents: .TouchUpInside)
				}
				else {
					if UserController.instance.authenticated {
						self.inviteView!.joinButton.hidden = false
						self.inviteView!.joinButton.setTitle("Join".uppercaseString, forState: .Normal)
						self.inviteView!.joinButton.removeTarget(nil, action: nil, forControlEvents: .TouchUpInside)
						self.inviteView!.joinButton.addTarget(self, action: Selector("joinAction:"), forControlEvents: .TouchUpInside)
					}
					else {
						self.inviteView!.loginButton.hidden = false
						self.inviteView!.signupButton.hidden = false
						self.inviteView!.loginButton.addTarget(self, action: Selector("loginAction:"), forControlEvents: .TouchUpInside)
						self.inviteView!.signupButton.addTarget(self, action: Selector("signupAction:"), forControlEvents: .TouchUpInside)
					}
				}

				self.inviteView!.setNeedsLayout()
				self.inviteView!.layoutIfNeeded()
				header.setNeedsLayout()
				return
			}
			
			if !(header.contextView is UIButton) {
				header.contextView.removeFromSuperview()
				header.contextView = AirFeaturedButton()
				header.contextGroup.addSubview(header.contextView)
				self.inviteView = nil
			}
			
			if let button = header.contextView as? UIButton {
				if isUserOwner() {
					if patch.countPendingValue > 0 {
						if patch.countPendingValue == 1 {
							button.setTitle("One member request".uppercaseString, forState: .Normal)
						}
						else {
							button.setTitle("\(patch.countPendingValue) member requests".uppercaseString, forState: .Normal)
						}
						self.contextAction = .BrowseUsersWatching
					}
					else if patch.userWatchStatusValue == .NonMember {
						button.setTitle("Join".uppercaseString, forState: .Normal)
						self.contextAction = .SubmitJoinRequest
					}
					else {
						button.setTitle("Invite friends to this patch".uppercaseString, forState: .Normal)
						self.contextAction = .SharePatch
					}
				}
				else {
					if !UserController.instance.authenticated {
						if patch.visibility == "public" {
							button.setTitle("Invite friends to this patch".uppercaseString, forState: .Normal)
							self.contextAction = .SharePatch
						}
						else {
							button.setTitle("Join".uppercaseString, forState: .Normal)
							self.contextAction = .SubmitJoinRequest
						}
					}
					else {
						if patch.visibility == "public" {
							if patch.userWatchStatusValue == .Member {
								if patch.userHasMessagedValue {
									button.setTitle("Invite friends to this patch".uppercaseString, forState: .Normal)
									self.contextAction = .SharePatch
								}
								else {
									button.setTitle("Post your first message".uppercaseString, forState: .Normal)
									self.contextAction = .CreateMessage
								}
							}
							else {
								button.setTitle("Join".uppercaseString, forState: .Normal)
								self.contextAction = .JoinPatch
							}
						}
						else {
							if patch.userWatchStatusValue == .Member {
								if patch.userHasMessagedValue {
									button.setTitle("Invite friends to this patch".uppercaseString, forState: .Normal)
									self.contextAction = .SharePatch
								}
								else {
									button.setTitle("Post your first message".uppercaseString, forState: .Normal)
									self.contextAction = .CreateMessage
								}
							}
							else if patch.userWatchStatusValue == .Pending {
								button.setTitle("Requested".uppercaseString, forState: .Normal)
								self.contextAction = .CancelJoinRequest
							}
							else if patch.userWatchStatusValue == .NonMember {
								button.setTitle("Join".uppercaseString, forState: .Normal)
								self.contextAction = .SubmitJoinRequest
							}
							
							if patch.userWatchJustApprovedValue {
								if patch.userHasMessagedValue {
									button.setTitle("Approved! Invite your friends".uppercaseString, forState: .Normal)
									self.contextAction = .SharePatch
								}
								else {
									button.setTitle("Approved! Post your first message".uppercaseString, forState: .Normal)
									self.contextAction = .CreateMessage
								}
							}
						}
					}
				}
			}
			
		}
	}
	
	func shareUsing(route: ShareRoute) {
		
		if route == .Patchr {
			
			let controller = MessageEditViewController()
			let navController = UINavigationController()
			controller.inputShareEntity = self.entity
			controller.inputShareSchema = Schema.ENTITY_PATCH
			controller.inputShareId = self.entityId!
			controller.inputMessageType = .Share
			controller.inputState = .Sharing
			navController.viewControllers = [controller]
			self.presentViewController(navController, animated: true, completion: nil)
		}
		else if route == .Facebook {
			
			let provider = FacebookProvider()
			provider.invite(self.entity!)
		}
		else if route == .AirDrop {
			
			BranchProvider.invite(self.entity as! Patch, referrer: UserController.instance.currentUser) {
				response, error in
				
				if let error = ServerError(error) {
					UIViewController.topMostViewController()!.handleError(error)
				}
				else {
					let patch = response as! PatchItem
					let excluded = [
						UIActivityTypePostToTwitter,
						UIActivityTypePostToFacebook,
						UIActivityTypePostToWeibo,
						UIActivityTypeMessage,
						UIActivityTypeMail,
						UIActivityTypePrint,
						UIActivityTypeCopyToPasteboard,
						UIActivityTypeAssignToContact,
						UIActivityTypeSaveToCameraRoll,
						UIActivityTypeAddToReadingList,
						UIActivityTypePostToFlickr,
						UIActivityTypePostToVimeo,
						UIActivityTypePostToTencentWeibo
					]
					
					let activityViewController = UIActivityViewController(
						activityItems: [patch, NSURL.init(string: patch.shareUrl, relativeToURL: nil)!],
						applicationActivities: nil)
					
					activityViewController.excludedActivityTypes = excluded
					
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
		else if route == .Actions {
			
			BranchProvider.invite(self.entity as! Patch, referrer: UserController.instance.currentUser) {
				response, error in
				
				if let error = ServerError(error) {
					UIViewController.topMostViewController()!.handleError(error)
				}
				else {
					let patch = response as! PatchItem
					let excluded = [
						UIActivityTypeAirDrop
					]
					
					let activityViewController = UIActivityViewController(
						activityItems: [patch, NSURL.init(string: patch.shareUrl, relativeToURL: nil)!],
						applicationActivities: nil)
					
					activityViewController.excludedActivityTypes = excluded
					
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

	/*--------------------------------------------------------------------------------------------
	* Properties
	*--------------------------------------------------------------------------------------------*/
	
    func isUserOwner() -> Bool {
        if let currentUser = UserController.instance.currentUser, let entity = self.entity {
            return currentUser.id_ == entity.creator?.entityId
        }
        return false
    }
}

extension PatchDetailViewController: MapViewDelegate {
    
    func locationForMap() -> CLLocation? {
        if let location = self.entity?.location {
            return location.cllocation
        }
        return nil
    }
    
    func locationChangedTo(location: CLLocation) {  }
    
    func locationEditable() -> Bool {
        return false
    }
    
    var locationTitle: String? {
        get {
            return self.entity?.name
        }
    }
    
    var locationSubtitle: String? {
        get {
			if self.entity?.type != nil {
				return "\(self.entity!.type!.uppercaseString) PATCH"
			}
			return "PATCH"
        }
    }
    
    var locationPhoto: AnyObject? {
        get {
            return self.entity?.photo
        }
    }
}

extension PatchDetailViewController {
	
	override func bindCellToEntity(cell: WrapperTableViewCell, entity: AnyObject, location: CLLocation?) {
		super.bindCellToEntity(cell, entity: entity, location: location)
		cell.hidden = self.disableCells
	}
}

extension PatchDetailViewController {
    /*
     * UITableViewDelegate
     */
    override func scrollViewDidScroll(scrollView: UIScrollView) {
		
		guard self.entity != nil else {
			return
		}
		
		let header = self.header as! PatchDetailView
		
		/* Parallax effect when user scrolls down */
		let offset = scrollView.contentOffset.y
		if offset >= originalScrollTop && offset <= 300 {
			let movement = originalScrollTop - scrollView.contentOffset.y
			let ratio: CGFloat = (movement <= 0) ? 0.50 : 1.0
			header.photo.frame.origin.y = self.originalRect!.origin.y + (-(movement) * ratio)
		}
		else {
			let movement = (originalScrollTop - scrollView.contentOffset.y) * 0.35
			if movement > 0 {
				header.photo.frame.origin.y = self.originalRect!.origin.y - (movement * 0.5)
				header.photo.frame.origin.x = self.originalRect!.origin.x - (movement * 0.5)
				header.photo.frame.size.width = self.originalRect!.size.width + movement
				header.photo.frame.size.height = self.originalRect!.size.height + movement
			}
		}
    }
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return super.tableView(tableView, numberOfRowsInSection: section)
	}
}

extension PatchDetailViewController: MFMailComposeViewControllerDelegate {
	
	func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
		
		switch result.rawValue {
		case MFMailComposeResultCancelled.rawValue:	// 0
			UIShared.Toast("Report cancelled", controller: self, addToWindow: false)
		case MFMailComposeResultSaved.rawValue:		// 1
			UIShared.Toast("Report saved", controller: self, addToWindow: false)
		case MFMailComposeResultSent.rawValue:		// 2
			UIShared.Toast("Report sent", controller: self, addToWindow: false)
		case MFMailComposeResultFailed.rawValue:	// 3
			UIShared.Toast("Report send failure: \(error!.localizedDescription)", controller: self, addToWindow: false)
		default:
			break
		}
		
		self.dismissViewControllerAnimated(true) {
			MailComposer = nil
			MailComposer = MFMailComposeViewController()
		}
	}
}

let UIActivityTypeGmail = "com.google.Gmail.ShareExtension"
let UIActivityTypeOutlook = "com.microsoft.Office.Outlook.compose-shareextension"
let UIActivityTypePatchr = "com.3meters.patchr.ios.PatchrShare"

class PatchItem: NSObject, UIActivityItemSource {
	
    var entity: Patch
    var shareUrl: String
    
    init(entity: Patch, shareUrl: String) {
        self.entity = entity
        self.shareUrl = shareUrl
    }
    
    func activityViewControllerPlaceholderItem(activityViewController: UIActivityViewController) -> AnyObject {
		/* Called before the share actions are displayed */
        return ""
    }
	
	func activityViewController(activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: String?, suggestedSize size: CGSize) -> UIImage? {
		/* Not currently called by any of the share extensions I could test. */
		return nil
	}
	
    func activityViewController(activityViewController: UIActivityViewController, itemForActivityType activityType: String) -> AnyObject? {
		let text = "\(UserController.instance.currentUser.name) has invited you to the \(self.entity.name) patch!"
		return text
    }
    
    func activityViewController(activityViewController: UIActivityViewController, subjectForActivityType activityType: String?) -> String {
		/*
		 * Outlook: Doesn't call this.
		 * Gmail constructs their own using the value from itemForActivityType
		 * Apple email calls this.
		 * Apple message calls this (I believe as an alternative if nothing provided via itemForActivityType).
		 */
        if activityType == UIActivityTypeMail
			|| activityType == UIActivityTypeOutlook
			|| activityType == UIActivityTypeGmail {
            return "Invitation to the \(self.entity.name) patch"
        }
        return ""
    }
}

private enum ShareButtonFunction {
    case Share
	case ShareFacebook
    case ShareVia
}

private enum ActionButtonFunction {
	case Leave
	case Report
}

enum ShareRoute {
	case Patchr
	case Facebook
	case AirDrop
	case Actions
}

enum ContextAction: UInt {
	case BrowseUsersWatching
	case SharePatch
	case CreateMessage
	case JoinPatch
	case SubmitJoinRequest
	case CancelJoinRequest
}