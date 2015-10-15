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
	private var rowHeights:		NSMutableDictionary = [:]

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
        
        self.contentViewName = "NotificationView"
        self.emptyMessage = "No notifications yet"
		self.loadMoreMessage = "LOAD MORE MESSAGES"
		self.listType = .Notifications
		
		super.viewDidLoad()
		
		/* Used to monitor for changes */
        self.activityDate = NotificationController.instance.activityDate
	}

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setScreenName("NotificationList")
    }
    
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
        if NotificationController.instance.activityDate > self.activityDate {
            self.bindQueryItems(true)
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
                                    let photoUrl = PhotoUtils.url(prefix!, source: source!, category: SizeCategory.profile, size: nil)

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
    
    override func query() -> Query {
        if self._query == nil {
            let query = Query.insertInManagedObjectContext(DataController.instance.managedObjectContext) as! Query
            query.name = DataStoreQueryName.NotificationsForCurrentUser.rawValue
            query.pageSize = DataController.proxibase.pageSizeNotifications
			DataController.instance.saveContext()
            self._query = query
        }
        return self._query
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

    override func populateSidecar(query: Query) {
        query.sidecar = self.nearbys    // Should make a copy
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

	/*--------------------------------------------------------------------------------------------
	* Cells
	*--------------------------------------------------------------------------------------------*/
	
	override func bindCell(cell: UITableViewCell, entity object: AnyObject, location: CLLocation?) -> UIView? {
		
		if let view = super.bindCell(cell, entity: object, location: location) as? NotificationCell {
			/* Hookup up delegates */
			if let label = view.description_ as? TTTAttributedLabel {
				label.delegate = self
			}
			view.delegate = self
		}
		return nil
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

extension NotificationsTableViewController {
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
			return UITableViewAutomaticDimension
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
				
				let minHeight: CGFloat = 64
				var height: CGFloat = 36    // Base size if no description or photo
				
				let columnWidth: CGFloat = UIScreen.mainScreen().bounds.size.width - (24 /* spacing */ + 48 /* user photo */)
				if entity.summary != nil {
					let description = entity.summary as NSString
					let attributes = [NSFontAttributeName: UIFont(name:"HelveticaNeue-Light", size: 17)!]
					/* Most time is spent here */
					let rect: CGRect = description.boundingRectWithSize(CGSizeMake(columnWidth, CGFloat.max), options: .UsesLineFragmentOrigin, attributes: attributes, context: nil)
					let descHeight = min(rect.height, 94)
					height += (descHeight + 8)
				}
				
				if entity.photoBig != nil {
					/* This relies on sizing and spacing of the message view */
					height += (CGFloat(Int(columnWidth * 0.5625)) + 8)  // 16:9 aspect ratio
				}
				
				if minHeight > height {
					height = minHeight
				}
				
				if entity.id_ != nil {
					self.rowHeights[entity.id_] = CGFloat(height)
				}
				
				return CGFloat(height + 1)
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
				let cell = buildCell()
				bindCell(cell, entity: queryResult.object, location: nil)
				
				cell.setNeedsUpdateConstraints()
				cell.updateConstraintsIfNeeded()
				cell.setNeedsLayout()
				cell.layoutIfNeeded()

				/* Get the actual height required for the cell */
				let height = cell.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height + 1
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

extension NotificationsTableViewController: ViewDelegate {
	
    func view(container: UIView, didTapOnView view: UIView) {
        if let view = view as? AirImageView, container = container as? NotificationCell {
            if view.image != nil {
                Shared.showPhotoBrowser(view.image, view: view, viewController: self, entity: container.entity)
            }
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