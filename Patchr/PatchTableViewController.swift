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
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        
        if user == nil {
            user = UserController.instance.currentUser
        }
        
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
        
        /* Content view */
        self.contentViewName = (SCREEN_NARROW || self.filter != .Nearby) ? "PatchNormalView" : "PatchLargeView"
        
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
                self.bindQueryItems(force: true)
            }
        }
        else {
            super.viewDidAppear(animated)
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
            let query = Query.insertInManagedObjectContext(DataController.instance.managedObjectContext) as! Query
            
            switch self.filter {
            case .Nearby:
                query.name = DataStoreQueryName.NearbyPatches.rawValue
                query.pageSize = DataController.proxibase.pageSizeNearby
            case .Explore:
                query.name = DataStoreQueryName.ExplorePatches.rawValue
                query.pageSize = DataController.proxibase.pageSizeExplore
            case .Watching:
                query.name = DataStoreQueryName.PatchesUserIsWatching.rawValue
                query.pageSize = DataController.proxibase.pageSizeDefault
                query.parameters = ["entity": user]
            case .Favorite:
                query.name = DataStoreQueryName.FavoritePatches.rawValue
                query.pageSize = DataController.proxibase.pageSizeDefault
                query.parameters = ["entity": user]
            case .Owns:
                query.name = DataStoreQueryName.PatchesByUser.rawValue
                query.pageSize = DataController.proxibase.pageSizeDefault
                query.parameters = ["entity": user]
            }
            
            DataController.instance.managedObjectContext.save(nil)
            self._query = query
        }
        return self._query!
    }
    
    override func bindQueryItems(force: Bool = false, paging: Bool = false) {
        
        if self.filter == .Nearby {
            if force {
                LocationController.instance.clearLastLocationAccepted()
                LocationController.instance.stopUpdates()
                LocationController.instance.startUpdates()
            }
            
            if !self.refreshControl!.refreshing {
                self.progress?.show(true)
            }
            
            if self.showEmptyLabel && self.emptyLabel.alpha > 0 {
                self.emptyLabel.fadeOut()
            }
        }
        else {
            super.bindQueryItems(force: force, paging: paging)
        }
    }
    
    override func configureCell(cell: UITableViewCell) {
        
        cell.contentView.backgroundColor = Colors.windowColor
        
        let view = cell.contentView.viewWithTag(1) as! BaseView
        let views = Dictionary(dictionaryLiteral: ("view", view))
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-8-[view]-8-|", options: nil, metrics: nil, views: views)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-8-[view]|", options: nil, metrics: nil, views: views)
        
        cell.contentView.addConstraints(horizontalConstraints)
        cell.contentView.addConstraints(verticalConstraints)
        cell.contentView.setNeedsLayout()
    }
    
    override func bindCell(cell: UITableViewCell, object: AnyObject, tableView: UITableView?) {
        let view = cell.contentView.viewWithTag(1) as! BaseView
        Patch.bindView(view, object: object, tableView: tableView, sizingOnly: false)
    }
    
    func didUpdateLocation(notification: NSNotification) {
        
        let loc = notification.userInfo!["location"] as! CLLocation
        
        var eventDate = loc.timestamp
        var howRecent = abs(trunc(eventDate.timeIntervalSinceNow * 100) / 100)
        var lat = trunc(loc.coordinate.latitude * 100) / 100
        var lng = trunc(loc.coordinate.longitude * 100) / 100
        
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
            if let error = ServerError(error) {
                Log.w("Error during updateProximity: \(error)")
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
        Reporting.updateCrashKeys()
        
        DataController.instance.refreshItemsFor(query(), force: false, paging: false, completion: {
            [weak self] results, query, error in
            
            self?.processingQuery = false
            if let error = ServerError(error) {
                
                /* Always reset location after a network error */
                LocationController.instance.clearLastLocationAccepted()
                
                /* User credentials probably need to be refreshed */
                if error.code == ServerStatusCode.UNAUTHORIZED {
                    let storyboard: UIStoryboard = UIStoryboard(name: "Lobby", bundle: NSBundle.mainBundle())
                    if let controller = storyboard.instantiateViewControllerWithIdentifier("LobbyNavigationController") as? UIViewController {
                        self?.view.window?.setRootViewController(controller, animated: true)
                    }
                }
                
                self?.progress?.hide(true)
                self?.refreshControl!.endRefreshing()
                
                return
            }
            
            self?.activityDate = DataController.instance.activityDate
            
            // Delay seems to be necessary to avoid visual glitch with UIRefreshControl
            Utils.delay(0.5, closure: {
                
                /* Flag query as having been executed at least once */
                self?.progress?.hide(true)
                self?.refreshControl!.endRefreshing()
                
                if let fetchedObjects = self?.fetchedResultsController.fetchedObjects as [AnyObject]? {
                    if fetchedObjects.count == 0 {
                        self?.emptyLabel.fadeIn()
                    }
                    else if NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("SoundEffects")) {
                        if !query.executedValue {
                            AudioController.instance.play(Sound.greeting.rawValue)
                        }
                    }
                }
                
                self?.query().executedValue = true
                
                return
            })
        })
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

extension PatchTableViewController: UITableViewDelegate {

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
		if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem,
            let patch = queryResult.object as? Patch,
            let controller = storyboard.instantiateViewControllerWithIdentifier("PatchDetailViewController") as? PatchDetailViewController {
                controller.entityId = patch.id_
                self.navigationController?.pushViewController(controller, animated: true)
		}
        
        /* Cell won't show highlighting when navigating back to table view */
        if let cell = self.tableView.cellForRowAtIndexPath(indexPath) {
            cell.setHighlighted(false, animated: false)
            cell.setSelected(false, animated: false)
        }
	}
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var height: CGFloat = 136
        if self.filter == .Nearby && !SCREEN_NARROW {
            height = 159
        }
        return height
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var height: CGFloat = 136
        if self.filter == .Nearby && !SCREEN_NARROW {
            height = 159
        }
        return height
    }
}

enum PatchListFilter {
    case Nearby
    case Explore
    case Watching
    case Favorite
    case Owns
}