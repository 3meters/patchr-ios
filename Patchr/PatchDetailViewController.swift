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
            if patch != nil {
                return currentUser.id_ == patch.creator.entityId
            }
        }
        return false
    }
    private var originalTop: CGFloat = 0.0
    private var originalScrollTop: CGFloat = -64.0

	/* Outlets are initialized before viewDidLoad is called */

    @IBOutlet weak var patchPhoto:     UIImageView!
    @IBOutlet weak var patchName:      UILabel!
    @IBOutlet weak var patchType:      UILabel!
    @IBOutlet weak var visibility:     UILabel!
    @IBOutlet weak var likeButton:     UIButton!
    @IBOutlet weak var watchButton:    UIButton!
    @IBOutlet weak var likesButton:    UIButton!
    @IBOutlet weak var watchersButton: UIButton!
    @IBOutlet weak var contextButton:  UIButton!
    @IBOutlet weak var lockImage:      UIImageView!
    @IBOutlet weak var likeActivity:   UIActivityIndicatorView!
    @IBOutlet weak var watchActivity:  UIActivityIndicatorView!
    
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
    @IBOutlet weak var likesButtonWidth: NSLayoutConstraint!

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

		super.viewDidLoad()

		tableView.registerNib(UINib(nibName: cellNibName, bundle: nil), forCellReuseIdentifier: "Cell")
		tableView.delaysContentTouches = false
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
		gradient.frame = patchPhoto.bounds
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
        lockImage.tintColor(AirUi.brandColor)
        infoLockImage.tintColor(AirUi.brandColor)
        likeButton.alpha = 0.0
        watchButton.alpha = 0.0
        likesButton.alpha = 0.0
        likesButtonWidth.constant = 0
        watchersButton.alpha = 0.0
        likeActivity.stopAnimating()
        watchActivity.stopAnimating()
        originalTop = patchPhotoTop.constant
        self.contextButton?.setTitle("", forState: .Normal)
        
        /* Navigation bar buttons */
        
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
    
    override func viewWillAppear(animated: Bool) {
        /*
         * Entity could have been delete while we were away to check it.
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
        
        refresh(force: true)
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
				self.draw()
			}
		}
	}

	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/

	@IBAction func watchAction(sender: AnyObject) {
        watchButton.enabled = false
        watchActivity.startAnimating()
        watchButton.alpha = 0.0
        
        if patch!.userWatchStatusValue == .Member {
            /* TODO: If not owner then confirm leave */
            DataController.proxibase.deleteLinkById(patch!.userWatchId!) {
                response, error in
                
                self.watchActivity.stopAnimating()
                if error == nil {
                    if let serviceData = DataController.instance.dataWrapperForResponse(response!) {
                        self.patch!.userWatchId = nil
                        self.patch!.userWatchStatusValue = .NonMember
                        self.patch!.countWatchingValue--
                    }
                }
                self.draw()
                self.watchButton.enabled = true
            }
        }
        else if patch!.userWatchStatusValue == .Pending {
            DataController.proxibase.deleteLinkById(patch!.userWatchId!) {
                response, error in
                
                self.watchActivity.stopAnimating()
                if error == nil {
                    if let serviceData = DataController.instance.dataWrapperForResponse(response!) {
                        self.patch!.userWatchId = nil
                        self.patch!.userWatchStatusValue = .NonMember
                    }
                }
                self.draw()
                self.watchButton.enabled = true
            }
        }
        else if patch!.userWatchStatusValue == .NonMember {
            /* Service automatically sets enabled = false if user is not the patch owner */
            DataController.proxibase.insertLink(UserController.instance.userId! as String, toID: patch!.id_, linkType: .Watch) {
                response, error in
                
                self.watchActivity.stopAnimating()
                if error == nil {
                    if let serviceData = DataController.instance.dataWrapperForResponse(response!) {
                        if serviceData.countValue == 1 {
                            if let entityDictionaries = serviceData.data as? [[String:NSObject]] {
                                let map = entityDictionaries[0]
                                self.patch!.userWatchId = map["_id"] as! String
                                if let enabled = map["enabled"] as? Bool {
                                    if enabled {
                                        self.patch!.userWatchStatusValue = .Member
                                        self.patch!.countWatchingValue++
                                    }
                                    else {
                                        self.patch!.userWatchStatusValue = .Pending
                                    }
                                }
                            }
                        }
                    }
                }
                self.draw()
                self.watchButton.enabled = true
            }
        }
	}

	@IBAction func likeAction(sender: AnyObject) {
        likeButton.enabled = false
        likeActivity.startAnimating()
        likeButton.alpha = 0.0
        if patch!.userLikesValue {
            DataController.proxibase.deleteLinkById(patch!.userLikesId!) {
                response, error in
                
                self.likeActivity.stopAnimating()
                if error == nil {
                    if let serviceData = DataController.instance.dataWrapperForResponse(response!) {
                        self.patch!.userLikesId = nil
                        self.patch!.userLikesValue = false
                        self.patch!.countLikesValue--
                    }
                }
                self.draw()
                self.likeButton.enabled = true
            }
        }
        else {
            DataController.proxibase.insertLink(UserController.instance.userId! as String, toID: patch!.id_, linkType: .Like) {
                response, error in
                
                self.likeActivity.stopAnimating()
                if error == nil {
                    if let serviceData = DataController.instance.dataWrapperForResponse(response!) {
                        if serviceData.countValue == 1 {
                            if let entityDictionaries = serviceData.data as? [[String:NSObject]] {
                                let map = entityDictionaries[0]
                                self.patch!.userLikesId = map["_id"] as! String
                            }
                            self.patch!.userLikesValue = true
                            self.patch!.countLikesValue++
                        }
                    }
                }
                self.draw()
                self.likeButton.enabled = true
            }
        }
	}
	
	@IBAction func numberOfLikesButtonAction(sender: UIButton) {
		self.performSegueWithIdentifier("LikeListSegue", sender: self)
	}

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
            DataController.proxibase.deleteLinkById(patch!.userWatchId!) {
                _, _ in
                self.patch!.userWatchStatusValue = .NonMember
                self.draw()
            }
        }
        else if contextAction == .SubmitJoinRequest {
            DataController.proxibase.insertLink(UserController.instance.userId! as String, toID: patch!.id_, linkType: .Watch) {
                _, _ in
                self.patch!.userWatchStatusValue = .Pending
                self.draw()
            }
        }
        else if contextAction == .BrowseUsersWatching {
            self.performSegueWithIdentifier("WatchingListSegue", sender: self)
        }
	}

	@IBAction func unwindFromMessageEdit(segue: UIStoryboardSegue) {
		// Refresh results when unwinding from Message screen to pickup any changes.
		self.refresh()
	}

	@IBAction override func unwindFromPatchEdit(segue: UIStoryboardSegue) {
		// Refresh results when unwinding from Patch edit/create screen to pickup any changes.
		self.refresh()
	}
    
    @IBAction func placeAction(sender: AnyObject) {
        self.performSegueWithIdentifier("PlaceDetailSegue", sender: self)
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
        
        if patch != nil {
            let patchURL                   = NSURL(string: "http://patchr.com/patch/\(self.patch!.id_)") ?? NSURL(string: "http://patchr.com")!
            let shareText                  = "You've been invited to the \(self.patch!.name) patch! \n\n\(patchURL.absoluteString!) \n\nGet the Patchr app at http://patchr.com"
            var activityItems: [AnyObject] = [shareText]
            
            let activityViewController = UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: nil)
            
            self.presentViewController(activityViewController, animated: true, completion: nil)
        }
    }
    
	/*--------------------------------------------------------------------------------------------
	 * Methods
	 *--------------------------------------------------------------------------------------------*/

	func draw() {
        
		self.patchName.text = patch!.name
        if patch.type != nil {
            self.patchType.text = patch!.type.uppercaseString + " PATCH"
        }
        self.patchPhoto.setImageWithPhoto(patch!.getPhotoManaged(), animate: patchPhoto.image == nil)
        
        /* Place */
        
        placeButton.hidden = (patch!.place == nil)
        if patch!.place != nil {
            placeButton.setTitle(patch!.place.name, forState: .Normal)
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
        
        /* Likes button */
        
        if patch?.countLikesValue == 0 {
            if likesButton.alpha != 0 {
                likesButton.fadeOut()
                self.buttonGroup.layoutIfNeeded()
                self.likesButtonWidth.constant = 0
                UIView.animateWithDuration(0.2, animations: {
                    self.buttonGroup.layoutIfNeeded()
                })
            }
        }
        else {
            let likesTitle = self.patch!.countLikesValue == 1
                ? "\(self.patch!.countLikes) like"
                : "\(self.patch!.countLikes ?? 0) likes"
            self.likesButton.setTitle(likesTitle, forState: UIControlState.Normal)
            if likesButton.alpha == 0 {
                likesButton.fadeIn()
                self.buttonGroup.layoutIfNeeded()
                self.likesButtonWidth.constant = 60
                UIView.animateWithDuration(0.2, animations: {
                    self.buttonGroup.layoutIfNeeded()
                })
            }
        }
        
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
        
        if (patch!.visibility == "public" || patch!.userWatchStatusValue == .Member || isOwner) {
            if patch!.userLikesValue {
                likeButton.imageView?.tintColor(AirUi.brandColor)
                if likeButton.alpha <= 0.5 {
                    likeButton.fadeIn(alpha: 1.0)
                }
            }
            else {
                likeButton.imageView?.tintColor(UIColor.whiteColor())
                if likeButton.alpha <= 0.5 {
                    likeButton.fadeIn(alpha: 0.7)
                }
            }
        }
        
        /* Watch button */
        
        if (patch!.userWatchStatusValue == .Member || patch!.userWatchStatusValue == .Pending){
            watchButton.imageView?.tintColor(AirUi.brandColor)
            if watchButton.alpha <= 0.5 {
                watchButton.fadeIn(alpha: 1.0)
            }
        }
        else {
            watchButton.imageView?.tintColor(UIColor.whiteColor())
            if watchButton.alpha <= 0.5 {
                watchButton.fadeIn(alpha: 0.7)
            }
        }
        
        /* Info view */
        infoName.text = patch!.name
        infoType.text = patch!.type.uppercaseString + " PATCH"
        infoDescription.text = patch!.description_
        infoDistance.text = LocationController.instance.distancePretty(patch!.distanceValue)
        infoOwner.text = patch!.creator.name
        
        if isOwner {
            /* TODO: Need to show pending request count */
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

	override func configureCell(cell: UITableViewCell, object: AnyObject) {

		// The cell width seems to incorrect occassionally
		if CGRectGetWidth(cell.bounds) != CGRectGetWidth(self.tableView.bounds) {
			cell.bounds = CGRect(x: 0, y: 0, width: CGRectGetWidth(self.tableView.bounds), height: CGRectGetHeight(cell.frame))
			cell.setNeedsLayout()
			cell.layoutIfNeeded()
		}
        
        let queryResult = object as! QueryItem
        let message = queryResult.object as! Message
		let cell = cell as! MessageTableViewCell

		cell.delegate = self

		cell.description_.text = nil
		cell.userName.text = nil
		cell.patchName.text = nil

		cell.description_.text = message.description_

		if let photo = message.photo {
            cell.photo.setImageWithPhoto(photo, animate: cell.photo.image == nil)
            cell.photoHolderHeight.constant = cell.photo.frame.height + 8
		}
        else {
            cell.photoHolderHeight.constant = 0
        }

		if let creator = message.creator {
			cell.userName.text = creator.name
            cell.userPhoto.setImageWithPhoto(creator.getPhotoManaged(), animate: cell.userPhoto.image == nil)
		}

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
		cell.patchName.text = self.patch!.name
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
			default: ()
		}
	}

	override func pullToRefreshAction(sender: AnyObject?) -> Void {
        self.refresh(force: true)
        refreshQueryItems(force: true)
	}

	func handleRemoteNotification(notification: NSNotification) {

		if let userInfo = notification.userInfo {
			let parentId = userInfo["parentId"] as? String
			let targetId = userInfo["targetId"] as? String

			let impactedByNotification = self.patch?.id_ == parentId || self.patch?.id_ == targetId

			// Only refresh notifications if view has already been loaded
			// and the notification is related to this Patch
			if self.isViewLoaded() && impactedByNotification {
				self.refreshControl?.beginRefreshing()
				self.pullToRefreshAction(self.refreshControl)
			}
		}
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
}

extension PatchDetailViewController: UITableViewDelegate {
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        if patchPhotoTop != nil {
            /* Parallax effect when user scrolls down */
            let offset = scrollView.contentOffset.y
            if offset >= originalScrollTop {
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
		var cell = self.offscreenCells.objectForKey("Cell") as? UITableViewCell

		if cell == nil {
			let nibObjects = NSBundle.mainBundle().loadNibNamed(cellNibName, owner: self, options: nil)
			cell = nibObjects[0] as? UITableViewCell // Assumes only one view in the nib
			self.offscreenCells.setObject(cell!, forKey: "Cell")
		}

		/* Get the data */
		let object: AnyObject = self.fetchedResultsController.objectAtIndexPath(indexPath)

		/* Bind the data to the cell */
		self.configureCell(cell!, object: object)

		/* Request a restraint pass */
		cell?.setNeedsUpdateConstraints()
		cell?.updateConstraintsIfNeeded()

		/* Set the cell bounds using table width and cell height */
		cell?.bounds = CGRect(x: 0, y: 0, width: CGRectGetWidth(self.tableView.bounds), height: CGRectGetHeight(cell!.frame))

		/* Request a layout pass */
		cell?.setNeedsLayout()
		cell?.layoutIfNeeded()

		/* Get height based on sizing to fit under compression using the current contraints */
		var height = cell!.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height + 1

		return height
	}
}

extension PatchDetailViewController: TableViewCellDelegate {

	func tableViewCell(cell: UITableViewCell, didTapOnView view: UIView) {
		let messageCell = cell as! MessageTableViewCell
		if view == messageCell.photo && messageCell.photo.image != nil {
			AirUi.instance.showPhotoBrowser(messageCell.photo.image, view: view, viewController: self)
		}
	}
}

enum ContextAction: UInt {
	case BrowseUsersWatching
	case SharePatch
	case CreateMessage
	case SubmitJoinRequest
	case CancelJoinRequest
}