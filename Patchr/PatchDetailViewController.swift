//
//  PatchDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class PatchDetailViewController: QueryTableViewController {

	var patch: Patch! = nil
    var patchId: String?
    var deleted = false

	private let cellNibName = "MessageTableViewCell"
	private var selectedMessage:      Message?
	private var messageDateFormatter: NSDateFormatter!
	private var offscreenCells:       NSMutableDictionary = NSMutableDictionary()
    private var _query: Query!
    private var contextAction: ContextAction = .SharePatch
    
    private var isOwner: Bool {
        if let currentUser = UserController.instance.currentUser {
            if patch != nil && patch.creator != nil {
                return currentUser.id_ == patch.creator.entityId
            }
        }
        return false
    }
    
    private var originalTop: CGFloat = 0.0
    private var originalScrollTop: CGFloat = -64.0

	/* Outlets are initialized before viewDidLoad is called */

    @IBOutlet weak var patchPhoto:     AirImageView!
    @IBOutlet weak var patchName:      UILabel!
    @IBOutlet weak var patchType:      UILabel!
    @IBOutlet weak var visibility:     UILabel!
    @IBOutlet weak var likeButton:     AirLikeButton!
    @IBOutlet weak var watchButton:    AirWatchButton!
    @IBOutlet weak var mapButton:      AirImageButton!
    @IBOutlet weak var watchersButton: UIButton!
    @IBOutlet weak var contextButton:  UIButton!
    @IBOutlet weak var lockImage:      UIImageView!
    
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

	override func query() -> Query {
		if self._query == nil {
			let query = Query.insertInManagedObjectContext(DataController.instance.managedObjectContext) as! Query
			query.name = DataStoreQueryName.MessagesForPatch.rawValue
            query.pageSize = DataController.proxibase.pageSizeDefault
            query.validValue = (patch != nil || patchId != nil)
            if query.validValue {
                query.parameters = [:]
                if patch != nil {
                    query.parameters["entity"] = patch
                }
                if patchId != nil {
                    query.parameters["entityId"] = patchId
                }
            }
			DataController.instance.managedObjectContext.save(nil)
			self._query = query
		}
		return self._query
	}

	/*--------------------------------------------------------------------------------------------
	 * Lifecycle
	 *--------------------------------------------------------------------------------------------*/

	override func awakeFromNib() {
		super.awakeFromNib()
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleRemoteNotification:",
            name: PAApplicationDidReceiveRemoteNotification, object: nil)
	}

	override func viewDidLoad() {

		if patch != nil {
			patchId = patch.id_
		}
        
        super.showEmptyLabel = false

		super.viewDidLoad()

		tableView.registerNib(UINib(nibName: cellNibName, bundle: nil), forCellReuseIdentifier: CELL_IDENTIFIER)
        let bannerTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "flipToInfo:")
        self.bannerGroup.addGestureRecognizer(bannerTapGestureRecognizer)
        let infoTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "flipToBanner:")
        self.infoGroup.addGestureRecognizer(infoTapGestureRecognizer)

		let dateFormatter = NSDateFormatter()
		dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
		dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
		dateFormatter.doesRelativeDateFormatting = true
		messageDateFormatter = dateFormatter
        
		/* Apply gradient to banner */
		var gradient: CAGradientLayer = CAGradientLayer()
		gradient.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width + 100, ((UIScreen.mainScreen().bounds.size.width - 24) * 0.75) + 50)
		var startColor: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.5))  // Bottom
		var endColor:   UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0))    // Top
		gradient.colors = [endColor.CGColor, startColor.CGColor]
		gradient.startPoint = CGPoint(x: 0.5, y: 0.5)
		gradient.endPoint = CGPoint(x: 0.5, y: 1)
		patchPhoto.layer.insertSublayer(gradient, atIndex: 0)
        
        var more: UITableViewCell = UITableViewCell()
        placeButton.addSubview(more)
        more.frame = placeButton.bounds
        more.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        more.userInteractionEnabled = false
        
        /* UI prep */
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None;
        lockImage.tintColor(Colors.brandColor)
        infoLockImage.tintColor(Colors.brandColor)
        mapButton.imageView?.tintColor = UIColor.whiteColor()
        watchersButton.alpha = 0.0
        originalTop = patchPhotoTop.constant
        self.contextButton?.setTitle("", forState: .Normal)
        self.tableView.estimatedRowHeight = UITableViewAutomaticDimension
        
        watchButton.tintOff = UIColor.whiteColor()
        watchButton.tintPending = Colors.brandColor
        watchButton.setProgressStyle(UIActivityIndicatorViewStyle.White)
        
        likeButton.tintOff = UIColor.whiteColor()
        likeButton.setProgressStyle(UIActivityIndicatorViewStyle.White)
        likeButton.imageOn = UIImage(named: "imgStarFilledLight")
        likeButton.imageOff = UIImage(named: "imgStarLight")
        likeButton.messageOn = "Added to favorites"
        likeButton.messageOff = "Removed from favorites"
        likeButton.alpha = 0.0
        
        /* Navigation bar buttons */
        
        drawButtons()
	}
    
    override func viewWillAppear(animated: Bool) {
        /*
         * Entity could have been deleted while we were away to check it.
         */
        if self.patch != nil {
            let item = ServiceBase.fetchOneById(patchId, inManagedObjectContext: DataController.instance.managedObjectContext)
            if item == nil {
                self.navigationController?.popViewControllerAnimated(false)
                return
            }
        }
        
        /* Triggers query processing by results controller */
        super.viewWillAppear(animated)
        
        if self.patch != nil {
            draw()
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "likeDidChange:", name: Events.LikeDidChange, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "watchDidChange:", name: Events.WatchDidChange, object: nil)
    }

    override func viewDidAppear(animated: Bool){
        super.viewDidAppear(animated)
        
        /* Super hack to resize the table header to fit the contents */
        var headerView: UIView = self.tableView.tableHeaderView!
        var height = contextButton.frame.height + bannerGroup.frame.height
        var newFrame: CGRect = self.tableView.tableHeaderView!.frame;
        
        newFrame.size.height = height
        headerView.frame = newFrame
        self.tableView.tableHeaderView = headerView
        
        /* Load the entity */
        refresh(force: true)
    }

    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: Events.LikeDidChange, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: Events.WatchDidChange, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

	private func refresh(force: Bool = false) {
		/* Refreshes the top object but not the message list */
		DataController.instance.withPatchId(patchId!, refresh: force) {
			patch in
            
			self.refreshControl?.endRefreshing()
			if patch != nil {
                if self.patch == nil {
                    self.refreshQueryItems(force: true)
                }
				self.patch = patch
                self.patchId = patch!.id_
                DataController.instance.currentPatch = patch    // Used for context for messages
                self.drawButtons()
				self.draw()
			}
		}
	}
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return UIStatusBarAnimation.Fade
    }

	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/
    
	@IBAction func numberOfWatchersButtonAction(sender: UIButton) {
		self.performSegueWithIdentifier("WatchingListSegue", sender: self)
	}

	@IBAction func contextButtonAction(sender: UIButton) {
        
        if contextAction == .CreateMessage {
            self.performSegueWithIdentifier("MessageEditSegue", sender: self)
        }
        else if contextAction == .SharePatch {
            shareAction()
        }
        else if contextAction == .CancelJoinRequest {
            self.watchButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
        }
        else if contextAction == .SubmitJoinRequest {
            self.watchButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
        }
        else if contextAction == .BrowseUsersWatching {
            self.performSegueWithIdentifier("WatchingListSegue", sender: self)
        }
	}

	@IBAction func unwindFromMessageEdit(segue: UIStoryboardSegue) {
		// Refresh results when unwinding from Message screen to pickup any changes.
        self.refreshQueryItems(force: true)
	}

	@IBAction override func unwindFromPatchEdit(segue: UIStoryboardSegue) {
		// Refresh results when unwinding from Patch edit/create screen to pickup any changes.
		self.refresh()
	}
    
    @IBAction func placeAction(sender: AnyObject) {
        if self.patch != nil {
            self.performSegueWithIdentifier("PlaceDetailSegue", sender: self)
        }
    }
    
    @IBAction func mapAction(sender: AnyObject) {
        if self.patch != nil {
            self.performSegueWithIdentifier("PatchMapSegue", sender: self)
        }
    }
    
    func handleRemoteNotification(notification: NSNotification) {
        
        if let userInfo = notification.userInfo {
            let parentId = userInfo["parentId"] as? String
            let targetId = userInfo["targetId"] as? String
            
            let impactedByNotification = self.patchId == parentId || self.patchId == targetId
            
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
        let options = UIViewAnimationOptions.TransitionFlipFromBottom
            | UIViewAnimationOptions.ShowHideTransitionViews
            | UIViewAnimationOptions.CurveEaseOut
        UIView.transitionFromView(bannerGroup!, toView: infoGroup, duration: 0.4, options: options, completion: nil);
    }
    
    func flipToBanner(sender: AnyObject) {
        let options = UIViewAnimationOptions.TransitionFlipFromTop
            | UIViewAnimationOptions.ShowHideTransitionViews
            | UIViewAnimationOptions.CurveEaseOut
        UIView.transitionFromView(infoGroup!, toView: bannerGroup, duration: 0.4, options: options, completion: nil);
    }
    
    func addAction() {
        self.performSegueWithIdentifier("MessageEditSegue", sender: self)
    }
    
    func editAction() {
        self.performSegueWithIdentifier("PatchEditSegue", sender: self)
    }
    
    func shareAction() {
        
        if self.patch != nil {
            
            Branch.getInstance().getShortURLWithParams(["entityId":self.patchId!, "entitySchema":"patch"], andChannel: "patchr-ios", andFeature: BRANCH_FEATURE_TAG_INVITE, andCallback: {
                (url: String?, error: NSError?) -> Void in
                
                if let error = ServerError(error) {
                    UIViewController.topMostViewController()!.handleError(error)
                }
                else {
                    NSLog("Branch link created: \(url!)")
                    var patch: PatchItem = PatchItem(entity: self.patch!, shareUrl: url!)
                    
                    let activityViewController = UIActivityViewController(
                        activityItems: [patch],
                        applicationActivities: nil)
                    
                    if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Phone {
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

	func draw() {
        
        if self.patch == nil {
            return
        }
        
        /* Name, type and photo */
        
		self.patchName.text = patch!.name
        self.patchType.text = patch.type == nil ? "PATCH" : patch!.type.uppercaseString + " PATCH"
        self.patchPhoto.setImageWithPhoto(patch!.getPhotoManaged(), animate: patchPhoto.image == nil)
        
        /* Place */
        
        if patch!.place != nil {
            placeButton.setTitle(patch!.place.name, forState: .Normal)
            placeButton.fadeIn()
        }

        /* Privacy */
        
        if lockImage != nil {
            lockImage.hidden = (patch!.visibility == "public")
            infoLockImage.hidden = (patch!.visibility == "public")
        }
        if visibility != nil {
            visibility.hidden = (patch!.visibility == "public")
            infoVisibility.hidden = (patch!.visibility == "public")
        }
        
        /* Map button */
        mapButton.hidden = (patch.location == nil)
        
        /* Watching button */
        
        if patch?.countWatchingValue == 0 {
            if watchersButton.alpha != 0 {
                watchersButton.fadeOut()
            }
        }
        else {
            let watchersTitle = "\(self.patch!.countWatching ?? 0) watching"
            self.watchersButton.setTitle(watchersTitle, forState: UIControlState.Normal)
            if watchersButton.alpha == 0 {
                watchersButton.fadeIn()
            }
        }

		/* Like button */
        
        likeButton.bindEntity(self.patch)
        if (patch!.visibility == "public" || patch!.userWatchStatusValue == .Member || isOwner) {
            likeButton.fadeIn(alpha: 1.0)
        }
        else {
            likeButton.fadeOut(alpha: 0.0)
        }
        
        /* Watch button */
        
        watchButton.bindEntity(self.patch)
        
        /* Info view */
        infoName.text = patch!.name
        if patch!.type != nil {
            infoType.text = patch!.type.uppercaseString + " PATCH"
        }
        infoDescription.text = patch!.description_
        if let distance = patch.distance() {
            infoDistance.text = LocationController.instance.distancePretty(distance)
        }
        infoOwner.text = patch!.creator?.name ?? "Deleted"
        
        if isOwner {
            if patch!.countPendingValue > 0 {
                if patch!.countPendingValue == 1 {
                    self.contextButton.setTitle("One member request".uppercaseString, forState: .Normal)
                }
                else {
                    self.contextButton.setTitle("\(patch!.countPendingValue) member requests".uppercaseString, forState: .Normal)
                }
                contextAction = .BrowseUsersWatching
            }
            else {
                self.contextButton.setTitle("Invite friends to this patch".uppercaseString, forState: .Normal)
                contextAction = .SharePatch
            }
        }
        else {
            if patch!.visibility == "public" {
                if patch!.userHasMessagedValue {
                    self.contextButton.setTitle("Invite friends to this patch".uppercaseString, forState: .Normal)
                    contextAction = .SharePatch
                }
                else {
                    self.contextButton.setTitle("Post your first message".uppercaseString, forState: .Normal)
                    contextAction = .CreateMessage
                }
            }
            else {
                if patch!.userWatchStatusValue == .Member {
                    if patch!.userHasMessagedValue {
                        self.contextButton.setTitle("Invite friends to this patch".uppercaseString, forState: .Normal)
                        contextAction = .SharePatch
                    }
                    else {
                        self.contextButton.setTitle("Post your first message".uppercaseString, forState: .Normal)
                        contextAction = .CreateMessage
                    }
                }
                else if patch!.userWatchStatusValue == .Pending {
                    self.contextButton.setTitle("Cancel join request".uppercaseString, forState: .Normal)
                    contextAction = .CancelJoinRequest
                }
                else if patch!.userWatchStatusValue == .NonMember {
                    self.contextButton.setTitle("Request to join".uppercaseString, forState: .Normal)
                    contextAction = .SubmitJoinRequest
                }
                
                if patch!.userWatchJustApprovedValue {
                    if patch!.userHasMessagedValue {
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

    func drawButtons() {
        
        var shareButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: Selector("shareAction"))
        var addButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: Selector("addAction"))
        var spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
        spacer.width = SPACER_WIDTH
        if isOwner {
            let editImage = UIImage(named: "imgEditLight")
            var editButton = UIBarButtonItem(image: editImage, style: UIBarButtonItemStyle.Plain, target: self, action: Selector("editAction"))
            self.navigationItem.rightBarButtonItems = [addButton, spacer, shareButton, spacer, editButton]
        }
        else {
            self.navigationItem.rightBarButtonItems = [addButton, spacer, shareButton]
        }
    }
    
    override func configureCell(cell: UITableViewCell, object: AnyObject, sizingOnly: Bool = false) {

		// The cell width seems to incorrect occassionally
		if CGRectGetWidth(cell.bounds) != CGRectGetWidth(self.tableView.bounds) {
			cell.bounds = CGRect(x: 0, y: 0, width: CGRectGetWidth(self.tableView.bounds), height: CGRectGetHeight(cell.frame))
			cell.setNeedsLayout()
			cell.layoutIfNeeded()
		}
        
        let queryResult = object as! QueryItem
        let message = queryResult.object as! Message
		let cell = cell as! MessageTableViewCell

        cell.entity = message
		cell.delegate = self

		cell.description_.text = nil
		cell.userName.text = nil
		cell.patchName.text = nil
        cell.patchNameHeight.constant = 0

        let linkColor = Colors.brandColorDark
        let linkActiveColor = Colors.brandColorLight
        
        cell.description_.linkAttributes = [kCTForegroundColorAttributeName : linkColor]
        cell.description_.activeLinkAttributes = [kCTForegroundColorAttributeName : linkActiveColor]
        cell.description_.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue|NSTextCheckingType.Address.rawValue
        cell.description_.delegate = self
        
		cell.description_.text = message.description_
        cell.description_.preferredMaxLayoutWidth = CGRectGetWidth(cell.description_.frame)

		if let photo = message.photo {
            if !sizingOnly {
                cell.photo.setImageWithPhoto(photo, animate: cell.photo.image == nil)
            }
            cell.photoTopSpace.constant = 8
            cell.photoHeight.constant = cell.photo.bounds.size.width * 0.5625
		}
        else {
            cell.photoTopSpace.constant = 0
            cell.photoHeight.constant = 0
        }

		if let creator = message.creator {
			cell.userName.text = creator.name
            if !sizingOnly {
                cell.userPhoto.setImageWithPhoto(creator.getPhotoManaged(), animate: cell.userPhoto.image == nil)
            }
		}
        else {
            cell.userName.text = "Deleted"
            if !sizingOnly {
                cell.userPhoto.setImageWithPhoto(Entity.getDefaultPhoto("user"))
            }
        }
        
        /* Likes button */
        cell.likeButton.bindEntity(message)

		cell.likes.hidden = true
		if message.countLikes != nil {
			if message.countLikes?.integerValue != 0 {
				let likesTitle = message.countLikes?.integerValue == 1
						? "\(message.countLikes) like"
						: "\(message.countLikes ?? 0) likes"
				cell.likes.text = likesTitle
				cell.likes.hidden = false
			}
		}
        
		cell.createdDate.text = self.messageDateFormatter.stringFromDate(message.createdDate)
	}

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == nil {
			return
		}

		switch segue.identifier! {
			case "MessageDetailSegue":
				if let controller = segue.destinationViewController as? MessageDetailViewController {
					controller.message = self.selectedMessage
				}
            case "PlaceDetailSegue":
                if let controller = segue.destinationViewController as? PlaceDetailViewController {
                    controller.placeId = self.patch!.place.entityId
                }
			case "MessageEditSegue":
                /* Has its own nav because we segue modally and it needs its own stack */
				if let navigationController = segue.destinationViewController as? UINavigationController {
					if let controller = navigationController.topViewController as? MessageEditViewController {
						controller.toString = patch!.name
						controller.patchId = patchId
					}
				}
			case "PatchEditSegue":
				if let navigationController = segue.destinationViewController as? UINavigationController {
					if let controller = navigationController.topViewController as? PatchEditViewController {
						controller.entity = patch
					}
				}
			case "LikeListSegue", "WatchingListSegue":
				if let controller = segue.destinationViewController as? UserTableViewController {
					controller.patch = self.patch
					controller.filter = segue.identifier == "LikeListSegue" ? .PatchLikers : .PatchWatchers
				}
            case "PatchMapSegue":
                if let controller = segue.destinationViewController as? PatchMapViewController {
                    controller.locationDelegate = self
                }
            
			default: ()
		}
	}

	override func pullToRefreshAction(sender: AnyObject?) -> Void {
        self.refresh(force: true)
        self.refreshQueryItems(force: true)
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
        var text = "\(UserController.instance.currentUser.name) has invited you to the \(self.entity.name) patch! \(self.shareUrl) \n"
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

extension PatchDetailViewController: MapViewDelegate {
    
    func locationForMap() -> CLLocation? {
        if let location = self.patch?.location {
            return CLLocation(latitude: self.patch.location.latValue, longitude: self.patch.location.lngValue)
        }
        return nil
    }
    
    func locationChangedTo(location: CLLocation) {  }
    
    func locationEditable() -> Bool {
        return false
    }
    
    var locationTitle: String? {
        get {
            return self.patch?.name
        }
    }
    
    var locationSubtitle: String? {
        get {
            if let type = self.patch?.type {
                return type.uppercaseString + " PATCH"
            }
            return nil
        }
    }
    
    var locationPhoto: AnyObject? {
        get {
            return self.patch?.photo
        }
    }
}


extension PatchDetailViewController: UITableViewDelegate {
    
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

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem {
            if let message = queryResult.object as? Message {
                self.selectedMessage = message
                self.performSegueWithIdentifier("MessageDetailSegue", sender: self)
                return
            }
        }
		assert(false, "Couldn't set selectedMessage")
	}

	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

		// https://github.com/smileyborg/TableViewCellWithAutoLayout

		/* Fetch or create our prototype cell */
		var cell = self.offscreenCells.objectForKey(CELL_IDENTIFIER) as? UITableViewCell

		if cell == nil {
			let nibObjects = NSBundle.mainBundle().loadNibNamed(cellNibName, owner: self, options: nil)
			cell = nibObjects[0] as? UITableViewCell // Assumes only one view in the nib
			self.offscreenCells.setObject(cell!, forKey: CELL_IDENTIFIER)
		}

		/* Get the data */
		let object: AnyObject = self.fetchedResultsController.objectAtIndexPath(indexPath)

		/* Bind the data to the cell */
        self.configureCell(cell!, object: object, sizingOnly: true)

		/* Request a restraint pass */
		cell?.setNeedsUpdateConstraints()
        cell?.updateConstraintsIfNeeded()

		/* Set the cell bounds using table width and cell height */
		cell?.bounds = CGRect(x: 0, y: 0, width: CGRectGetWidth(self.tableView.bounds), height: CGRectGetHeight(cell!.bounds))

		/* Request a layout pass */
		cell?.setNeedsLayout()
		cell?.layoutIfNeeded()

		/* Get height based on sizing to fit under compression using the current contraints */
		var height = cell!.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height + 1
        
        let queryResult  = object as! QueryItem
        let entity = queryResult.object as! Entity
        
        //        NSLog("Height for row: \(entity.description_) \(height)")
        
        return height
	}
}

extension PatchDetailViewController: TableViewCellDelegate {

	func tableViewCell(cell: UITableViewCell, didTapOnView view: UIView) {
		let messageCell = cell as! MessageTableViewCell
		if view == messageCell.photo && messageCell.photo.image != nil {
            Shared.showPhotoBrowser(messageCell.photo.image, view: view, viewController: self, entity: messageCell.entity)
		}
	}
}

extension PatchDetailViewController: TTTAttributedLabelDelegate {
    
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        UIApplication.sharedApplication().openURL(url)
    }
}

enum ContextAction: UInt {
	case BrowseUsersWatching
	case SharePatch
	case CreateMessage
	case SubmitJoinRequest
	case CancelJoinRequest
}