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
import SDWebImage
import TWMessageBarManager

class NotificationsTableViewController: BaseTableViewController {

    private var nearbys:        [[NSObject: AnyObject]] = []
	
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
	convenience init() {
		self.init(nibName: nil, bundle: nil)
	}
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		initialize()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initialize()
	}

	override func viewDidLoad() {
		
        self.emptyMessage = "No notifications yet"
		self.loadMoreMessage = "LOAD MORE NOTIFICATIONS"
		self.listType = .Notifications
		self.itemTemplate = NotificationView()
		self.itemPadding = UIEdgeInsetsMake(12, 12, 12, 12)

		self.navigationItem.title = "Notifications"
		
		super.viewDidLoad()
	}

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Reporting.screen("NotificationList")
    }
    
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		/*
		 * A stashed notification date means a notification came in while
		 * the app was closed.
		 */
		if let _ = NSUserDefaults.standardUserDefaults().valueForKey(PatchrUserDefaultKey("notificationDate")) {
			NSUserDefaults.standardUserDefaults().setObject(nil, forKey: PatchrUserDefaultKey("notificationDate"))
			NSUserDefaults.standardUserDefaults().synchronize()
		}
		
		if getActivityDate() != self.query.activityDateValue {
			self.fetchQueryItems(force: true, paging: false, queryDate: getActivityDate())
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
    
    func didReceiveRemoteNotification(notification: NSNotification) {
		
        if let userInfo = notification.userInfo {
			
            if let stateRaw = userInfo["receivedInApplicationState"] as? Int {
                if let applicationState = UIApplicationState(rawValue: stateRaw) {
                    
                    let targetId = userInfo["targetId"] as? String
                    
                    switch applicationState {
                        case .Active: // App was active when remote notification was received
							
							let json:JSON = JSON(userInfo)
							let trigger = json["trigger"].string
							
							/* Viewing notification list */
							
                            if self.tabBarController?.selectedViewController == self.navigationController
                                && self.navigationController?.topViewController == self {
                                    
                                /* Only refresh notifications if view has already been loaded */
                                if self.isViewLoaded() {
									if getActivityDate() != self.query.activityDateValue {
										self.fetchQueryItems(force: true, paging: false, queryDate: getActivityDate())
										
										/* Bail if user has disabled this in-app notification */
										if !notificationEnabledFor(trigger!, description: description) {
											return
										}
										
										/* Chirp */
										if NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("SoundForNotifications")) {
											if let priority = json["priority"].int {
												if priority == 2 {
													return
												}
											}
											AudioServicesPlaySystemSound(AudioController.chirpSound)
										}
									}
                                }
                            }
								
							/* Viewing anything other than the nofication list */
								
                            else {
                                
                                /* Add one because user isn't viewing nofications right now */
                                incrementBadges()
                                
								/* Bail if low priority */
								if let priority = json["priority"].int {
									if priority == 3 {
										return
									}
								}
								
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
                                }
								
								let invitation = json["trigger"] != nil && json["trigger"].string == "share" && description.lowercaseString.rangeOfString("invite") != nil
								var duration: CGFloat = 5.0
								if invitation {
									duration = 10.0
									description += "\n\nTap to go to the invitation"
								}
								
                                if json["photo"] != nil {
                                    let prefix = json["photo"]["prefix"].string
                                    let source = json["photo"]["source"].string
                                    let photoUrl = PhotoUtils.url(prefix!, source: source!, category: SizeCategory.profile)

                                    SDWebImageManager.sharedManager().downloadImageWithURL(photoUrl, options: SDWebImageOptions.HighPriority, progress: nil, completed: {
                                        (image:UIImage!, error:NSError!, cacheType:SDImageCacheType, finished:Bool, url:NSURL!) -> Void in
                                        if image != nil && finished {
											self.showNotificationBar(json["name"].string!, description: description, image: image, targetId: json["targetId"].string!, duration: duration)
                                        }
                                    })
                                }
                                else {
									self.showNotificationBar(json["name"].string!, description: description, image: nil, targetId: json["targetId"].string!, duration: duration)
                                }
                                
                                /* Chirp */
                                if NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("SoundForNotifications")) {
									if let priority = json["priority"].int {
										if priority == 2 {
											return
										}
									}
									AudioServicesPlaySystemSound(AudioController.chirpSound)
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
                            
                            if targetId!.hasPrefix("pa.") {
								let controller = PatchDetailViewController()
                                controller.entityId = targetId
                                self.navigationController?.pushViewController(controller, animated: true)
                            }
                            else if targetId!.hasPrefix("me.") {
								let controller = MessageDetailViewController()
								controller.inputMessageId = targetId
								self.navigationController?.pushViewController(controller, animated: true)
                            }
                        
                        case .Background:   // Shouldn't ever fire
                            precondition(false, "Notification controller should never get called when app state == background")
                    }
                }
            }
        }
    }
    
	func applicationDidBecomeActive(sender: NSNotification) {
		
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
	
	func initialize() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NotificationsTableViewController.didReceiveRemoteNotification(_:)), name: Events.DidReceiveRemoteNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NotificationsTableViewController.applicationDidBecomeActive(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
		self.view.accessibilityIdentifier = View.Notifications
		self.tableView.accessibilityIdentifier = Table.Notifications
	}
	
	override func getActivityDate() -> Int64 {
		return NotificationController.instance.activityDate
	}
    
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

	override func fetchQueryItems(force force: Bool, paging: Bool, queryDate: Int64?) {
        /* Always make sure we have the freshest sidecar data before a query */
        if let groupDefaults = NSUserDefaults(suiteName: "group.com.3meters.patchr.ios") {
            if let storedNearbys = groupDefaults.arrayForKey(PatchrUserDefaultKey("nearby.patches")) as? [[NSObject:AnyObject]] {
                self.nearbys = storedNearbys
            }
        }
		super.fetchQueryItems(force: force, paging: paging, queryDate: queryDate)
    }
	
	override func populateSidecar(query: Query) {
		query.sidecar = self.nearbys    // Should make a copy
	}
	
	func showNotificationBar(title: String, description: String, image: UIImage?, targetId: String, duration: CGFloat = 5.0) {
        
        TWMessageBarManager.sharedInstance().styleSheet = AirStylesheet(image: image)
		
        TWMessageBarManager.sharedInstance().showMessageWithTitle(title,
            description: description,
            type: TWMessageBarMessageType.Info,
            duration: duration) {
                
            if targetId.hasPrefix("me.") {
				let controller = MessageDetailViewController()
				controller.inputMessageId = targetId
				controller.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: controller, action: #selector(controller.dismissAction(_:)))
				UIViewController.topMostViewController()?.presentViewController(UINavigationController(rootViewController: controller), animated: true, completion: nil)
            }
            else if targetId.hasPrefix("pa.") {
				let controller = PatchDetailViewController()
				controller.entityId = targetId
				controller.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: controller, action: #selector(controller.dismissAction(_:)))
				UIViewController.topMostViewController()?.presentViewController(UINavigationController(rootViewController: controller), animated: true, completion: nil)
            }
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
	
	@objc func titleColorForMessageType(type: TWMessageBarMessageType) -> UIColor {
		return Colors.white
	}
	
	@objc func descriptionColorForMessageType(type: TWMessageBarMessageType) -> UIColor {
		return Colors.white
	}
	
    @objc func backgroundColorForMessageType(type: TWMessageBarMessageType) -> UIColor {
        return Theme.colorBackgroundNotification
    }
    
    @objc func strokeColorForMessageType(type: TWMessageBarMessageType) -> UIColor {
        return Theme.colorBackgroundNotification
    }
    
    @objc func iconImageForMessageType(type: TWMessageBarMessageType) -> UIImage {
        let image = self.image ?? UIImage(named: "imgMessageDark")
        return image!.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
    }
}

extension NotificationsTableViewController {
	/*
	* UITableViewDelegate
	*/
	override func bindCellToEntity(cell: WrapperTableViewCell, entity: AnyObject, location: CLLocation?) {
		super.bindCellToEntity(cell, entity: entity, location: location)
		if let view = cell.view as? NotificationView {
			view.description_?.delegate = self
		}
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		
		if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem,
			let entity = queryResult.object as? Notification {
				if entity.targetId!.hasPrefix("pa.") {
					let controller = PatchDetailViewController()
					controller.entityId = entity.targetId
					self.navigationController?.pushViewController(controller, animated: true)
				}
				else if entity.targetId!.hasPrefix("me.") {
					let controller = MessageDetailViewController()
					controller.inputMessageId = entity.targetId
					self.navigationController?.pushViewController(controller, animated: true)
				}
		}
	}
}