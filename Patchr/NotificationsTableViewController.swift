//
//  NotificationsTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-27.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
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
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Reporting.screen("NotificationList")
    }
    
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		/*
		 * A stashed notification date means a notification came in while
		 * the app was closed.
		 */
		if let _ = UserDefaults.standard.value(forKey: PatchrUserDefaultKey(subKey: "notificationDate")) {
			UserDefaults.standard.set(nil, forKey: PatchrUserDefaultKey(subKey: "notificationDate"))
		}
		
		if getActivityDate() != self.query.activityDateValue {
			self.fetchQueryItems(force: true, paging: false, queryDate: getActivityDate())
		}

        clearBadges()
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    /*--------------------------------------------------------------------------------------------
     * Notifications
     *--------------------------------------------------------------------------------------------*/
    
    func didReceiveRemoteNotification(notification: NSNotification) {
        if self.isViewLoaded {
            if self.tabBarController?.selectedViewController == self.navigationController
                && self.navigationController?.topViewController == self {
                if getActivityDate() != self.query.activityDateValue {
                    self.pullToRefreshAction(sender: self.refreshControl)
                }
            }
        }
    }
    
	func applicationDidBecomeActive(sender: NSNotification) {
        /* User either switched to patchr or turned their screen back on. */
        Log.d("Notifications tab: application did become active")
        if self.tabBarController?.selectedViewController == self.navigationController
            && self.navigationController?.topViewController == self {
                /* This view controller is currently visible. Clear the stinkin' badges! */
                clearBadges()
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		NotificationCenter.default.addObserver(self, selector: #selector(NotificationsTableViewController.didReceiveRemoteNotification(notification:)), name: NSNotification.Name(rawValue: Events.DidReceiveRemoteNotification), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(NotificationsTableViewController.applicationDidBecomeActive(sender:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        _ = NotificationController.instance.badgeNumber.subscribe(onNext: { [unowned self] (badgeNumber) in
            self.navigationController?.tabBarItem.badgeValue = badgeNumber > 0 ? String(badgeNumber) : nil
        })
	}
	
	override func getActivityDate() -> Int64 {
		return NotificationController.instance.activityDate
	}
    
    override func loadQuery() -> Query {
		
        let id = queryId()
        var query: Query? = Query.fetchOne(byId: id, in: DataController.instance.mainContext)

        if query == nil {
            query = Query.fetchOrInsertOne(byId: id, in: DataController.instance.mainContext) as Query
            query!.name = DataStoreQueryName.NotificationsForCurrentUser.rawValue
            query!.pageSize = DataController.proxibase.pageSizeNotifications as NSNumber!
            DataController.instance.saveContext(wait: true)	// Blocks until finished
        }
			
        return query!
    }
	
	func queryId() -> String {
		return "query.\(DataStoreQueryName.NotificationsForCurrentUser.rawValue.lowercased())"
	}

	override func fetchQueryItems(force: Bool, paging: Bool, queryDate: Int64?) {
        /* Always make sure we have the freshest sidecar data before a query */
        if let groupDefaults = UserDefaults(suiteName: "group.com.3meters.patchr.ios") {
            if let storedNearbys = groupDefaults.array(forKey: PatchrUserDefaultKey(subKey: "nearby.patches")) as? [[NSObject:AnyObject]] {
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
		
        TWMessageBarManager.sharedInstance().showMessage(withTitle: title,
            description: description,
            type: TWMessageBarMessageType.info,
            duration: duration) {
                
            if targetId.hasPrefix("me.") {
				let controller = MessageDetailViewController()
				controller.inputMessageId = targetId
				controller.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: controller, action: #selector(controller.dismissAction(sender:)))
				UIViewController.topMostViewController()?.present(UINavigationController(rootViewController: controller), animated: true, completion: nil)
            }
            else if targetId.hasPrefix("pa.") {
				let controller = PatchDetailViewController()
				controller.entityId = targetId
				controller.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: controller, action: #selector(controller.dismissAction(sender:)))
				UIViewController.topMostViewController()?.present(UINavigationController(rootViewController: controller), animated: true, completion: nil)
            }
        }
    }
	
    func notificationEnabledFor(trigger: String, description: String) -> Bool {
        if trigger == "nearby" {
            return UserDefaults.standard.bool(forKey: PatchrUserDefaultKey(subKey: "PatchesCreatedNearby"))
        }
        else if trigger == "watch_to" {
            return UserDefaults.standard.bool(forKey: PatchrUserDefaultKey(subKey: "MessagesForPatchesWatching"))
        }
        else if trigger == "own_to" {
            /* Super hack to differentiate likes from favorites */
            if description.contains("like") {
                return UserDefaults.standard.bool(forKey: PatchrUserDefaultKey(subKey: "LikeMessage"))
            }
            else if description.contains("favorite") {
                return UserDefaults.standard.bool(forKey: PatchrUserDefaultKey(subKey: "LikePatch"))
            }
        }
        else if trigger == "share" {
            return UserDefaults.standard.bool(forKey: PatchrUserDefaultKey(subKey: "MessagesSharing"))
        }
        return true
    }
	
    func clearBadges() {
        NotificationController.instance.clearBadgeNumber()
    }
}

class AirStylesheet: NSObject, TWMessageBarStyleSheet {
	
    var image: UIImage?
    
    init(image: UIImage?) {
        if image != nil {
            self.image = image
        }
    }
	
	@objc func titleColor(for type: TWMessageBarMessageType) -> UIColor {
		return Colors.white
	}
	
	@objc func descriptionColor(for type: TWMessageBarMessageType) -> UIColor {
		return Colors.white
	}
	
    @objc func backgroundColor(for type: TWMessageBarMessageType) -> UIColor {
        return Theme.colorBackgroundNotification
    }
    
    @objc func strokeColor(for type: TWMessageBarMessageType) -> UIColor {
        return Theme.colorBackgroundNotification
    }
    
    @objc func iconImage(for type: TWMessageBarMessageType) -> UIImage {
        let image = self.image ?? UIImage(named: "imgMessageDark")
        return image!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
    }
}

extension NotificationsTableViewController {
	/*
	* UITableViewDelegate
	*/
	override func bindCellToEntity(cell: WrapperTableViewCell, entity: AnyObject, location: CLLocation?) {
		super.bindCellToEntity(cell: cell, entity: entity, location: location)
		if let view = cell.view as? NotificationView {
			view.description_?.delegate = self
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		let queryResult = self.fetchedResultsController.object(at: indexPath)
        let entity = queryResult.object as? FeedItem
        if (entity?.targetId!.hasPrefix("pa."))! {
            let controller = PatchDetailViewController()
            controller.entityId = entity?.targetId
            self.navigationController?.pushViewController(controller, animated: true)
        }
        else if (entity?.targetId!.hasPrefix("me."))! {
            let controller = MessageDetailViewController()
            controller.inputMessageId = entity?.targetId
            self.navigationController?.pushViewController(controller, animated: true)
        }
	}
}
