//
//  PatchTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-10.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation

class PatchTableViewController: BaseTableViewController {

    var user						: User!
	var filter						: PatchListFilter!
	var cachedLocation				: CLLocation?
	var locationServicesDisabled	= false
	var greetingDidPlay				= false
	var locationDialogShot			= false		// Has dialog been shown at least once
	var selectedCell				: WrapperTableViewCell?
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
	override func viewDidLoad() {
		
		guard self.filter != nil else {
			fatalError("Filter must be set on PatchTableViewController")
		}
		
		if self.user == nil {
			self.user = UserController.instance.currentUser
		}
		
		/* Strings */
		self.loadMoreMessage = "LOAD MORE PATCHES"
		self.listType = .Patches
		
		switch self.filter! {
		case .Nearby:
			self.emptyMessage = "No patches nearby"
		case .Explore:
			self.emptyMessage = "Discover popular patches here"
		case .Watching:
			self.emptyMessage = "Join patches and browse them here"
		case .Owns:
			self.emptyMessage = "Make patches and browse them here"
		}
		
		self.itemPadding = UIEdgeInsetsMake(8, 8, 0, 8)
		
		super.viewDidLoad()
		
		switch self.filter! {
		case .Nearby:
			self.navigationItem.title = "Nearby"
			self.view.accessibilityIdentifier = View.PatchesNearby
		case .Explore:
			self.navigationItem.title = "Explore"
			self.view.accessibilityIdentifier = View.PatchesExplore
		case .Watching:
			self.navigationItem.title = "Member of"
			self.view.accessibilityIdentifier = View.PatchesWatching
		case .Owns:
			self.navigationItem.title = "Owner of"
			self.view.accessibilityIdentifier = View.PatchesOwn
		}
		
		self.tableView.accessibilityIdentifier = Table.Patches
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PatchTableViewController.didReceiveRemoteNotification(_:)), name: Events.DidReceiveRemoteNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UIApplicationDelegate.applicationDidBecomeActive(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
	}
	
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        switch self.filter! {
            case .Nearby:
                setScreenName("NearbyList")
            case .Explore:
                setScreenName("ExploreList")
            case .Watching:
                setScreenName("JoinedList")
            case .Owns:
                setScreenName("OwnsList")
        }
    }

    override func viewDidAppear(animated: Bool) {

        if self.filter == .Nearby {
			registerForLocationNotifications()
			var level = Level.Background
			if CLLocationManager.locationServicesEnabled() && self.locationServicesDisabled {
				level = .Update
			}
			if getActivityDate() != self.query.activityDateValue {
				level = .Update
			}
			activateNearby(Level: level)
			if CLLocationManager.authorizationStatus() == .AuthorizedAlways {
				LocationController.instance.stopSignificantChangeUpdates()
			}
        }
		else {
			super.viewDidAppear(animated)
			self.cachedLocation = LocationController.instance.mostRecentAvailableLocation()
			if getActivityDate() != self.query.activityDateValue {
				fetchQueryItems(force: true, paging: false, queryDate: getActivityDate())
			}
		}
    }

    override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
        if self.filter == .Nearby {
			deactivateNearby()
        }
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

	override func pullToRefreshAction(sender: AnyObject?) -> Void {
		
		if self.filter == .Nearby {
			/* Returns true if ok to proceed */
			if presentLocationPermission() {
				activateNearby(Level: .Maximum)
			}
		}
		else {
			super.pullToRefreshAction(sender)
		}
	}

    func mapAction(sender: AnyObject?) {
        /* Called from dynamically generated segment controller */
		let controller = PatchTableMapViewController()
        controller.fetchRequest = self.fetchedResultsController.fetchRequest
        self.navigationController?.pushViewController(controller, animated: true)
    }

	func presentPermissionAction(sender: AnyObject?) {
		/* Returns true if ok to proceed */
		if presentLocationPermission(Force: true) {
			activateNearby(Level: .Maximum)
		}
	}

	/*--------------------------------------------------------------------------------------------
	* Notifications
	*--------------------------------------------------------------------------------------------*/
	
	override func didFetchQuery(notification: NSNotification) {
		super.didFetchQuery(notification)
		
		if self.filter == .Nearby {
			if let userInfo = notification.userInfo {
				if NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("SoundEffects")) {
					if !self.greetingDidPlay && userInfo["count"] as! Int > 0 {
						AudioController.instance.play(Sound.greeting.rawValue)
						self.greetingDidPlay = true
					}
				}
			}
		}
	}
	
	func locationWasUpdated(notification: NSNotification) {
		
		let loc = notification.userInfo!["location"] as! CLLocation
		
		/*  Update location associated with this install */
		if UserController.instance.authenticated {
			DataController.proxibase.updateProximity(loc){
				response, error in
				NSOperationQueue.mainQueue().addOperationWithBlock {
					if let _ = ServerError(error) {
						Log.w("Error during updateProximity")
					}
					else {
						Log.d("Install proximity updated because of accepted location")
					}
				}
			}
		}
		
		refreshForLocation()
	}
	
	func locationWasDenied(sender: NSNotification?) {
		
		self.emptyLabel.setTitle("Location Services disabled for Patchr", forState: .Normal)

		if !CLLocationManager.locationServicesEnabled() {
			self.emptyLabel.setTitle("Location Services turned off", forState: .Normal)
			self.locationServicesDisabled = true
		}
		else {
			self.emptyLabel.setTitleColor(Theme.colorButtonTitle, forState: .Normal)
			self.emptyLabel.addTarget(self, action: #selector(PatchTableViewController.presentPermissionAction(_:)), forControlEvents: .TouchUpInside)
		}
		
		clearQueryItems()
		if self.showEmptyLabel && self.emptyLabel.alpha == 0 {
			self.emptyLabel.fadeIn()
		}
		self.refreshControl?.endRefreshing()
		self.activity.stopAnimating()
	}
	
	func locationWasAllowed(sender: NSNotification) {
		self.emptyLabel.setTitle(self.emptyMessage, forState: .Normal)
		LocationController.instance.startUpdates(force: true)
	}
	
	func applicationDidBecomeActive(sender: NSNotification) {
		
		/* User either switched to patchr or turned their screen back on. */
		if self.tabBarController?.selectedViewController == self.navigationController
			&& self.navigationController?.topViewController == self
			&& self.filter == .Nearby
			&& !self.firstAppearance {
				/*
				* This view controller is currently visible. viewDidAppear does not
				* fire on its own when returning from Location settings so we do it.
				*/
				Log.d("Nearby became active")
				viewDidAppear(true)
		}
	}
	
	func didReceiveRemoteNotification(sender: NSNotification) {
		
		if self.filter == .Nearby {
			if let userInfo = sender.userInfo {
				if let trigger = userInfo["trigger"] as? String where trigger == "nearby" {
					if self.isViewLoaded() {
						self.pullToRefreshAction(self.refreshControl)
					}
				}
			}
		}
	}
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	func presentLocationPermission(Force force: Bool = false) -> Bool {
		
		if CLLocationManager.authorizationStatus() == .Denied {
			locationWasDenied(nil)	// Configure UI
			if force || !self.locationDialogShot {
				UIShared.askToEnableLocationService()
				self.locationDialogShot = true
			}
			return false
		}
		else if CLLocationManager.authorizationStatus() == .NotDetermined {
			if force || !self.locationDialogShot {
				LocationController.instance.guardedRequestAuthorization(nil)
			}
			self.locationDialogShot = true
		}
		return true
	}
	
	func activateNearby(Level level: Level) {
		
		if CLLocationManager.authorizationStatus() == .Denied {
			locationWasDenied(nil)	// Configure UI
			return
		}
		else if CLLocationManager.authorizationStatus() == .NotDetermined {
			locationWasDenied(nil)
		}
		/*
		* Be more aggressive about refreshing the nearby list. Always true on first load 
		* because date is initialized to now and only updated when user creates or deletes a patch.
		*/
		if level != .Background {
			/*
			* - Denied means that the user has specifically denied location service
			*	for Patchr.
			* - Restricted most likely means they have disabled location services for the
			*	device itself so all apps are hosed.
			* - Undetermined: User has not chosen anything yet. Could be fresh install
			*   or they may done a device wide reset on privacy and locations.
			*/
			if CLLocationManager.authorizationStatus() == .Restricted {
				self.refreshControl?.endRefreshing()
				UIShared.Toast("Waiting for location...")
				return
			}

			/* We want a fresh location fix */
			if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse
				|| CLLocationManager.authorizationStatus() == .AuthorizedAlways {
				
				LocationController.instance.startUpdates(force: true)
				if self.refreshControl == nil || !self.refreshControl!.refreshing {
					if self.showProgress {
						self.activity.startAnimating()
					}
				}
				else {
					self.activity.stopAnimating()
				}
				
				if self.showEmptyLabel && self.emptyLabel.alpha > 0 {
					self.emptyLabel.fadeOut()
				}
			}
		}
		
		if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse
			|| CLLocationManager.authorizationStatus() == .AuthorizedAlways {
			LocationController.instance.startUpdates(force: false)
		}
		
		/* Cleanup fallback in case we never get a location. */
		Utils.delay(10) {
			if self.refreshControl == nil || self.refreshControl!.refreshing {
				self.refreshControl?.endRefreshing()
			}
			/* Wacky activity control for body */
			if self.activity.isAnimating() {
				self.activity.stopAnimating()
			}
		}
	}
	
	func deactivateNearby() {
		unregisterForLocationNotifications()
		LocationController.instance.stopUpdates()
		if CLLocationManager.authorizationStatus() == .AuthorizedAlways {
			LocationController.instance.startSignificantChangeUpdates()
		}
	}
	
	override func getActivityDate() -> Int64 {
		switch self.filter! {
		case .Nearby:
			return DataController.instance.activityDateInsertDeletePatch
		case .Explore:
			return 1  	// Causes one update only
		case .Watching:
			return DataController.instance.activityDateWatching
		case .Owns:
			return DataController.instance.activityDateInsertDeletePatch
		}
	}
	
    override func loadQuery() -> Query {

		let id = queryId()
		var query: Query? = Query.fetchOneById(id, inManagedObjectContext: DataController.instance.mainContext)

		if query == nil {
			query = Query.fetchOrInsertOneById(id, inManagedObjectContext: DataController.instance.mainContext) as Query

			switch self.filter! {
			case .Nearby:
				query!.name = DataStoreQueryName.NearbyPatches.rawValue
				query!.pageSize = DataController.proxibase.pageSizeNearby
			case .Explore:
				query!.name = DataStoreQueryName.ExplorePatches.rawValue
				query!.pageSize = DataController.proxibase.pageSizeExplore
			case .Watching:
				query!.name = DataStoreQueryName.PatchesUserIsWatching.rawValue
				query!.pageSize = DataController.proxibase.pageSizeDefault
				query!.contextEntity = self.user
			case .Owns:
				query!.name = DataStoreQueryName.PatchesByUser.rawValue
				query!.pageSize = DataController.proxibase.pageSizeDefault
				query!.contextEntity = self.user
			}

			DataController.instance.saveContext(true)
		}

        return query!
    }
	
	func queryId() -> String {
		
		var queryId: String!
		switch self.filter! {
			case .Nearby:
				queryId = "query.\(DataStoreQueryName.NearbyPatches.rawValue.lowercaseString)"
			case .Explore:
				queryId = "query.\(DataStoreQueryName.ExplorePatches.rawValue.lowercaseString)"
			case .Watching:
				queryId = "query.\(DataStoreQueryName.PatchesUserIsWatching.rawValue.lowercaseString).\(self.user.id_)"
			case .Owns:
				queryId = "query.\(DataStoreQueryName.PatchesByUser.rawValue.lowercaseString).\(self.user.id_)"
		}
		
		guard queryId != nil else {
			fatalError("Unassigned query id")
		}
		
		return queryId
	}
	
    func refreshForLocation() {
        
        guard !self.processingQuery else {
            return
        }
        
        self.processingQuery = true
		
		NSNotificationCenter.defaultCenter().postNotificationName(Events.WillFetchQuery, object: self, userInfo: nil)
		
		let queryId = self.query.objectID
		
		DataController.instance.backgroundOperationQueue.addOperationWithBlock {
			Reporting.updateCrashKeys()
			
			DataController.instance.refreshItemsFor(queryId, force: false, paging: false, completion: {
				[weak self] results, query, error in
				/*
				 * Called on main thread
				 */
				NSOperationQueue.mainQueue().addOperationWithBlock {
					
					self?.refreshControl?.endRefreshing()
					
					Utils.delay(0.5) {
						
						self?.processingQuery = false
						self?.activity.stopAnimating()
						var userInfo: [NSObject:AnyObject] = ["error": (error != nil)]

						if let error = ServerError(error) {
							
							/* Always reset location after a network error */
							LocationController.instance.clearLastLocationAccepted()
							
							/* User credentials probably need to be refreshed */
							if error.code == ServerStatusCode.UNAUTHORIZED {								
								let navController = UINavigationController()
								navController.viewControllers = [LobbyViewController()]
								AppDelegate.appDelegate().window!.setRootViewController(navController, animated: true)
							}
							return
						}
						
						if let fetchedObjects = self?.fetchedResultsController.fetchedObjects as [AnyObject]? {
							userInfo["count"] = fetchedObjects.count
						}
						
						let query = DataController.instance.mainContext.objectWithID(queryId) as! Query
						query.executedValue = true
						query.activityDateValue = (self?.getActivityDate())!
						
						DataController.instance.saveContext(BLOCKING)	// Enough to trigger table update
						
						if self != nil {
							NSNotificationCenter.defaultCenter().postNotificationName(Events.DidFetchQuery, object: self!, userInfo: userInfo)
						}
						
						return
					}
				}
			})
		}
    }
	
    func registerForLocationNotifications() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PatchTableViewController.locationWasDenied(_:)), name: Events.LocationWasDenied, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PatchTableViewController.locationWasAllowed(_:)), name: Events.LocationWasAllowed, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PatchTableViewController.locationWasUpdated(_:)), name: Events.LocationWasUpdated, object: nil)
    }
	
    func unregisterForLocationNotifications(){
        NSNotificationCenter.defaultCenter().removeObserver(self, name: Events.LocationWasDenied, object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: Events.LocationWasAllowed, object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: Events.LocationWasUpdated, object: nil)
    }
}

