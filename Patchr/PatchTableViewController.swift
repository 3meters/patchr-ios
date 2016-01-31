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

    var user				: User!
	var filter				: PatchListFilter!
	var location			: CLLocation?
	var firstNearPass		= true
	var greetingDidPlay		= false
	var locationDialogShot	= false
    
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
                self.emptyMessage = "Watch patches and browse them here"
            case .Owns:
                self.emptyMessage = "Make patches and browse them here"
        }
		
        super.viewDidLoad()
		
		switch self.filter! {
			case .Nearby:
				self.navigationItem.title = "Nearby"
				self.view.accessibilityIdentifier = View.PatchesNearby
			case .Explore:
				self.navigationItem.title = "Explore"
				self.view.accessibilityIdentifier = View.PatchesExplore
			case .Watching:
				self.navigationItem.title = "Patches watching"
				self.view.accessibilityIdentifier = View.PatchesWatching
			case .Owns:
				self.navigationItem.title = "Patches owned"
				self.view.accessibilityIdentifier = View.PatchesOwn
		}
		
		self.tableView.estimatedRowHeight = 136
		self.tableView.rowHeight = 136
		
		self.tableView.accessibilityIdentifier = Table.Patches
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleRemoteNotification:", name: PAApplicationDidReceiveRemoteNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "locationDenied", name: Events.LocationDenied, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "locationAllowed", name: Events.LocationAllowed, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidBecomeActive", name: Events.ApplicationDidBecomeActive, object: nil)
		
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        switch self.filter! {
            case .Nearby:
                setScreenName("NearbyList")
            case .Explore:
                setScreenName("ExploreList")
            case .Watching:
                setScreenName("WatchingList")
            case .Owns:
                setScreenName("OwnsList")
        }
    }
    
    override func viewDidAppear(animated: Bool) {
		
        if self.filter == .Nearby {
			
			registerForLocationNotifications()
			
			if CLLocationManager.authorizationStatus() == .Denied {
				locationDenied()
				if !self.locationDialogShot {
					UIShared.enableLocationService()
					self.locationDialogShot = true
				}
				return
			}
			
			if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
				LocationController.instance.stopSignificantChangeUpdates()
			}
			
			if CLLocationManager.authorizationStatus() == .NotDetermined {
				LocationController.instance.requestAuthorizationIfNeeded()
				self.locationDialogShot = true
			}
			
			/*
			* Always true on first load because date is initialized to now and only
			* updated when user creates or deletes a patch.
			*/
			if getActivityDate() != self.query.activityDateValue {
				self.fetchQueryItems(force: true, paging: false, queryDate: getActivityDate())
			}
			else {
				LocationController.instance.startUpdates()
			}
			
			self.firstNearPass = false
        }
		else {
			super.viewDidAppear(animated)
			self.location = LocationController.instance.lastLocationFromManager()
			if getActivityDate() != self.query.activityDateValue {
				self.fetchQueryItems(force: true, paging: false, queryDate: getActivityDate())
			}
		}
    }
    
    override func viewWillDisappear(animated: Bool) {
        if self.filter == .Nearby {
            unregisterForLocationNotifications()
            LocationController.instance.stopUpdates()
            LocationController.instance.startSignificantChangeUpdates()
        }
        else {
            super.viewWillDisappear(animated)
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    func mapAction(sender: AnyObject?) {
        /* Called from dynamically generated segment controller */
		let controller = PatchTableMapViewController()
        controller.fetchRequest = self.fetchedResultsController.fetchRequest
        self.navigationController?.pushViewController(controller, animated: true)
    }

	func handleRemoteNotification(notification: NSNotification) {
		
		if self.filter == .Nearby {
			if let userInfo = notification.userInfo {
				if let trigger = userInfo["trigger"] as? String where trigger == "nearby" {
					if self.isViewLoaded() {
						self.pullToRefreshAction(self.refreshControl)
					}
				}
			}
		}
	}

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
	
	func locationDenied() {
		self.emptyLabel.text = "Location Services disabled"
		if let fetchedObjects = self.fetchedResultsController.fetchedObjects as [AnyObject]? {
			if fetchedObjects.count == 0 {
				if self.showEmptyLabel && self.emptyLabel.alpha == 0 {
					self.emptyLabel.fadeIn()
				}
			}
		}
		self.refreshControl?.endRefreshing()
		self.activity.stopAnimating()
	}
	
	func locationAllowed() {
		self.emptyLabel.text = self.emptyMessage
		LocationController.instance.startUpdates()
	}
	
	func applicationDidBecomeActive() {
		/* User either switched to patchr or turned their screen back on. */
		if self.tabBarController?.selectedViewController == self.navigationController
			&& self.navigationController?.topViewController == self
			&& self.filter == .Nearby {
				/* 
				 * This view controller is currently visible. viewDidAppear does not
				 * fire on its own when returning from Location settings so we do it.
				 */
				Log.d("Nearby became active")
				viewDidAppear(true)
		}
	}
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
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
	
	override func fetchQueryItems(force force: Bool, paging: Bool, queryDate: Int64?) {
		
		if self.filter == .Nearby {
			/*
			 * - Denied means that the user has specifically denied location service
			 *	 for Patchr.
			 * - Restricted most likely means they have disabled location services for the
			 *	 device itself so all apps are hosed.
			 * - Undetermined: User has not chosen anything yet. Could be fresh install
			 *   or they may done a device wide reset on privacy and locations.
			 */
			if CLLocationManager.authorizationStatus() == .Restricted
				|| CLLocationManager.authorizationStatus() == .Denied {
					self.refreshControl?.endRefreshing()
					UIShared.Toast("Waiting for location...")
					return
			}
			
			if force {
				if LocationController.instance.lastLocationAccepted() != nil {
					if self.firstNearPass {
						LocationController.instance.resendLast()
					}
					else {
						Log.i("Clearing last location accepted")
						LocationController.instance.clearLastLocationAccepted()
					}
				}
				LocationController.instance.stopUpdates()
				LocationController.instance.startUpdates()
			}
			
			if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
				if self.refreshControl == nil || !self.refreshControl!.refreshing {
					/* Wacky activity control for body */
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
		else {
			if !paging {
				/* Might be fresher than the location we cached in didAppear */
				self.location = LocationController.instance.lastLocationFromManager()
			}
			super.fetchQueryItems(force: force, paging: paging, queryDate: queryDate)
		}
	}
	
    func didUpdateLocation(notification: NSNotification) {
        
        let loc = notification.userInfo!["location"] as! CLLocation
        
        let eventDate = loc.timestamp
        let howRecent = abs(trunc(eventDate.timeIntervalSinceNow * 100) / 100)
        let lat = trunc(loc.coordinate.latitude * 100) / 100
        let lng = trunc(loc.coordinate.longitude * 100) / 100
        
        var message = "Location accepted ***: lat: \(lat), lng: \(lng), acc: \(loc.horizontalAccuracy)m, age: \(howRecent)s"
        
        if let locOld = notification.userInfo!["locationOld"] as? CLLocation {
            let moved = Int(loc.distanceFromLocation(locOld))
            message = "Location accepted ***: lat: \(lat), lng: \(lng), acc: \(loc.horizontalAccuracy)m, age: \(howRecent)s, moved: \(moved)m"
        }
        
        if NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("enableDevModeAction")) {
            UIShared.Toast(message)
            AudioController.instance.play(Sound.pop.rawValue)
        }
        
        /*  Update location associated with this install */
		if UserController.instance.authenticated {
			DataController.proxibase.updateProximity(loc){
				response, error in
				NSOperationQueue.mainQueue().addOperationWithBlock {
					if let _ = ServerError(error) {
						Log.w("Error during updateProximity")
					}
					else {
						Log.w("Install proximity updated")
					}
				}
			}
		}
		
        Log.d(message)
        
        refreshForLocation()
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
								
								if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
									let navController = UINavigationController()
									navController.viewControllers = [LobbyViewController()]
									appDelegate.window!.setRootViewController(navController, animated: true)
								}
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didUpdateLocation:",
            name: Events.LocationUpdate, object: nil)
    }
	
    func unregisterForLocationNotifications(){
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: Events.LocationUpdate, object: nil)
    }
}

/*--------------------------------------------------------------------------------------------
 * Extensions
 *--------------------------------------------------------------------------------------------*/

extension PatchTableViewController {
	/* 
	 * Cells
	 */
	override func bindCellToEntity(cell: WrapperTableViewCell, entity: AnyObject, location: CLLocation?) {
		
		var location = self.location
		if self.filter == .Nearby || location == nil {
			if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
				location = LocationController.instance.lastLocationFromManager()
			}
		}
		
		super.bindCellToEntity(cell, entity: entity, location: location)
	}

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		
		if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem,
			let patch = queryResult.object as? Patch {
				let controller = PatchDetailViewController()
				controller.entityId = patch.id_
				controller.modalPresentationStyle = UIModalPresentationStyle.FullScreen
				controller.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
				showViewController(controller, sender: self)
		}
		
        /* Cell won't show highlighting when navigating back to table view */
        if let cell = self.tableView.cellForRowAtIndexPath(indexPath) {
            cell.setHighlighted(false, animated: false)
            cell.setSelected(false, animated: false)
        }
	}
}

enum PatchListFilter {
    case Nearby
    case Explore
    case Watching
    case Owns
}