//
//  PatchDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class PatchDetailViewController: BaseDetailViewController, InviteWelcomeProtocol {

    private var contextAction: ContextAction = .SharePatch
    private var shareButtonFunctionMap = [Int: ShareButtonFunction]()
    private var originalTop: CGFloat = 0.0
    private var originalScrollTop: CGFloat = -64.0
	
	var inputShowInviteWelcome = false
	var inputInviterName: String?
	var inviteController: WelcomeViewController?

	/* Outlets are initialized before viewDidLoad is called */

    @IBOutlet weak var patchPhoto:     AirImageView!
    @IBOutlet weak var patchName:      UILabel!
    @IBOutlet weak var patchType:      UILabel!
    @IBOutlet weak var visibility:     UILabel!
    @IBOutlet weak var likeButton:     AirLikeButton!
    @IBOutlet weak var muteButton:     AirMuteButton!
    @IBOutlet weak var watchButton:    AirWatchButton!
    @IBOutlet weak var mapButton:      AirToolButton!
    @IBOutlet weak var watchersButton: AirButtonLink!
    @IBOutlet weak var contextButton:  UIButton!
    @IBOutlet weak var lockImage:      UIImageView!
	@IBOutlet weak var toolbar:		   UIVisualEffectView!
	
    @IBOutlet weak var headerSection:  UIView!
    @IBOutlet weak var bannerGroup:    UIView!
    @IBOutlet weak var titlingGroup:   UIView!
    @IBOutlet weak var buttonGroup:    UIView!
    
    @IBOutlet weak var infoGroup:      UIView!
    @IBOutlet weak var infoName:       UILabel!
    @IBOutlet weak var infoType:       UILabel!
    @IBOutlet weak var infoLockImage:  UIImageView!
    @IBOutlet weak var infoVisibility: UILabel!
    @IBOutlet weak var infoDistance:   UILabel!
    @IBOutlet weak var infoDescription:UILabel!
    @IBOutlet weak var infoOwner:      UILabel!
    
    @IBOutlet weak var patchPhotoTop:  NSLayoutConstraint!
    @IBOutlet weak var placeButton:    UIButton!

	/*--------------------------------------------------------------------------------------------
	 * Lifecycle
	 *--------------------------------------------------------------------------------------------*/

	override func awakeFromNib() {
		super.awakeFromNib()
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleRemoteNotification:",
            name: PAApplicationDidReceiveRemoteNotification, object: nil)
	}

	override func viewDidLoad() {
        self.queryName = DataStoreQueryName.MessagesForPatch.rawValue
        
		super.viewDidLoad()
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "bindingComplete:", name: Events.BindingComplete, object: nil)

        let bannerTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "flipToInfo:")
        self.bannerGroup.addGestureRecognizer(bannerTapGestureRecognizer)
        let infoTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "flipToBanner:")
        self.infoGroup.addGestureRecognizer(infoTapGestureRecognizer)
        
		/* Apply gradient to banner */
		let gradient: CAGradientLayer = CAGradientLayer()
		let width = UIScreen.mainScreen().bounds.size.width + 72
		let height = width * 0.35
		let offsetY = height * 0.75
		
		gradient.frame = CGRectMake(0, offsetY, width, height)
		
		let topColor:   UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.0))		// Top
		let stop2Color:   UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.33))	// Middle
		let bottomColor: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.66))		// Bottom
		gradient.colors = [topColor.CGColor, stop2Color.CGColor, bottomColor.CGColor]
		gradient.locations = [0.0, 0.5, 1.0]
		
		/* Travels from top to bottom */
		gradient.startPoint = CGPoint(x: 0.5, y: 0.0)	// (0,0) upper left corner, (1,1) lower right corner
		gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
		self.patchPhoto.layer.insertSublayer(gradient, atIndex: 0)
		
        /* UI prep */
        self.patchNameVisible = false
        self.lockImage.tintColor(Theme.colorTint)
        self.infoLockImage.tintColor(Theme.colorTint)
        self.originalTop = patchPhotoTop.constant
        self.contextButton?.setTitle("", forState: .Normal)
		
		self.mapButton.setImage(UIImage(named: "imgMapLight")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate), forState: .Normal)
		
		self.watchersButton.alpha = 0.0
		
        self.watchButton.tintOff = Theme.colorActionOff
		self.watchButton.tintOn = Theme.colorActionOn
        self.watchButton.tintPending = Theme.colorActionOn
        self.watchButton.setProgressStyle(UIActivityIndicatorViewStyle.White)
		
        self.muteButton.tintOff = Theme.colorActionOff
		self.muteButton.tintOn = Theme.colorActionOn
        self.muteButton.setProgressStyle(UIActivityIndicatorViewStyle.White)
        self.muteButton.imageOn = UIImage(named: "imgSoundOn2Light")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        self.muteButton.imageOff = UIImage(named: "imgSoundOff2Light")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        self.muteButton.messageOn = "Notifications active"
        self.muteButton.messageOff = "Notifications muted"
        self.muteButton.alpha = 0.0
        
        /* Navigation bar buttons */
        drawButtons()
	}
    
    override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		setScreenName("PatchDetail")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "watchDidChange:", name: Events.WatchDidChange, object: nil)
    }

    override func viewDidAppear(animated: Bool){
		super.viewDidAppear(animated)	// Triggers loading of list items
		
        /* Super hack to resize the table header to fit the contents */
        let headerView: UIView = self.tableView.tableHeaderView!
        var newFrame: CGRect = self.tableView.tableHeaderView!.frame;
        newFrame.size.height = contextButton.frame.height + bannerGroup.frame.height
        headerView.frame = newFrame
        self.tableView.tableHeaderView = headerView

        /* Load the freshest version of the entity */
        bind(true)
    }

    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: Events.WatchDidChange, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/
    
	@IBAction func watchersAction(sender: AnyObject) {
		let controller = UserTableViewController()
		controller.patch = self.entity as! Patch
		controller.filter = .PatchWatchers
		self.navigationController?.pushViewController(controller, animated: true)
	}

	@IBAction func contextButtonAction(sender: UIButton) {
        
        if contextAction == .CreateMessage {
            if !UserController.instance.authenticated {
				UserController.instance.showGuestGuard(nil, message: "Sign up for a free account to post messages and more.")
                return
            }
            addAction()
        }
        else if contextAction == .SharePatch {
            shareAction()
        }
        else if contextAction == .CancelJoinRequest {
            self.watchButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
        }
        else if contextAction == .SubmitJoinRequest {
            if !UserController.instance.authenticated {
				UserController.instance.showGuestGuard(nil, message: "Sign up for a free account to join patches and more.")
                return
            }
            self.watchButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
        }
        else if contextAction == .BrowseUsersWatching {
            watchersAction(self)
        }
	}

    @IBAction func mapAction(sender: AnyObject) {
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        if let controller = storyboard.instantiateViewControllerWithIdentifier("PatchMapViewController") as? PatchMapViewController {
            controller.locationDelegate = self
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
	
	func bindingComplete(notification: NSNotification) {
		if notification.userInfo == nil {
			if self.inputShowInviteWelcome {
				if let entity = self.entity as? Patch where entity.userWatchStatusValue == .NonMember {
					self.inputShowInviteWelcome = false
					if self.inputInviterName != nil {
						showInviteWelcome(nil, message: "\(self.inputInviterName!) invited you to join this patch.")
					}
					else {
						showInviteWelcome(nil, message: "A friend invited you to join this patch.")
					}
				}
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
                self.refreshControl?.beginRefreshing()
                self.pullToRefreshAction(self.refreshControl)
            }
        }
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
	
    func flipToInfo(sender: AnyObject) {
        UIView.transitionFromView(bannerGroup!, toView: infoGroup, duration: 0.4, options: [.TransitionFlipFromBottom, .ShowHideTransitionViews, .CurveEaseOut], completion: nil);
    }
    
    func flipToBanner(sender: AnyObject) {
        UIView.transitionFromView(infoGroup!, toView: bannerGroup, duration: 0.4, options: [.TransitionFlipFromTop, .ShowHideTransitionViews, .CurveEaseOut], completion: nil);
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
	
    func likeDidChange(sender: NSNotification) {
        self.draw()
        self.tableView.reloadData()
    }
    
    func watchDidChange(sender: NSNotification) {
        self.draw()
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
    
	override func draw() {
        
        if let entity = self.entity as? Patch {
            
            /* Name, type and photo */
            
            self.patchName.text = entity.name
            self.patchType.text = entity.type == nil ? "PATCH" : entity.type.uppercaseString + " PATCH"
			self.patchPhoto.setImageWithPhoto(entity.getPhotoManaged(), animate: false)
            
            /* Privacy */
            
            if self.lockImage != nil {
                self.lockImage.hidden = (entity.visibility == "public")
                self.infoLockImage.hidden = (entity.visibility == "public")
            }
            if self.visibility != nil {
                self.visibility.hidden = (entity.visibility == "public")
                self.infoVisibility.hidden = (entity.visibility == "public")
            }
            
            /* Map button */
            self.mapButton.hidden = (entity.location == nil)
            
            /* Watching button */
            
            if entity.countWatchingValue == 0 {
                if self.watchersButton.alpha != 0 {
                    self.watchersButton.fadeOut()
                }
            }
            else {
                let watchersTitle = "\(self.entity!.countWatching ?? 0) watching"
                self.watchersButton.setTitle(watchersTitle, forState: UIControlState.Normal)
                if self.watchersButton.alpha == 0 {
                    self.watchersButton.fadeIn()
                }
            }
            
            /* Like button */
            
            self.likeButton.bindEntity(self.entity)
            if (entity.visibility == "public" || entity.userWatchStatusValue == .Member || isOwner()) {
                self.likeButton.fadeIn(alpha: 1.0)
            }
            else {
                self.likeButton.fadeOut(alpha: 0.0)
            }
            
            /* Watch button */
            
            self.watchButton.bindEntity(self.entity)
            
            /* Mute button */
            
            self.muteButton.bindEntity(self.entity)
            if (entity.userWatchStatusValue == .Member) {
                self.muteButton.fadeIn(alpha: 1.0)
            }
            else {
                self.muteButton.fadeOut(alpha: 0.0)
            }
            
            /* Info view */
            self.infoName.text = entity.name
            if entity.type != nil {
                self.infoType.text = entity.type.uppercaseString + " PATCH"
            }
            self.infoDescription.text = entity.description_
            if let distance = entity.distanceFrom(nil) {
                self.infoDistance.text = LocationController.instance.distancePretty(distance)
            }
            self.infoOwner.text = entity.creator?.name ?? "Deleted"
            
            if isOwner() {
                if entity.countPendingValue > 0 {
                    if entity.countPendingValue == 1 {
                        self.contextButton.setTitle("One member request".uppercaseString, forState: .Normal)
                    }
                    else {
                        self.contextButton.setTitle("\(entity.countPendingValue) member requests".uppercaseString, forState: .Normal)
                    }
                    contextAction = .BrowseUsersWatching
                }
                else {
                    self.contextButton.setTitle("Invite friends to this patch".uppercaseString, forState: .Normal)
                    contextAction = .SharePatch
                }
            }
            else {
                if !UserController.instance.authenticated {
                    if entity.visibility == "public" {
                        self.contextButton.setTitle("Invite friends to this patch".uppercaseString, forState: .Normal)
                        contextAction = .SharePatch
                    }
                    else {
                        self.contextButton.setTitle("Request to join".uppercaseString, forState: .Normal)
                        contextAction = .SubmitJoinRequest
                    }
                }
                else {
                    if entity.visibility == "public" {
                        if entity.userHasMessagedValue {
                            self.contextButton.setTitle("Invite friends to this patch".uppercaseString, forState: .Normal)
                            contextAction = .SharePatch
                        }
                        else {
                            self.contextButton.setTitle("Post your first message".uppercaseString, forState: .Normal)
                            contextAction = .CreateMessage
                        }
                    }
                    else {
                        if entity.userWatchStatusValue == .Member {
                            if entity.userHasMessagedValue {
                                self.contextButton.setTitle("Invite friends to this patch".uppercaseString, forState: .Normal)
                                contextAction = .SharePatch
                            }
                            else {
                                self.contextButton.setTitle("Post your first message".uppercaseString, forState: .Normal)
                                contextAction = .CreateMessage
                            }
                        }
                        else if entity.userWatchStatusValue == .Pending {
                            self.contextButton.setTitle("Cancel join request".uppercaseString, forState: .Normal)
                            contextAction = .CancelJoinRequest
                        }
                        else if entity.userWatchStatusValue == .NonMember {
                            self.contextButton.setTitle("Request to join".uppercaseString, forState: .Normal)
                            contextAction = .SubmitJoinRequest
                        }
                        
                        if entity.userWatchJustApprovedValue {
                            if entity.userHasMessagedValue {
                                self.contextButton.setTitle("Approved! Invite your friends".uppercaseString, forState: .Normal)
                                contextAction = .SharePatch
                            }
                            else {
                                self.contextButton.setTitle("Approved! Post your first message".uppercaseString, forState: .Normal)
                                contextAction = .CreateMessage
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
			if FBSDKAccessToken.currentAccessToken() == nil {
				provider.authorize { response, error in
					if FBSDKAccessToken.currentAccessToken() != nil {
						provider.invite(self.entity!)
					}
				}
			}
			else {
				provider.invite(self.entity!)
			}
		}
		else if route == .Actions {
			
			let inviterName = UserController.instance.currentUser.id_
			Branch.getInstance().getShortURLWithParams(["entityId":self.entityId!, "entitySchema":"patch", "inviterName":inviterName],
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
					self.watchButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
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
    /*
     * UITableViewDelegate
     */
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        if patchPhotoTop != nil {
            /* Parallax effect when user scrolls down */
            let offset = scrollView.contentOffset.y
            if offset >= originalScrollTop && offset <= 300 {
                let movement = originalScrollTop - scrollView.contentOffset.y
                let ratio: CGFloat = (movement <= 0) ? 0.50 : 1.0
                patchPhotoTop.constant = originalTop + (-(movement) * ratio)
            }
            else {
                patchPhotoTop.constant = originalTop
            }
        }
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

class PatchItem: NSObject, UIActivityItemSource {
    
    var entity: Patch
    var shareUrl: String
    
    init(entity: Patch, shareUrl: String) {
        self.entity = entity
        self.shareUrl = shareUrl
    }
    
    func activityViewControllerPlaceholderItem(activityViewController: UIActivityViewController) -> AnyObject {
        return ""
    }
    
    func activityViewController(activityViewController: UIActivityViewController, itemForActivityType activityType: String) -> AnyObject? {
        let text = "\(UserController.instance.currentUser.name) has invited you to the \(self.entity.name) patch! \(self.shareUrl) \n"
        if activityType == UIActivityTypeMail {
            return text
        }
        else {
            return text
        }
    }
    
    func activityViewController(activityViewController: UIActivityViewController, subjectForActivityType activityType: String?) -> String {
        if activityType == UIActivityTypeMail || activityType == "com.google.Gmail.ShareExtension" {
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
	case SubmitJoinRequest
	case CancelJoinRequest
}