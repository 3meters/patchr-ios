//
//  NotificationsTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-27.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import Parse
import AudioToolbox

let chirpSound: SystemSoundID = createChirpSound()

func createChirpSound() -> SystemSoundID {
    var soundID: SystemSoundID = 0
    let soundURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), "chirp", "caf", nil)
    AudioServicesCreateSystemSoundID(soundURL, &soundID)
    return soundID
}

class NotificationsTableViewController: QueryTableViewController {

	private let cellNibName = "NotificationTableViewCell"

	private var offscreenCells:       NSMutableDictionary = NSMutableDictionary()
	private var messageDateFormatter: NSDateFormatter!
	private var selectedPatch:        Patch?
	private var selectedMessage:      Message?
    private var selectedEntityId:     String?
    private var activityDate:         Int64!
    
	private var _query:               Query!
    
	override func query() -> Query {
		if self._query == nil {
			let query = Query.insertInManagedObjectContext(DataController.instance.managedObjectContext) as! Query
			query.name = DataStoreQueryName.NotificationsForCurrentUser.rawValue
            query.pageSize = DataController.proxibase.pageSizeNotifications
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidBecomeActive",
            name: Event.ApplicationDidBecomeActive.rawValue, object: nil)
	}

	override func viewDidLoad() {
        
        self.emptyMessage = "No notifications yet"
        
		super.viewDidLoad()

		tableView.registerNib(UINib(nibName: cellNibName, bundle: nil), forCellReuseIdentifier: CELL_IDENTIFIER)

		let dateFormatter = NSDateFormatter()
		dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
		dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
		dateFormatter.doesRelativeDateFormatting = true
		self.messageDateFormatter = dateFormatter
        
        self.activityDate = NotificationController.instance.activityDate
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
        if NotificationController.instance.activityDate > self.activityDate {
            self.refreshQueryItems(force: true)
            self.activityDate = NotificationController.instance.activityDate
        }
        clearBadges()
	}

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    func dismissModal(sender: AnyObject?) {
        if let button = sender as? UIBarButtonItem {
            if let controller = button.target as? UIViewController {
                controller.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }
    
    func handleRemoteNotification(notification: NSNotification) {
        
        if let userInfo = notification.userInfo {
            if let stateRaw = userInfo["receivedInApplicationState"] as? Int {
                if let applicationState = UIApplicationState(rawValue: stateRaw) {
                    
                    let parentId = userInfo["parentId"] as? String
                    let targetId = userInfo["targetId"] as? String
                    
                    switch applicationState {
                        case .Active: // App was active when remote notification was received
                            
                            if NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("SoundForNotifications")) {
                                AudioServicesPlaySystemSound(chirpSound)
                            }
                            
                            if self.tabBarController?.selectedViewController == self.navigationController
                                && self.navigationController?.topViewController == self {
                                    
                                /* Only refresh notifications if view has already been loaded */
                                if self.isViewLoaded() {
                                    self.refreshQueryItems(force: true)
                                }
                            }
                            else {
                                
                                /* Show banner */
                                let json:JSON = JSON(userInfo)
                                let alert = json["aps"]["alert"].string
                                var description: String = alert!
                                if json["description"] != nil {
                                    description = json["description"].string!
                                }
                                var subtitle: String?
                                if json["subtitle"] != nil && json["subtitle"].string != "subtitle" {
                                    subtitle = json["subtitle"].string?.stringByReplacingOccurrencesOfString("<b>", withString: "", options: .LiteralSearch, range: nil)
                                    subtitle = subtitle!.stringByReplacingOccurrencesOfString("</b>", withString: "", options: .LiteralSearch, range: nil)
                                    if json["description"] == nil {
                                        description = subtitle!
                                    }
                                    else {
                                        description = "\(description)\n\n\(subtitle!)"
                                    }
                                }
                                
                                if json["photo"] != nil {
                                    let prefix = json["photo"]["prefix"].string
                                    let source = json["photo"]["source"].string
                                    let width = json["photo"]["width"].int
                                    let height = json["photo"]["height"].int
                                    
                                    var frameHeightPixels = Int(36 * PIXEL_SCALE)
                                    var frameWidthPixels = Int(36 * PIXEL_SCALE)
                                    
                                    let photoUrl = PhotoUtils.url(prefix!, source: source!)
                                    let photoUrlSized = PhotoUtils.urlSized(photoUrl, frameWidth: frameWidthPixels, frameHeight: frameHeightPixels, photoWidth: width, photoHeight: height)

                                    SDWebImageManager.sharedManager().downloadImageWithURL(photoUrlSized, options: SDWebImageOptions.HighPriority, progress: nil, completed: {
                                        (image:UIImage!, error:NSError!, cacheType:SDImageCacheType, finished:Bool, url:NSURL!) -> Void in
                                        if image != nil && finished {
                                            self.showNotificationBar(json["name"].string!, description: description, image: image, targetId: json["targetId"].string!)
                                        }
                                    })
                                }
                                else {
                                    self.showNotificationBar("Notification", description: description, image: nil, targetId: json["targetId"].string!)
                                }
                                
                                /* Add one because user isn't viewing nofications right now */
                                incrementBadges()
                            }
                            
                        case .Inactive: // App was resumed or launched via remote notification
                            
                            /* Select the notifications tab and then segue as if the user had selected the notification */
                            self.tabBarController?.selectedViewController = self.navigationController
                            
                            /* Pop back to notication list if necessary */
                            if self.navigationController?.topViewController != self {
                                self.navigationController?.popToRootViewControllerAnimated(false)
                            }
                            
                            /* Knock off one because the user will be view one */
                            decrementBadges()
                            
                            self.segueWith(targetId, parentId: parentId, refreshEntities: true)
                            
                        case .Background:
                            ()
                    }
                }
            }
        }
    }
    
    func applicationDidBecomeActive() {
        /* User either switched to patchr or turned their screen back on. */
        println("Notifications tab: application did become active")
        if self.tabBarController?.selectedViewController == self.navigationController
            && self.navigationController?.topViewController == self {
                // This view controller is currently visible. Don't badge.
                clearBadges()
        }
        else {
            let badgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber
            self.navigationController?.tabBarItem.badgeValue = (badgeNumber == 0) ? nil : String(badgeNumber)
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
	override func configureCell(cell: UITableViewCell, object: AnyObject, sizingOnly: Bool = false) {

		// The cell width seems to incorrect occassionally
		if CGRectGetWidth(cell.bounds) != CGRectGetWidth(self.tableView.bounds) {
			cell.bounds = CGRect(x: 0, y: 0, width: CGRectGetWidth(self.tableView.bounds), height: CGRectGetHeight(cell.frame))
			cell.setNeedsLayout()
			cell.layoutIfNeeded()
		}

		let queryResult  = object as! QueryItem
		let notification = queryResult.object as! Notification
		let cell         = cell as! NotificationTableViewCell

		cell.delegate = self

		cell.description_.text = nil
        
        let linkColor = Colors.brandColorDark
        let linkActiveColor = Colors.brandColorLight
        
        cell.description_.linkAttributes = [kCTForegroundColorAttributeName : linkColor]
        cell.description_.activeLinkAttributes = [kCTForegroundColorAttributeName : linkActiveColor]
        cell.description_.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
        cell.description_.delegate = self
        
		cell.description_.text = notification.summary
        
        if let photo = notification.photoBig {
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

        cell.userPhoto.setImageWithPhoto(notification.getPhotoManaged(), animate: cell.userPhoto.image == nil)
		cell.createdDate.text = self.messageDateFormatter.stringFromDate(notification.createdDate)
        
        /* Age indicator */
        cell.ageDot.layer.backgroundColor = Colors.accentColor.CGColor
        let now = NSDate()
        
        /* Age of notification in hours */
        let interval = Int(now.timeIntervalSinceDate(NSDate(timeIntervalSince1970: notification.createdDate.timeIntervalSince1970)) / 3600)
        if interval > 12 {
            cell.ageDot.alpha = 0.0
        }
        else if interval > 1 {
            cell.ageDot.alpha = 0.25
        }
        else {
            cell.ageDot.alpha = 1.0
        }

		if notification.type == "media" {
			cell.iconImageView.image = UIImage(named: "imgMediaLight")
		}
		else if notification.type == "message" {
			cell.iconImageView.image = UIImage(named: "imgMessageLight")
		}
		else if notification.type == "watch" {
			cell.iconImageView.image = UIImage(named: "imgWatchLight")
		}
        else if notification.type == "like" {
            if notification.targetId.hasPrefix("pa.") {
                cell.iconImageView.image = UIImage(named: "imgStarFilledLight")
            }
            else {
                cell.iconImageView.image = UIImage(named: "imgLikeLight")
            }
        }
		else if notification.type == "share" {
			cell.iconImageView.image = UIImage(named: "imgShareLight")
		}
        cell.iconImageView.tintColor(Colors.brandColor)
	}

    func segueWith(targetId: String?, parentId: String?, refreshEntities: Bool = false) {
        if targetId == nil { return }
        
        self.selectedEntityId = targetId
        if targetId!.hasPrefix("pa.") {
            self.performSegueWithIdentifier("PatchDetailSegue", sender: self)
        }
        else if targetId!.hasPrefix("me.") {
            self.performSegueWithIdentifier("MessageDetailSegue", sender: self)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == nil {
            return
        }
        
        switch segue.identifier! {
        case "PatchDetailSegue":
            if let controller = segue.destinationViewController as? PatchDetailViewController {
                controller.patchId = self.selectedEntityId
                self.selectedEntityId = nil
            }
        case "MessageDetailSegue":
            if let controller = segue.destinationViewController as? MessageDetailViewController {
                controller.messageId = self.selectedEntityId
                self.selectedEntityId = nil
            }
        default: ()
        }
    }

    func showNotificationBar(title: String, description: String, image: UIImage?, targetId: String) {
        
        TWMessageBarManager.sharedInstance().styleSheet = AirStylesheet(image: image)
        TWMessageBarManager.sharedInstance().showMessageWithTitle(title,
            description: description,
            type: TWMessageBarMessageType.Info,
            duration: 5.0) {
                
            if targetId.hasPrefix("me.") {
                self.showViewControllerBySchema("message", targetId: targetId)
            }
            else if targetId.hasPrefix("pa.") {
                self.showViewControllerBySchema("patch", targetId: targetId)
            }
        }
    }
    
    func showViewControllerBySchema(schema: String, targetId: String) {
        var controllerId: String?
        if schema == "patch" {
            controllerId = "PatchDetailViewController"
        }
        else if schema == "message" {
            controllerId = "MessageDetailViewController"
        }
        
        if controllerId != nil {
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            if let controller = storyboard.instantiateViewControllerWithIdentifier(controllerId!) as? UIViewController {
                if let patchController = controller as? PatchDetailViewController {
                    patchController.patchId = targetId
                }
                else if let messageController = controller as? MessageDetailViewController {
                    messageController.messageId = targetId
                }
                controller.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: controller, action: Selector("dismissAction:"))
                UIViewController.topMostViewController()?.presentViewController(UINavigationController(rootViewController: controller), animated: true, completion: nil)
            }
        }
    }
    
    func clearBadges() {
        self.navigationController?.tabBarItem.badgeValue = nil
        
        /* Automatically sets applicationIconBadgeNumber too */
        if PFInstallation.currentInstallation().badge != 0 {
            PFInstallation.currentInstallation().badge = 0
            PFInstallation.currentInstallation().saveEventually(nil)
        }
    }
    
    func decrementBadges() {
        if PFInstallation.currentInstallation().badge == 0 {
            self.navigationController?.tabBarItem.badgeValue = nil
            return
        }
        else {
            let badge = PFInstallation.currentInstallation().badge - 1
            self.navigationController?.tabBarItem.badgeValue = String(badge)
            PFInstallation.currentInstallation().badge = badge
            PFInstallation.currentInstallation().saveEventually(nil)
        }
    }

    func incrementBadges() {
        let badge = PFInstallation.currentInstallation().badge + 1
        self.navigationController?.tabBarItem.badgeValue = String(badge)
        PFInstallation.currentInstallation().badge = badge
        PFInstallation.currentInstallation().saveEventually(nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

class AirStylesheet: NSObject, TWMessageBarStyleSheet {
    
    var image: UIImage?
    
    init(image: UIImage?) {
        self.image = image
    }
    
    @objc func backgroundColorForMessageType(type: TWMessageBarMessageType) -> UIColor! {
        return Colors.brandColorDark
    }
    
    @objc func strokeColorForMessageType(type: TWMessageBarMessageType) -> UIColor! {
        return Colors.brandColorLight
    }
    
    @objc func iconImageForMessageType(type: TWMessageBarMessageType) -> UIImage! {
        let image = self.image ?? UIImage(named: "imgMessageDark")
        return image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
    }
}

extension NotificationsTableViewController: UITableViewDelegate {
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let queryResult  = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem {
            if let notification = queryResult.object as? Notification {
                self.segueWith(notification.targetId, parentId: notification.parentId)
            }
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        var cell = self.offscreenCells.objectForKey(CELL_IDENTIFIER) as? UITableViewCell
        
        if cell == nil {
            let nibObjects = NSBundle.mainBundle().loadNibNamed(cellNibName, owner: self, options: nil)
            cell = nibObjects[0] as? UITableViewCell
            self.offscreenCells.setObject(cell!, forKey: CELL_IDENTIFIER)
        }
        
        let object: AnyObject = self.fetchedResultsController.objectAtIndexPath(indexPath)
        
        self.configureCell(cell!, object: object, sizingOnly: true)
        
        cell?.setNeedsUpdateConstraints()
        cell?.updateConstraintsIfNeeded()
        
        cell?.bounds = CGRect(x: 0, y: 0, width: CGRectGetWidth(self.tableView.bounds), height: CGRectGetHeight(cell!.frame))
        
        cell?.setNeedsLayout()
        cell?.layoutIfNeeded()
        
        var height = cell!.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height + 1
        
        return height
    }
}

extension NotificationsTableViewController: TableViewCellDelegate {
    
	func tableViewCell(cell: UITableViewCell, didTapOnView view: UIView) {
		let notificationCell = cell as! NotificationTableViewCell
		if view == notificationCell.photo && notificationCell.photo.image != nil {
            Shared.showPhotoBrowser(notificationCell.photo.image, view: view, viewController: self, entity: nil)
		}
	}
}

extension NotificationsTableViewController: TTTAttributedLabelDelegate {
    
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        UIApplication.sharedApplication().openURL(url)
    }
}