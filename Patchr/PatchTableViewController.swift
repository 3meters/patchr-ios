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
    case Favorite
	case Owns
}

class PatchTableViewController: QueryTableViewController {

    var user: User!
	var selectedPatch: Patch?
	var filter: PatchListFilter = .Nearby
    var activityDate: Int64?
    
	private var _query: Query?

    @IBOutlet weak var contentHolder: UIView!
    
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
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        
        switch self.filter {
            case .Nearby:
                self.emptyMessage = "No patches nearby"
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
        
        /* A bit of UI tweaking */
        self.tableView.backgroundColor = Colors.windowColor
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None;
        
		switch self.filter {
			case .Nearby:
				self.navigationItem.title = "Nearby"
			case .Explore:
				self.navigationItem.title = "Explore"
				self.searchDisplayController?.searchResultsTableView.rowHeight = self.tableView.rowHeight
				self.searchDisplayController?.searchResultsTableView.estimatedRowHeight = self.tableView.estimatedRowHeight
				self.tableView.contentOffset = CGPointMake(0, self.searchDisplayController?.searchBar.frame.size.height ?? 0) // Sets search bar under nav bar initially
			case .Watching:
				self.navigationItem.title = "Patches I'm watching"
            case .Favorite:
                self.navigationItem.title = "Favorites"
			case .Owns:
				self.navigationItem.title = "Patches I own"
		}
        
        /* Add a little bit of room at the bottom of the table */
        var footer: UIView = UIView(frame:CGRectMake(0, 0, 200, 8))
        footer.backgroundColor = UIColor.clearColor()
        self.tableView.tableFooterView = footer;
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        switch self.filter {
        case .Nearby:
            setScreenName("NearbyList")
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
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    func mapAction(sender: AnyObject?) {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("PatchTableMapViewController") as? PatchTableMapViewController
        controller!.fetchRequest = self.fetchedResultsController.fetchRequest
        self.navigationController?.pushViewController(controller!, animated: true)
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
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
				if let controller = segue.destinationViewController as? PatchTableMapViewController {
					controller.fetchRequest = self.fetchedResultsController.fetchRequest
				}
			default: ()
		}
	}    
}

/*--------------------------------------------------------------------------------------------
 * Extensions
 *--------------------------------------------------------------------------------------------*/

extension PatchTableViewController: UITableViewDelegate {

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem {
			if let patch = queryResult.object as? Patch {
                let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
                let controller = storyboard.instantiateViewControllerWithIdentifier("PatchDetailViewController") as? PatchDetailViewController
                controller!.patch = patch
                self.navigationController?.pushViewController(controller!, animated: true)
				return
			}
		}
		assert(false, "Couldn't set selectedPatch")
	}
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var height: CGFloat = 136
        if self.filter == .Nearby && !SCREEN_NARROW {
            height = 159
        }
        return height
    }
}