/*--------------------------------------------------------------------------------------------
 * Extensions
 *--------------------------------------------------------------------------------------------*/

extension PatchTableViewController {
	/*
	* UITableViewDelegate
	*/
	override func bindCellToEntity(cell: WrapperTableViewCell, entity: AnyObject, location: CLLocation?) {
		
		var location = self.cachedLocation
		if self.filter == .Nearby || location == nil {
			if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse
				|| CLLocationManager.authorizationStatus() == .AuthorizedAlways {
				location = LocationController.instance.mostRecentAvailableLocation()
			}
		}
		
		super.bindCellToEntity(cell, entity: entity, location: location)
	}

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		
		/* Cell won't show highlighting when navigating back to table view */
		if let cell = self.tableView.cellForRowAtIndexPath(indexPath) {
			self.selectedCell = cell as? WrapperTableViewCell
			cell.setHighlighted(false, animated: false)
			cell.setSelected(false, animated: false)
		}
		
		if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem,
			let patch = queryResult.object as? Patch {
				let controller = PatchDetailViewController()
				controller.entityId = patch.id_
				self.navigationController?.pushViewController(controller, animated: true)
		}
	}
	
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 136
	}
}

enum Level {
	case Background
	case Update
	case Maximum
}

enum PatchListFilter {
    case Nearby
    case Explore
    case Watching
    case Owns
}