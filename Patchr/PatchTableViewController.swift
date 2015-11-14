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

    var user: User!
	var filter: PatchListFilter = .Nearby
    var activityDate: Int64?
	var location: CLLocation?
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        
        if user == nil {
            user = UserController.instance.currentUser
        }
        
		/* Strings */
		self.loadMoreMessage = "LOAD MORE PATCHES"
		self.listType = .Patches
		
        switch self.filter {
            case .Nearby:
                self.emptyMessage = "No patches nearby"
                self.activityDate = DataController.instance.activityDate
            case .Explore:
                self.emptyMessage = "Discover popular patches here"
            case .Watching:
                self.emptyMessage = "Watch patches and browse them here"
            case .Favorite:
                self.emptyMessage = "Browse your favorite patches here"
            case .Owns:
                self.emptyMessage = "Make patches and browse them here"
        }
        
        super.viewDidLoad()
		
		switch self.filter {
			case .Nearby:
				self.navigationItem.title = "Nearby"
			case .Explore:
				self.navigationItem.title = "Explore"
			case .Watching:
				self.navigationItem.title = "Patches I'm watching"
            case .Favorite:
                self.navigationItem.title = "Favorites"
			case .Owns:
				self.navigationItem.title = "Patches I own"
		}
		
		self.tableView.estimatedRowHeight = 136
		self.tableView.rowHeight = 136
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        switch self.filter {
            case .Nearby:
                setScreenName("NearbyList")
                registerForLocationNotifications()
                LocationController.instance.stopSignificantChangeUpdates()
                LocationController.instance.startUpdates()
            
            case .Explore:
                setScreenName("ExploreList")
            case .Watching:
                setScreenName("WatchingList")
            case .Favorite:
                setScreenName("FavoriteList")
            case .Owns:
                setScreenName("OwnsList")
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        if self.filter == .Nearby {
            /* We do this here so user can see the changes */
            if DataController.instance.activityDate > self.activityDate || !self.query().executedValue {
                self.bindQueryItems(true)
            }
        }
        else {
            super.viewDidAppear(animated)
			self.location = LocationController.instance.lastLocationFromManager()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        if self.filter == .Nearby {
            unregisterForLocationNotifications()
            LocationController.instance.stopUpdates()
            LocationController.instance.startSignificantChangeUpdates()
			if self._query != nil {
				DataController.instance.mainContext.refreshObject(self._query, mergeChanges: false)
			}
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
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        if let controller = storyboard.instantiateViewControllerWithIdentifier("PatchTableMapViewController") as? PatchTableMapViewController {
            controller.fetchRequest = self.fetchedResultsController.fetchRequest
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    override func query() -> Query {
        if self._query == nil {
			
			let id = "query.\(queryName().lowercaseString)"
			var query: Query? = Query.fetchOneById(id, inManagedObjectContext: DataController.instance.mainContext)
			
			if query == nil {
				query = Query.fetchOrInsertOneById(id, inManagedObjectContext: DataController.instance.mainContext) as Query
				
				switch self.filter {
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
				case .Favorite:
					query!.name = DataStoreQueryName.FavoritePatches.rawValue
					query!.pageSize = DataController.proxibase.pageSizeDefault
					query!.contextEntity = self.user
				case .Owns:
					query!.name = DataStoreQueryName.PatchesByUser.rawValue
					query!.pageSize = DataController.proxibase.pageSizeDefault
					query!.contextEntity = self.user
				}
				
				DataController.instance.saveContext(true)
			}
			
            self._query = query
        }
		
        return self._query!
    }
	
	func queryName() -> String {
		var queryName = "Generic"
		switch self.filter {
		case .Nearby:
			queryName = DataStoreQueryName.NearbyPatches.rawValue
		case .Explore:
			queryName = DataStoreQueryName.ExplorePatches.rawValue
		case .Watching:
			queryName = DataStoreQueryName.PatchesUserIsWatching.rawValue
		case .Favorite:
			queryName = DataStoreQueryName.FavoritePatches.rawValue
		case .Owns:
			queryName = DataStoreQueryName.PatchesByUser.rawValue
		}
		return queryName
	}
	
	override func bindQueryItems(force: Bool = false, paging: Bool = false) {
		
		if self.filter == .Nearby {
			if force {
				LocationController.instance.clearLastLocationAccepted()
				LocationController.instance.stopUpdates()
				LocationController.instance.startUpdates()
			}
			
			if !self.refreshControl!.refreshing {
				/* Wacky activity control for body */
				if self.showProgress {
					self.activity.startAnimating()
				}
			}
			
			if self.showEmptyLabel && self.emptyLabel.alpha > 0 {
				self.emptyLabel.fadeOut()
			}
		}
		else {
			if !paging {
				/* Might be fresher than the location we cached in didAppear */
				self.location = LocationController.instance.lastLocationFromManager()
			}
			super.bindQueryItems(force, paging: paging)
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
        
        if NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("devModeEnabled")) {
            Shared.Toast(message)
            AudioController.instance.play(Sound.pop.rawValue)
        }
        
        /*  Update location associated with this install */
        DataController.proxibase.updateProximity(loc){
            response, error in
			NSOperationQueue.mainQueue().addOperationWithBlock {
				if let error = ServerError(error) {
					Log.w("Error during updateProximity: \(error)")
				}
			}
        }
        
        Log.d(message)
        
        refreshForLocation()
    }
    
    func refreshForLocation() {
        
        if self.processingQuery {
            return
        }
        
        self.processingQuery = true
		
		let queryId = self.query().objectID
		
		DataController.instance.backgroundOperationQueue.addOperationWithBlock {
			Reporting.updateCrashKeys()
			
			DataController.instance.refreshItemsFor(queryId, force: false, paging: false, completion: {
				[weak self] results, query, error in
				/*
				 * Called on main thread
				 */
				NSOperationQueue.mainQueue().addOperationWithBlock {
					
					self?.processingQuery = false
					if let error = ServerError(error) {
						
						/* Always reset location after a network error */
						LocationController.instance.clearLastLocationAccepted()
						
						/* User credentials probably need to be refreshed */
						if error.code == ServerStatusCode.UNAUTHORIZED {
							let storyboard: UIStoryboard = UIStoryboard(name: "Lobby", bundle: NSBundle.mainBundle())
							let controller = storyboard.instantiateViewControllerWithIdentifier("LobbyNavigationController")
							self?.view.window?.setRootViewController(controller, animated: true)
						}
						
						self?.activity.stopAnimating()
						self?.refreshControl!.endRefreshing()
						
						return
					}
					
					self?.activityDate = DataController.instance.activityDate
					
					// Delay seems to be necessary to avoid visual glitch with UIRefreshControl
					Utils.delay(0.5) {
						
						let query = DataController.instance.mainContext.objectWithID(queryId) as! Query						
					
						/* Flag query as having been executed at least once */
						self?.activity.stopAnimating()
						self?.refreshControl!.endRefreshing()
						
						if let fetchedObjects = self?.fetchedResultsController.fetchedObjects as [AnyObject]? {
							if fetchedObjects.count == 0 {
								self?.emptyLabel.fadeIn()
							}
							else if NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("SoundEffects")) {
								if self!.showEmptyLabel && self?.emptyLabel.alpha > 0 {
									self?.emptyLabel.fadeOut()
								}
								if !query.executedValue {
									AudioController.instance.play(Sound.greeting.rawValue)
								}
							}
						}
						
						self?.query().executedValue = true
						DataController.instance.saveContext(false)
						
						return
					}
				}
			})
		}
    }
	
    func registerForLocationNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didUpdateLocation:",
            name: Event.LocationUpdate.rawValue, object: nil)
    }
	
    func unregisterForLocationNotifications(){
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: Event.LocationUpdate.rawValue, object: nil)
    }
}

/*--------------------------------------------------------------------------------------------
 * Extensions
 *--------------------------------------------------------------------------------------------*/

extension PatchTableViewController {
	/* 
	 * Cells
	 */
	override func bindCell(cell: AirTableViewCell, entity object: AnyObject, location: CLLocation?) -> UIView? {
		
		var location = self.location
		if self.filter == .Nearby || location == nil {
			location = LocationController.instance.lastLocationFromManager()
		}
		
		super.bindCell(cell, entity: object, location: location)
		
		return nil
	}
    /*
     * UITableViewDelegate
     */
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 136
	}

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
		if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem,
            let patch = queryResult.object as? Patch,
            let controller = storyboard.instantiateViewControllerWithIdentifier("PatchDetailViewController") as? PatchDetailViewController {
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
    case Favorite
    case Owns
}