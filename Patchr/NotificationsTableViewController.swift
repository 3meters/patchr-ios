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

class NotificationsTableViewController: BaseTableViewController {

    private var activityDate:   Int64!
    private var nearbys:        [[NSObject: AnyObject]] = []

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
		self.loadMoreMessage = "LOAD MORE NOTIFICATIONS"
		self.listType = .Notifications
		
		super.viewDidLoad()
		
		/* Turn off estimate so rows are measured up front */
		self.tableView.estimatedRowHeight = 0
		self.tableView.rowHeight = 0
		
		/* Used to monitor for changes */
        self.activityDate = NotificationController.instance.activityDate
	}

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setScreenName("NotificationList")
    }
    
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		/*
		 * A stashed notification date means a notification came in while
		 * the app was closed.
		 */
		if let _ = NSUserDefaults.standardUserDefaults().valueForKey(PatchrUserDefaultKey("notificationDate")) {
			NSUserDefaults.standardUserDefaults().setObject(nil, forKey: PatchrUserDefaultKey("notificationDate"))
			self.bindQueryItems(true)
			self.activityDate = NotificationController.instance.activityDate
		}
		else if NotificationController.instance.activityDate > self.activityDate {
            self.bindQueryItems(true)
            self.activityDate = NotificationController.instance.activityDate
        }
        clearBadges()
	}
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
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
                    
                    let targetId = userInfo["targetId"] as? String
                    
                    switch applicationState {
                        case .Active: // App was active when remote notification was received
							
							/* Viewing notification list */
                            
                            if self.tabBarController?.selectedViewController == self.navigationController
                                && self.navigationController?.topViewController == self {
                                    
                                /* Only refresh notifications if view has already been loaded */
                                if self.isViewLoaded() {
                                    self.bindQueryItems(true)
                                }
                            }
								
							/* Viewing anything other than the nofication list */
								
                            else {
                                
                                /* Add one because user isn't viewing nofications right now */
                                incrementBadges()
                                
                                let json:JSON = JSON(userInfo)
								
								/* Bail if low priority */
								if let priority = json["priority"].int {
									if priority == 3 {
										return
									}
								}
								
								let trigger = json["trigger"].string
								
                                var alert = json["aps"]["alert"].string
                                if alert == nil {
                                    alert = json["alert-x"].string
                                }
                                
                                var description: String = alert!
                                if json["description"] != nil {
                                    description = json["description"].string!
                                }
                                
                                /* Bail if user has disabled this in-app notification */
                                if !notificationEnabledFor(trigger!, description: description) {
                                    return
                                }
								
                                /* Show banner */
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
                                    let photoUrl = PhotoUtils.url(prefix!, source: source!, category: SizeCategory.profile)

                                    SDWebImageManager.sharedManager().downloadImageWithURL(photoUrl, options: SDWebImageOptions.HighPriority, progress: nil, completed: {
                                        (image:UIImage!, error:NSError!, cacheType:SDImageCacheType, finished:Bool, url:NSURL!) -> Void in
                                        if image != nil && finished {
                                            self.showNotificationBar(json["name"].string!, description: description, image: image, targetId: json["targetId"].string!)
                                        }
                                    })
                                }
                                else {
                                    self.showNotificationBar("Notification", description: description, image: nil, targetId: json["targetId"].string!)
                                }
                                
                                /* Chirp */
                                if NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("SoundForNotifications")) {
									if let priority = json["priority"].int {
										if priority == 2 {
											return
										}
									}
									AudioServicesPlaySystemSound(chirpSound)
                                }
                            }
                            
                        case .Inactive: // User tapped on remote notification
                            
                            /* Select the notifications tab and then segue as if the user had selected the notification */
                            self.tabBarController?.selectedViewController = self.navigationController
                            
                            /* Pop back to notication list if necessary */
                            if self.navigationController?.topViewController != self {
                                self.navigationController?.popToRootViewControllerAnimated(false)
                            }
                            
                            /* Knock off one because the user will be view one */
                            decrementBadges()
                            
                            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
                            if targetId!.hasPrefix("pa.") {
                                if let controller = storyboard.instantiateViewControllerWithIdentifier("PatchDetailViewController") as? PatchDetailViewController {
                                    controller.entityId = targetId
                                    self.navigationController?.pushViewController(controller, animated: true)
                                }
                            }
                            else if targetId!.hasPrefix("me.") {
                                if let controller = storyboard.instantiateViewControllerWithIdentifier("MessageDetailViewController") as? MessageDetailViewController {
                                    controller.messageId = targetId
                                    self.navigationController?.pushViewController(controller, animated: true)
                                }
                            }
                        
                        case .Background:   // Shouldn't ever fire
                            assert(false, "Notification controller should never get called when app state == background")
                    }
                }
            }
        }
    }
    
    func applicationDidBecomeActive() {
        /* User either switched to patchr or turned their screen back on. */
        Log.d("Notifications tab: application did become active")
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
    
    override func loadQuery() -> Query {
		
        let id = queryId()
        var query: Query? = Query.fetchOneById(id, inManagedObjectContext: DataController.instance.mainContext)

        if query == nil {
            query = Query.fetchOrInsertOneById(id, inManagedObjectContext: DataController.instance.mainContext) as Query
            query!.name = DataStoreQueryName.NotificationsForCurrentUser.rawValue
            query!.pageSize = DataController.proxibase.pageSizeNotifications
            DataController.instance.saveContext(true)	// Blocks until finished
        }
			
        return query!
    }
	
	func queryId() -> String {
		return "query.\(DataStoreQueryName.NotificationsForCurrentUser.rawValue.lowercaseString)"
	}

    override func bindQueryItems(force: Bool = false, paging: Bool = false) {
        /* Always make sure we have the freshest sidecar data before a query */
        if let groupDefaults = NSUserDefaults(suiteName: "group.com.3meters.patchr.ios") {
            if let storedNearbys = groupDefaults.arrayForKey(PatchrUserDefaultKey("nearby.patches")) as? [[NSObject:AnyObject]] {
                self.nearbys = storedNearbys
            }
        }
        super.bindQueryItems(force, paging: paging)
    }
	
	override func populateSidecar(query: Query) {
		query.sidecar = self.nearbys    // Should make a copy
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
            let controller = storyboard.instantiateViewControllerWithIdentifier(controllerId!)
            if let patchController = controller as? PatchDetailViewController {
                patchController.entityId = targetId
            }
            else if let messageController = controller as? MessageDetailViewController {
                messageController.messageId = targetId
            }
            controller.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: controller, action: Selector("dismissAction:"))
            UIViewController.topMostViewController()?.presentViewController(UINavigationController(rootViewController: controller), animated: true, completion: nil)
        }
    }
    
    func notificationEnabledFor(trigger: String, description: String) -> Bool {
        if trigger == "nearby" {
            return NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("PatchesCreatedNearby"))
        }
        else if trigger == "watch_to" {
            return NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("MessagesForPatchesWatching"))
        }
        else if trigger == "own_to" {
            /* Super hack to differentiate likes from favorites */
            if (description.rangeOfString("like") != nil) {
                return NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("LikeMessage"))
            }
            else if (description.rangeOfString("favorite") != nil) {
                return NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("LikePatch"))
            }
        }
        else if trigger == "share" {
            return NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("MessagesSharing"))
        }
        return true
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
}

