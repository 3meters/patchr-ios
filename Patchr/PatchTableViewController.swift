//
//  PatchTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-10.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

enum PatchListFilter {
	case Nearby
	case Explore
	case Watching
	case Owns
}

class PatchTableViewController: QueryTableViewController {

    var user: User!
	var selectedPatch: Patch?
	var filter: PatchListFilter = .Nearby
    var activityDate: Int?
    
	private var _query: Query!

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
                case .Owns:
                    query.name = DataStoreQueryName.PatchesByUser.rawValue
                    query.pageSize = DataController.proxibase.pageSizeDefault
                    query.parameters = ["entity": user]
            }

			DataController.instance.managedObjectContext.save(nil)
			self._query = query
		}
		return self._query
	}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* A bit of UI tweaking */
        tableView.backgroundColor = AirUi.windowColor
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None;
        
        /* Add a little bit of room at the bottom of the table */
        var footer: UIView = UIView(frame:CGRectMake(0, 0, 1, 8))
        footer.backgroundColor = UIColor.clearColor()
        tableView.tableFooterView = footer;        

		switch self.filter {
			case .Nearby:
				self.navigationItem.title = "Nearby"
                self.tableView.registerNib(UINib(nibName: "PatchLargeTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
			case .Explore:
				self.navigationItem.title = "Explore"
                self.tableView.registerNib(UINib(nibName: "PatchNormalTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
				self.searchDisplayController?.searchResultsTableView.rowHeight = self.tableView.rowHeight
				self.searchDisplayController?.searchResultsTableView.estimatedRowHeight = self.tableView.estimatedRowHeight
				self.tableView.contentOffset = CGPointMake(0, self.searchDisplayController?.searchBar.frame.size.height ?? 0) // Sets search bar under nav bar initially
			case .Watching:
				self.navigationItem.title = "Patches I'm watching"
                self.tableView.registerNib(UINib(nibName: "PatchNormalTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
			case .Owns:
				self.navigationItem.title = "Patches I own"
                self.tableView.registerNib(UINib(nibName: "PatchNormalTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
		}
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        registerForAppNotifications()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForAppNotifications()
    }
    
    override func configureCell(cell: UITableViewCell, object: AnyObject) {
        
        // The cell width seems to incorrect occassionally
        if CGRectGetWidth(cell.bounds) != CGRectGetWidth(self.tableView.bounds) {
            cell.bounds = CGRect(x: 0, y: 0, width: CGRectGetWidth(self.tableView.bounds), height: CGRectGetHeight(cell.frame))
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
        }
        
        let queryResult = object as! QueryItem
        let patch = queryResult.object as! Patch
        let cell = cell as! PatchTableViewCell
        
        cell.name.text = patch.name
        if patch.type != nil {
            cell.type.text = patch.type.uppercaseString + " PATCH"
        }
        
        if cell.placeName != nil {
            cell.placeName.hidden = true
            cell.placeName.text = nil
            if patch.place != nil {
                cell.placeName.text = patch.place.name.uppercaseString
                cell.placeName.hidden = false
            }
        }
        
        if cell.visibility != nil {
            cell.visibility?.tintColor = AirUi.brandColor
            cell.visibility.hidden = (patch.visibility == "public")
        }
        
        if (cell.status != nil) {
            cell.status.hidden = true
            if (patch.userWatchStatusValue == .Pending) {
                cell.status.hidden = false
            }
        }
        
        if let numberOfMessages = patch.numberOfMessages {
            if cell.messageCount != nil {
                cell.messageCount.text = numberOfMessages.stringValue
            }
        }
        
        if let numberOfWatching = patch.countWatching {
            if cell.watchingCount != nil {
                cell.watchingCount.text = numberOfWatching.stringValue
            }
        }
        
        /* Distance */
        if cell.distance != nil {
            cell.distance.text = "--"
            if let currentLocation = LocationController.instance.getLocation() {
                if let loc = patch.location {
                    var patchLocation = CLLocation(latitude: loc.latValue, longitude: loc.lngValue)
                    let dist = Float(currentLocation.distanceFromLocation(patchLocation))  // in meters
                    cell.distance.text = LocationController.instance.distancePretty(dist)
                }
            }
        }
        
        /* Apply gradient to banner */
        if !(cell.photo.layer.sublayers[0] is CAGradientLayer) {
            var gradient: CAGradientLayer = CAGradientLayer()
            gradient.frame = cell.photo.bounds
            var startColor: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.2))  // Bottom
            var endColor:   UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0))    // Top
            gradient.colors = [endColor.CGColor, startColor.CGColor]
            gradient.startPoint = CGPoint(x: 0.5, y: 0.5)
            gradient.endPoint = CGPoint(x: 0.5, y: 1)
            cell.photo.layer.insertSublayer(gradient, atIndex: 0)
        }
        
        cell.photo.setImageWithPhoto(patch.getPhotoManaged(), animate: cell.photo.image == nil)
    }

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

		if segue.identifier == nil {
			return
		}

		switch segue.identifier! {
			case "PatchDetailSegue":
				if let controller = segue.destinationViewController as? PatchDetailViewController {
					controller.patch = self.selectedPatch
					self.selectedPatch = nil
				}
			case "MapViewSegue":
				if let controller = segue.destinationViewController as? FetchedResultsMapViewController {
					controller.fetchRequest = self.fetchedResultsController.fetchRequest
				}
			default: ()
		}
	}
    
    /*
    * We only get these callbacks if nearby is the current view controller.
    */
    func applicationDidEnterBackground() {
        /* User either switched away from patchr or turned their screen off. */
        println("Application entered background")
    }
    
    func applicationWillEnterForeground(){
        /* User either switched to patchr or turned their screen back on. */
        println("Application will enter foreground")
    }
    
    func registerForAppNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidEnterBackground",
            name: Event.ApplicationDidEnterBackground.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillEnterForeground",
            name: Event.ApplicationWillEnterForeground.rawValue, object: nil)
    }
    
    func unregisterForAppNotifications(){
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: Event.ApplicationDidEnterBackground.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: Event.ApplicationWillEnterForeground.rawValue, object: nil)
    }
}

/*--------------------------------------------------------------------------------------------
 * Extensions
 *--------------------------------------------------------------------------------------------*/

extension PatchTableViewController: UITableViewDelegate {

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem {
			if let patch = queryResult.object as? Patch {
				self.selectedPatch = patch
				self.performSegueWithIdentifier("PatchDetailSegue", sender: self)
				return
			}
		}
		assert(false, "Couldn't set selectedPatch")
	}
}
