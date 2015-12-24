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

    var user			: User!
	var filter			: PatchListFilter?
    var activityDate	: Int64?
	var location		: CLLocation?
	var firstNearPass	= true
    
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
                self.activityDate = DataController.instance.activityDateInsertDeletePatch
            case .Explore:
                self.emptyMessage = "Discover popular patches here"
            case .Watching:
                self.emptyMessage = "Watch patches and browse them here"
				self.activityDate = DataController.instance.activityDateWatching
            case .Owns:
                self.emptyMessage = "Make patches and browse them here"
				self.activityDate = DataController.instance.activityDateInsertDeletePatch
        }
		
        super.viewDidLoad()
		
		switch self.filter! {
			case .Nearby:
				self.navigationItem.title = "Nearby"
			case .Explore:
				self.navigationItem.title = "Explore"
			case .Watching:
				self.navigationItem.title = "Patches I'm watching"
			case .Owns:
				self.navigationItem.title = "Patches I own"
		}
		
		self.tableView.estimatedRowHeight = 136
		self.tableView.rowHeight = 136
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
			LocationController.instance.stopSignificantChangeUpdates()
			
            if DataController.instance.activityDateInsertDeletePatch > self.activityDate || !self.query.executedValue {
				/* We do this here so user can see the changes */
				self.activityDate = DataController.instance.activityDateInsertDeletePatch
                self.bindQueryItems(true)
            }
			else {
				LocationController.instance.startUpdates()
				if self.firstNearPass {
					if LocationController.instance.lastLocationAccepted() != nil {
						LocationController.instance.resendLast()
					}
				}
			}
			self.firstNearPass = false
        }
		else {
			super.viewDidAppear(animated)	// Will query if executed == false
			self.location = LocationController.instance.lastLocationFromManager()
			
			if self.filter == .Watching && self.query.executedValue {
				if DataController.instance.activityDateWatching > self.activityDate {
					self.activityDate = DataController.instance.activityDateWatching
					self.bindQueryItems(true, paging: false)
				}
			}
			else if self.filter == .Owns && self.query.executedValue {
				if DataController.instance.activityDateInsertDeletePatch > self.activityDate {
					self.activityDate = DataController.instance.activityDateInsertDeletePatch
					self.bindQueryItems(true, paging: false)
				}
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

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
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
	
	override func bindQueryItems(force: Bool = false, paging: Bool = false) {
		
		if self.filter == .Nearby {
			if force {
				if LocationController.instance.lastLocationAccepted() != nil {
					Log.i("Clearing last location accepted")
					LocationController.instance.clearLastLocationAccepted()
				}
				LocationController.instance.stopUpdates()
				LocationController.instance.startUpdates()
			}
			
			if !self.refreshControl!.refreshing {
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
        
        if NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("enableDevModeAction")) {
            Shared.Toast(message)
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
        
        if self.processingQuery {
            return
        }
        
        self.processingQuery = true
		
		let queryId = self.query.objectID
		
		DataController.instance.backgroundOperationQueue.addOperationWithBlock {
			Reporting.updateCrashKeys()
			
			DataController.instance.refreshItemsFor(queryId, force: false, paging: false, completion: {
				[weak self] results, query, error in
				/*
				 * Called on main thread
				 */
				NSOperationQueue.mainQueue().addOperationWithBlock {
					
					if let refreshControl = self?.refreshControl where refreshControl.refreshing {
						refreshControl.endRefreshing()
					}
					
					Utils.delay(0.5) {
						
						self?.processingQuery = false
						self?.activity.stopAnimating()

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

						let query = DataController.instance.mainContext.objectWithID(queryId) as! Query
						
						query.executedValue = true
						
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
						
						self?.activityDate = DataController.instance.activityDateInsertDeletePatch
						
						DataController.instance.saveContext(false)	// Enough to trigger table update
						
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
	override func bindCell(cell: WrapperTableViewCell, entity object: AnyObject, location: CLLocation?) -> UIView? {
		
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
		
		if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem,
			let entity = queryResult.object as? Patch {
				let view = PatchView()
				view.bindToEntity(entity, location: nil)
				view.sizeToFit()
				return view.bounds.size.height
		}
		return 0
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