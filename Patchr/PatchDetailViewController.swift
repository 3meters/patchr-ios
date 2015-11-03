//
//  PatchDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class PatchDetailViewController: BaseDetailViewController {

    private var contextAction: ContextAction = .SharePatch
    private var shareButtonFunctionMap = [Int: ShareButtonFunction]()
    private var originalTop: CGFloat = 0.0
    private var originalScrollTop: CGFloat = -64.0

	/* Outlets are initialized before viewDidLoad is called */

    @IBOutlet weak var patchPhoto:     AirImageView!
    @IBOutlet weak var patchName:      UILabel!
    @IBOutlet weak var patchType:      UILabel!
    @IBOutlet weak var visibility:     UILabel!
    @IBOutlet weak var likeButton:     AirLikeButton!
    @IBOutlet weak var muteButton:     AirMuteButton!
    @IBOutlet weak var watchButton:    AirWatchButton!
    @IBOutlet weak var mapButton:      AirImageButton!
    @IBOutlet weak var watchersButton: UIButton!
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

        let bannerTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "flipToInfo:")
        self.bannerGroup.addGestureRecognizer(bannerTapGestureRecognizer)
        let infoTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "flipToBanner:")
        self.infoGroup.addGestureRecognizer(infoTapGestureRecognizer)
        
		/* Apply gradient to banner */
		let gradient: CAGradientLayer = CAGradientLayer()
		gradient.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width + 100, ((UIScreen.mainScreen().bounds.size.width - 24) * 0.75) + 50)
		
		let startColor:   UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.0))  // Top
		let endColor: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.5))		// Bottom
		gradient.colors = [startColor.CGColor, endColor.CGColor]
		
		/* Travels from top to bottom */
		gradient.startPoint = CGPoint(x: 0.5, y: 0.25)	// (0,0) upper left corner, (1,1) lower right corner
		gradient.endPoint = CGPoint(x: 0.5, y: 1)
		self.patchPhoto.layer.insertSublayer(gradient, atIndex: 0)
		
		let more = UITableViewCell()
		more.frame = placeButton.bounds
		more.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
		more.userInteractionEnabled = false
		self.placeButton.addSubview(more)
		
        /* UI prep */
        self.patchNameVisible = false
        self.lockImage.tintColor(Colors.brandColor)
        self.infoLockImage.tintColor(Colors.brandColor)
        self.originalTop = patchPhotoTop.constant
        self.contextButton?.setTitle("", forState: .Normal)
		
		self.mapButton.imageView!.tintColor(Colors.actionOnColor)
		self.mapButton.tintColor = Colors.actionOffColor
		self.mapButton.setImage(UIImage(named: "imgMapLight")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate), forState: .Normal)
		
		self.watchersButton.alpha = 0.0
        self.watchButton.tintOff = Colors.actionOffColor
		self.watchButton.tintOn = Colors.actionOnColor
        self.watchButton.tintPending = Colors.brandColor
        self.watchButton.setProgressStyle(UIActivityIndicatorViewStyle.White)
        
        self.likeButton.tintOff = Colors.actionOffColor
		self.likeButton.tintOn = Colors.actionOnColor
        self.likeButton.setProgressStyle(UIActivityIndicatorViewStyle.White)
        self.likeButton.imageOn = UIImage(named: "imgStarFilledLight")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        self.likeButton.imageOff = UIImage(named: "imgStarLight")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        self.likeButton.messageOn = "Added to favorites"
        self.likeButton.messageOff = "Removed from favorites"
        self.likeButton.alpha = 0.0
        
        self.muteButton.tintOff = Colors.actionOffColor
		self.muteButton.tintOn = Colors.actionOnColor
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
        /*
         * Entity could have been deleted while we were away so check it.
         */
        if self.entity != nil {
            let item = ServiceBase.fetchOneById(self.entityId!, inManagedObjectContext: DataController.instance.mainContext)
            if item == nil {
                self.navigationController?.popViewControllerAnimated(false)
                return
            }
        }
		
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRowAtIndexPath(indexPath, animated: animated)
		}
        
        /* Triggers query processing by results controller */
		if !self.query().executedValue && self._query != nil {
			self.bindQueryItems(false)
		}
		
		/* Draw what we have, we look for something fresher when the view appears. */
        if self.entity != nil {
            draw()
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "likeDidChange:", name: Events.LikeDidChange, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "watchDidChange:", name: Events.WatchDidChange, object: nil)
        setScreenName("PatchDetail")
    }

    override func viewDidAppear(animated: Bool){
		super.viewDidAppear(animated)	// Triggers loading of list items
		
        /* Super hack to resize the table header to fit the contents */
        let headerView: UIView = self.tableView.tableHeaderView!
        let height = contextButton.frame.height + bannerGroup.frame.height
        var newFrame: CGRect = self.tableView.tableHeaderView!.frame;
        
        newFrame.size.height = height
        headerView.frame = newFrame
        self.tableView.tableHeaderView = headerView

        /* Load the freshest version of the entity */
        bind(true)
    }

    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: Events.LikeDidChange, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: Events.WatchDidChange, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/
    
	@IBAction func watchersAction(sender: AnyObject) {
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        if let controller = storyboard.instantiateViewControllerWithIdentifier("UserTableViewController") as? UserTableViewController {
            controller.patch = self.entity as! Patch
            controller.filter = .PatchWatchers
            self.navigationController?.pushViewController(controller, animated: true)
        }
	}

	@IBAction func contextButtonAction(sender: UIButton) {
        
        if contextAction == .CreateMessage {
            if !UserController.instance.authenticated {
                Shared.Toast("Sign in to post messages")
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
                Shared.Toast("Sign in to join patches")
                return
            }
            self.watchButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
        }
        else if contextAction == .BrowseUsersWatching {
            watchersAction(self)
        }
	}

    @IBAction func placeAction(sender: AnyObject) {
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        if let controller = storyboard.instantiateViewControllerWithIdentifier("PlaceDetailViewController") as? PlaceDetailViewController {
            controller.placeId = (self.entity as! Patch).place.entityId
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    @IBAction func mapAction(sender: AnyObject) {
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        if let controller = storyboard.instantiateViewControllerWithIdentifier("PatchMapViewController") as? PatchMapViewController {
            controller.locationDelegate = self
            self.navigationController?.pushViewController(controller, animated: true)
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
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func flipToInfo(sender: AnyObject) {
        UIView.transitionFromView(bannerGroup!, toView: infoGroup, duration: 0.4, options: [.TransitionFlipFromBottom, .ShowHideTransitionViews, .CurveEaseOut], completion: nil);
    }
    
    func flipToBanner(sender: AnyObject) {
        UIView.transitionFromView(infoGroup!, toView: bannerGroup, duration: 0.4, options: [.TransitionFlipFromTop, .ShowHideTransitionViews, .CurveEaseOut], completion: nil);
    }
    
    func addAction() {
        if !UserController.instance.authenticated {
            Shared.Toast("Sign in to post messages")
            return
        }
        /* Has its own nav because we segue modally and it needs its own stack */
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        if let controller = storyboard.instantiateViewControllerWithIdentifier("MessageEditViewController") as? MessageEditViewController {
            controller.toString = self.entity!.name
            controller.patchId = self.entityId
            let navController = UINavigationController()
            navController.navigationBar.tintColor = Colors.brandColorDark
            navController.viewControllers = [controller]
            self.navigationController?.presentViewController(navController, animated: true, completion: nil)
        }
    }
    
    func editAction() {
        /* Has its own nav because we segue modally and it needs its own stack */
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        if let controller = storyboard.instantiateViewControllerWithIdentifier("PatchEditViewController") as? PatchEditViewController {
            controller.entity = entity
            let navController = UINavigationController()
            navController.navigationBar.tintColor = Colors.brandColorDark
            navController.viewControllers = [controller]
            self.navigationController?.presentViewController(navController, animated: true, completion: nil)
        }
    }
    
    func shareAction() {
        
        if self.entity != nil {
            
            let sheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: nil)
            
            shareButtonFunctionMap[sheet.addButtonWithTitle("Invite")] = .Share
            shareButtonFunctionMap[sheet.addButtonWithTitle("Invite via")] = .ShareVia
            sheet.addButtonWithTitle("Cancel")
            sheet.cancelButtonIndex = sheet.numberOfButtons - 1
            
            sheet.showInView(self.view)
        }
    }
    
    func likeDidChange(sender: NSNotification) {
        self.draw()
        self.tableView.reloadData()
    }
    
    func watchDidChange(sender: NSNotification) {
        self.draw()
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
            
            /* Place */
            
            if entity.place != nil {
                placeButton.setTitle(entity.place.name, forState: .Normal)
                placeButton.fadeIn()
            }
            
            /* Privacy */
            
            if lockImage != nil {
                lockImage.hidden = (entity.visibility == "public")
                infoLockImage.hidden = (entity.visibility == "public")
            }
            if visibility != nil {
                visibility.hidden = (entity.visibility == "public")
                infoVisibility.hidden = (entity.visibility == "public")
            }
            
            /* Map button */
            mapButton.hidden = (entity.location == nil)
            
            /* Watching button */
            
            if entity.countWatchingValue == 0 {
                if watchersButton.alpha != 0 {
                    watchersButton.fadeOut()
                }
            }
            else {
                let watchersTitle = "\(self.entity!.countWatching ?? 0) watching"
                self.watchersButton.setTitle(watchersTitle, forState: UIControlState.Normal)
                if watchersButton.alpha == 0 {
                    watchersButton.fadeIn()
                }
            }
            
            /* Like button */
            
            likeButton.bindEntity(self.entity)
            if (entity.visibility == "public" || entity.userWatchStatusValue == .Member || isOwner()) {
                likeButton.fadeIn(alpha: 1.0)
            }
            else {
                likeButton.fadeOut(alpha: 0.0)
            }
            
            /* Watch button */
            
            watchButton.bindEntity(self.entity)
            
            /* Mute button */
            
            muteButton.bindEntity(self.entity)
            if (entity.userWatchStatusValue == .Member) {
                muteButton.fadeIn(alpha: 1.0)
            }
            else {
                muteButton.fadeOut(alpha: 0.0)
            }
            
            /* Info view */
            infoName.text = entity.name
            if entity.type != nil {
                infoType.text = entity.type.uppercaseString + " PATCH"
            }
            infoDescription.text = entity.description_
            if let distance = entity.distanceFrom(nil) {
                infoDistance.text = LocationController.instance.distancePretty(distance)
            }
            infoOwner.text = entity.creator?.name ?? "Deleted"
            
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
        let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
        spacer.width = SPACER_WIDTH
        if isOwner() {
            let editImage = Utils.imageEdit
            let editButton = UIBarButtonItem(image: editImage, style: UIBarButtonItemStyle.Plain, target: self, action: Selector("editAction"))
            self.navigationItem.rightBarButtonItems = [addButton, spacer, shareButton, spacer, editButton]
        }
        else {
            self.navigationItem.rightBarButtonItems = [addButton, spacer, shareButton]
        }
    }
    
    func shareUsing(patchr: Bool = true) {
        
        if patchr {
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            let controller = storyboard.instantiateViewControllerWithIdentifier("MessageEditViewController") as? MessageEditViewController
            /* viewDidLoad hasn't fired yet but awakeFromNib has */
            controller?.shareEntity = self.entity
            controller?.shareSchema = Schema.ENTITY_PATCH
            controller?.shareId = self.entityId!
            controller?.messageType = .Share
			let navController = UINavigationController(rootViewController: controller!)
			navController.navigationBar.tintColor = Colors.brandColorDark
            self.presentViewController(navController, animated: true, completion: nil)
        }
        else {
            Branch.getInstance().getShortURLWithParams(["entityId":self.entityId!, "entitySchema":"patch"], andChannel: "patchr-ios", andFeature: BRANCH_FEATURE_TAG_INVITE, andCallback: {
                (url: String?, error: NSError?) -> Void in
                
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
}

extension PatchDetailViewController: MapViewDelegate {
    
    func locationForMap() -> CLLocation? {
        if let location = self.entity?.location {
            return CLLocation(latitude: location.latValue, longitude: location.lngValue)
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
			return (self.entity?.type ?? "place")
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
                    self.shareUsing(true)
                    
                case .ShareVia:
                    self.shareUsing(false)
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
    case ShareVia
}

enum ContextAction: UInt {
	case BrowseUsersWatching
	case SharePatch
	case CreateMessage
	case SubmitJoinRequest
	case CancelJoinRequest
}