class AirStylesheet: NSObject, TWMessageBarStyleSheet {
    
    var image: UIImage?
    
    init(image: UIImage?) {
        if image != nil {
            self.image = image
        }
    }
    
    @objc func backgroundColorForMessageType(type: TWMessageBarMessageType) -> UIColor! {
        return Theme.colorBackgroundNotification
    }
    
    @objc func strokeColorForMessageType(type: TWMessageBarMessageType) -> UIColor! {
        return Theme.colorTextNotification
    }
    
    @objc func iconImageForMessageType(type: TWMessageBarMessageType) -> UIImage! {
        let image = self.image ?? UIImage(named: "imgMessageDark")
        return image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
    }
}

extension NotificationsTableViewController {
	/*
	 * Cells
	 */
	override func bindCell(cell: AirTableViewCell, entity object: AnyObject, location: CLLocation?) -> UIView? {
		
		if let view = super.bindCell(cell, entity: object, location: location) as? NotificationView {
			view.description_?.delegate = self
			view.photo?.addTarget(self, action: Selector("photoAction:"), forControlEvents: .TouchUpInside)
		}
		return nil
	}
    /*
     * UITableViewDelegate
     */
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		
		let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
		if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem,
			let entity = queryResult.object as? Notification {
				if entity.targetId!.hasPrefix("pa.") {
					if let controller = storyboard.instantiateViewControllerWithIdentifier("PatchDetailViewController") as? PatchDetailViewController {
						controller.entityId = entity.targetId
						self.navigationController?.pushViewController(controller, animated: true)
					}
				}
				else if entity.targetId!.hasPrefix("me.") {
					if let controller = storyboard.instantiateViewControllerWithIdentifier("MessageDetailViewController") as? MessageDetailViewController {
						controller.messageId = entity.targetId
						self.navigationController?.pushViewController(controller, animated: true)
					}
				}
		}
	}
	
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		if let height = quickHeight(indexPath) {
			return height
		}
		else {
			return 0
		}
	}
	
	func quickHeight(indexPath: NSIndexPath) -> CGFloat? {
		/*
		* Using an estimate significantly improves table view load time but we can get
		* small scrolling glitches if actual height ends up different than estimated height.
		* So we try to provide the best estimate we can and still deliver it quickly.
		*
		* Note: Called once only for each row in fetchResultController when FRC is making a data pass in
		* response to managedContext.save.
		*/
		if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem,
			let entity = queryResult.object as? Notification {
				
				if entity.id_ != nil {
					if let cachedHeight = self.rowHeights.objectForKey(entity.id_) as? CGFloat {
						return cachedHeight
					}
				}
				
				let minHeight: CGFloat = CELL_USER_PHOTO_SIZE + (CELL_PADDING_VERTICAL * 2)
				let columnLeft = CELL_USER_PHOTO_SIZE + CELL_VIEW_SPACING + (CELL_PADDING_HORIZONTAL * 2)
				let columnWidth = self.tableView.width() - columnLeft
				let photoHeight = columnWidth * CELL_PHOTO_RATIO
				
				var height: CGFloat = CELL_FOOTER_HEIGHT + (CELL_PADDING_VERTICAL * 2)    // Base size if no description or photo
				
				if entity.summary != nil {
					
					let description = entity.summary as NSString
					let attributes = [NSFontAttributeName: UIFont(name:"HelveticaNeue-Light", size: 17)!]
					let options: NSStringDrawingOptions = [NSStringDrawingOptions.UsesLineFragmentOrigin, NSStringDrawingOptions.UsesFontLeading]
					
					/* Most time is spent here */
					let rect: CGRect = description.boundingRectWithSize(CGSizeMake(columnWidth, CGFloat.max),
						options: options,
						attributes: attributes,
						context: nil)
					
					let descHeight = min(rect.height, 102.272)	// Cap at ~5 lines based on HNeueLight 17pts
					height += (descHeight + CELL_VIEW_SPACING + 0.5) // Add a bit because of rounding scruff
				}
				
				if entity.photoBig != nil {
					/* This relies on sizing and spacing of the message view */
					height += photoHeight + CELL_VIEW_SPACING  // 16:9 aspect ratio
				}
				
				height = max(minHeight, height)
				
				if entity.id_ != nil {
					self.rowHeights[entity.id_] = CGFloat(height)
				}
				
				return CGFloat(height + 1)	// Add one for row separator
		}
		else {
			return nil
		}
	}
	
	func layoutHeight(indexPath: NSIndexPath) -> CGFloat? {
		
		if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem,
			let entity = queryResult.object as? Notification {
				
				if entity.id_ != nil {
					if let cachedHeight = self.rowHeights.objectForKey(entity.id_) as? CGFloat {
						return cachedHeight
					}
				}
				
				/* Create and bind a cell */
				var cellType: CellType = .TextAndPhoto
				
				if entity.photoBig == nil {
					cellType = .Text
				}
				else if entity.summary == nil {
					cellType = .Photo
				}
				
				let cell = makeCell(cellType)
				bindCell(cell, entity: queryResult.object, location: nil)
				cell.setNeedsLayout()
				cell.layoutIfNeeded()
				let cellSize = cell.contentView.sizeThatFits(CGSizeMake(self.tableView.frame.size.height, CGFloat.max))
				
				/* Get the actual height required for the cell */
				let height = cellSize.height + 1
				if entity.id_ != nil {
					self.rowHeights[entity.id_] = CGFloat(height)
				}
				
				return CGFloat(height)
		}
		else {
			return nil
		}
	}
}

extension NotificationsTableViewController: TTTAttributedLabelDelegate {
    
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        UIApplication.sharedApplication().openURL(url)
    }
}

let chirpSound: SystemSoundID = createChirpSound()

func createChirpSound() -> SystemSoundID {
    var soundID: SystemSoundID = 0
    let soundURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), "chirp", "caf", nil)
    AudioServicesCreateSystemSoundID(soundURL, &soundID)
    return soundID
}