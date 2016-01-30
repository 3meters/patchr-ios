//
//  PatchDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import Branch
import iRate

class PatchDetailViewController: BaseDetailViewController, InviteWelcomeProtocol {

    private var contextAction			: ContextAction = .SharePatch
    private var shareButtonFunctionMap	= [Int: ShareButtonFunction]()
	private var originalRect			: CGRect?
    private var originalScrollTop		= CGFloat(-64.0)
	
	var inputShowInviteWelcome	= false
	var inputInviterName		: String?
	var inviteController		: WelcomeViewController?
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
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.width())
		let viewHeight = (viewWidth * 0.625) + 48
		self.tableView.tableHeaderView?.bounds.size = CGSizeMake(viewWidth, viewHeight)	// Triggers layoutSubviews on header
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)		// calls bind
		fetch(reset: self.firstAppearance)
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		if self.autoWatchOnAppear {
			self.autoWatchOnAppear = false
			let header = self.header as! PatchDetailView
			header.watchButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
			Utils.delay(1.0) {
				UIShared.Toast("You are now watching this patch", controller: self, addToWindow: false)
			}
		}
		else {
			iRate.sharedInstance().promptIfAllCriteriaMet()
		}
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
            shareAction()
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
    
    func shareAction() {
        
        if self.entity != nil {
            
            let sheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: nil)
            
            shareButtonFunctionMap[sheet.addButtonWithTitle("Invite using Patchr")] = .Share
			shareButtonFunctionMap[sheet.addButtonWithTitle("Invite using Facebook")] = .ShareFacebook
            shareButtonFunctionMap[sheet.addButtonWithTitle("More")] = .ShareVia
            sheet.addButtonWithTitle("Cancel")
            sheet.cancelButtonIndex = sheet.numberOfButtons - 1
            
            sheet.showInView(self.view)
        }
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
	
	func didFetch(notification: NSNotification) {
		if notification.userInfo == nil {
			if self.inputShowInviteWelcome {
				if let entity = self.entity as? Patch where entity.userWatchStatusValue == .NonMember {
					self.inputShowInviteWelcome = false
					if self.inputInviterName != nil {
						showInviteWelcome(self, message: "\(self.inputInviterName!) invited you to join this patch.")
					}
					else {
						showInviteWelcome(self, message: "A friend invited you to join this patch.")
					}
				}
			}
		}
		/*
		 * HACK: We hide messages if the user is not a member of a private even if messages
		 * were returned by the service because they are owned by the current user.
		 */
		let showMessages = (self.entity!.visibility == "public" || self.entity!.userWatchStatusValue == .Member)
		if !showMessages {
			self.emptyLabel.fadeIn()
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
		bindContextButton()
	}
	
	func didInsertMessage(sender: NSNotification) {
		if let entity = self.entity as? Patch where !entity.userHasMessagedValue {
			self.autoWatchOnAppear = true
		}
	}
	
	func inviteFinishedWithInvitations(invitationIds: [AnyObject]!, error: NSError!) {
		if (error != nil) {
			print("Failed: " + error.localizedDescription)
		} else {
			print("Invitations sent")
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
		header.contextButton.addTarget(self, action: Selector("contextButtonAction:"), forControlEvents: .TouchUpInside)

		NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleRemoteNotification:", name: PAApplicationDidReceiveRemoteNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "didFetch:", name: Events.DidFetch, object: self)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "watchDidChange:", name: Events.WatchDidChange, object: header.watchButton)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "didInsertMessage:", name: Events.DidInsertMessage, object: nil)
		
		/* UI prep */
		self.patchNameVisible = false
		header.contextButton.setTitle("", forState: .Normal)
		
		self.showEmptyLabel = true
		self.showProgress = true
		self.progressOffsetY = 80
		self.loadMoreMessage = "LOAD MORE MESSAGES"
		
		/* Navigation bar buttons */
		drawButtons()
	}
	
	override func bind() {
        
        if let entity = self.entity as? Patch {
			let header = self.header as! PatchDetailView

			header.bindToEntity(entity)
			bindContextButton()

			self.emptyMessage = (entity.visibility == "private") ? "Only members can see messages" : "Be the first to post a message to this patch"
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

	func bindContextButton() {
		
		if let entity = self.entity as? Patch {
			
			let header = self.header as! PatchDetailView
			
			if isOwner() {
				if entity.countPendingValue > 0 {
					if entity.countPendingValue == 1 {
						header.contextButton.setTitle("One member request".uppercaseString, forState: .Normal)
					}
					else {
						header.contextButton.setTitle("\(entity.countPendingValue) member requests".uppercaseString, forState: .Normal)
					}
					self.contextAction = .BrowseUsersWatching
				}
				else {
					header.contextButton.setTitle("Invite friends to this patch".uppercaseString, forState: .Normal)
					self.contextAction = .SharePatch
				}
			}
			else {
				if !UserController.instance.authenticated {
					if entity.visibility == "public" {
						header.contextButton.setTitle("Invite friends to this patch".uppercaseString, forState: .Normal)
						self.contextAction = .SharePatch
					}
					else {
						header.contextButton.setTitle("Request to join".uppercaseString, forState: .Normal)
						self.contextAction = .SubmitJoinRequest
					}
				}
				else {
					if entity.visibility == "public" {
						if entity.userWatchStatusValue == .Member {
							if entity.userHasMessagedValue {
								header.contextButton.setTitle("Invite friends to this patch".uppercaseString, forState: .Normal)
								self.contextAction = .SharePatch
							}
							else {
								header.contextButton.setTitle("Post your first message".uppercaseString, forState: .Normal)
								self.contextAction = .CreateMessage
							}
						}
						else {
							header.contextButton.setTitle("Join this patch".uppercaseString, forState: .Normal)
							self.contextAction = .JoinPatch
						}
					}
					else {
						if entity.userWatchStatusValue == .Member {
							if entity.userHasMessagedValue {
								header.contextButton.setTitle("Invite friends to this patch".uppercaseString, forState: .Normal)
								self.contextAction = .SharePatch
							}
							else {
								header.contextButton.setTitle("Post your first message".uppercaseString, forState: .Normal)
								self.contextAction = .CreateMessage
							}
						}
						else if entity.userWatchStatusValue == .Pending {
							header.contextButton.setTitle("Cancel join request".uppercaseString, forState: .Normal)
							self.contextAction = .CancelJoinRequest
						}
						else if entity.userWatchStatusValue == .NonMember {
							header.contextButton.setTitle("Request to join".uppercaseString, forState: .Normal)
							self.contextAction = .SubmitJoinRequest
						}
						
						if entity.userWatchJustApprovedValue {
							if entity.userHasMessagedValue {
								header.contextButton.setTitle("Approved! Invite your friends".uppercaseString, forState: .Normal)
								self.contextAction = .SharePatch
							}
							else {
								header.contextButton.setTitle("Approved! Post your first message".uppercaseString, forState: .Normal)
								self.contextAction = .CreateMessage
							}
						}
					}
				}
			}
		}
	}
	
    override func drawButtons() {
        
        let shareButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: Selector("shareAction"))
        let addButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: Selector("addAction"))
		let editButton = UIBarButtonItem(image: Utils.imageEdit, style: UIBarButtonItemStyle.Plain, target: self, action: Selector("editAction"))
		
        if isOwner() {
            self.navigationItem.setRightBarButtonItems([addButton, Utils.spacer, shareButton, Utils.spacer, editButton], animated: true)
        }
        else {
			self.navigationItem.setRightBarButtonItems([addButton, Utils.spacer, shareButton], animated: true)
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
		else if route == .Actions {
			
			let inviterName = UserController.instance.currentUser.name!
			
			let photo = self.entity!.getPhotoManaged()
			let settings = "w=400&h=250&crop&fit=crop&q=50"
			let photoUrl = "https://3meters-images.imgix.net/\(photo.prefix)?\(settings)"
			let description = self.entity!.description_ ?? "Patches are a fast and fun way for casual groups to share events, places, interests and projects."
			
			let parameters = [
				"entityId":self.entityId!,
				"entitySchema":"patch",
				"inviterName":inviterName,
				"$og_image_url": photoUrl,
				"$og_title": "\(self.entity!.name) Patch",
				"$og_description": description
			]
			
			Branch.getInstance().getShortURLWithParams(parameters,
				andChannel: "patchr-ios",
				andFeature: BRANCH_FEATURE_TAG_INVITE,
				andCallback: { url, error in
				
				if let error = ServerError(error) {
					UIViewController.topMostViewController()!.handleError(error)
				}
				else {
					Log.d("Branch link created: \(url!)")
					let patch: PatchItem = PatchItem(entity: self.entity as! Patch, shareUrl: url!)
					
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

    func isOwner() -> Bool {
        if let currentUser = UserController.instance.currentUser, let entity = self.entity {
            return currentUser.id_ == entity.creator?.entityId
        }
        return false
    }
	
	func showInviteWelcome(var controller: UIViewController?, message: String?) {
		
		self.inviteController = WelcomeViewController()
		self.inviteController!.modalPresentationStyle = .OverFullScreen
		self.inviteController!.modalTransitionStyle = .CrossDissolve
		if controller == nil {
			controller = UIViewController.topMostViewController()!
		}
		self.inviteController!.inputMessage = message
		if let entity = self.entity as? Patch {
			self.inviteController!.inputPublic = (entity.visibility == "public")
		}
		self.inviteController!.delegate = self
		controller!.presentViewController(self.inviteController!, animated: true, completion: nil)
	}

	func inviteResult(result: InviteWelcomeResult) {
		Utils.delay(0.1) {
			self.dismissViewControllerAnimated(true) {
				if result == .Login {
					self.loginAction(nil)
				}
				else if result == .Signup {
					self.signupAction(nil)
				}
				else if result == .Join {
					let header = self.header as! PatchDetailView
					header.watchButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
				}
			}
		}
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
		let showMessages = (self.entity!.visibility == "public" || self.entity!.userWatchStatusValue == .Member)
		cell.hidden = !showMessages
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

extension PatchDetailViewController: UIActionSheetDelegate {
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex != actionSheet.cancelButtonIndex {
            // There are some strange visual artifacts with the share sheet and the presented
            // view controllers. Adding a small delay seems to prevent them.
            Utils.delay(0.4) {
				
                switch self.shareButtonFunctionMap[buttonIndex]! {
                case .Share:
                    self.shareUsing(.Patchr)
                    
				case .ShareFacebook:
					self.shareUsing(.Facebook)
					
                case .ShareVia:
                    self.shareUsing(.Actions)
                }
            }
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
        let text = "\(UserController.instance.currentUser.name) has invited you to the \(self.entity.name) patch! \(self.shareUrl) \n"
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

enum ShareRoute {
	case Patchr
	case Facebook
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