//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation

class NavigationController: BaseTableViewController, UISearchBarDelegate {

    var filter: PatchListFilter!
    var selectedCell: WrapperTableViewCell?
    var lastContentOffset = CGFloat(0)
    var header: NavHeaderView!
    var searchActive = false

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func viewDidLoad() {

        guard self.filter != nil else {
            fatalError("Filter must be set on NavigationController")
        }

        /* Strings */
        self.loadMoreMessage = "LOAD MORE CHANNELS"
        self.listType = .Patches
        self.emptyMessage = "No channels yet"
        self.itemPadding = UIEdgeInsetsZero
        
        self.header = NavHeaderView()
        self.header.searchBar.delegate = self
        self.header.switchButton.addTarget(self, action: #selector(NavigationController.switchAction(_:)), forControlEvents: .TouchUpInside)

        self.tableView = AirTableView(frame: self.tableView.frame, style: .Grouped)
        
        self.header.searchBar.placeholder = "Filter"

        super.viewDidLoad()

        self.tableView.accessibilityIdentifier = Table.Patches
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.width())
        let viewHeight = CGFloat(112)
        self.tableView.tableHeaderView?.bounds.size = CGSizeMake(viewWidth, viewHeight)	// Triggers layoutSubviews on header
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)	// calls bind
        //bind()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
//        if getActivityDate() != self.query.activityDateValue {
//            fetchQueryItems(force: true, paging: false, queryDate: getActivityDate())
//        }
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchActive = true;
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }

    func addAction(sender: AnyObject?) {
        let controller = PatchEditViewController()
        let navController = AirNavigationController()
        controller.inputState = .Creating
        controller.inputType = "group"
        navController.viewControllers = [controller]
        self.presentViewController(navController, animated: true, completion: nil)
    }
    
    func switchAction(sender: AnyObject?) {
        UIShared.Toast("Show patch switching UI")
    }

    /*--------------------------------------------------------------------------------------------
    * Notifications
    *--------------------------------------------------------------------------------------------*/

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func bind() {
        self.header.name.text = "Massena Time"
        self.header.photo.bindPhoto(PhotoUtils.url("us.000000.00000.000.000001_20141218_205536.jpg", source: "aircandi.images", category: SizeCategory.thumbnail), name: "Massena Time")
        if self.tableView.tableHeaderView == nil {
            self.header.frame = CGRectMake(0, 0, self.tableView.width(), CGFloat(112))
            self.header.setNeedsLayout()
            self.header.layoutIfNeeded()
            self.tableView.tableHeaderView = self.header	// Triggers table binding
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        Log.d("Filter using: \(searchText)")
        searchActive = false;
    }
    
    override func getActivityDate() -> Int64 {
        return DataController.instance.activityDateWatching
    }

    override func loadQuery() -> Query {

        let id = queryId()
        var query: Query? = Query.fetchOneById(id, inManagedObjectContext: DataController.instance.mainContext)

        if query == nil {
            query = Query.fetchOrInsertOneById(id, inManagedObjectContext: DataController.instance.mainContext) as Query
            query!.name = DataStoreQueryName.PatchesUserIsWatching.rawValue
            query!.pageSize = DataController.proxibase.pageSizeDefault
            DataController.instance.saveContext(true)
        }

        return query!
    }

    func queryId() -> String {
        //        return "query.\(DataStoreQueryName.PatchesUserIsWatching.rawValue.lowercaseString).\(UserController.instance.userFire?.uid)"
        return "query.\(DataStoreQueryName.PatchesUserIsWatching.rawValue.lowercaseString).grbits"
    }
}

/*--------------------------------------------------------------------------------------------
 * Extensions
 *--------------------------------------------------------------------------------------------*/

extension NavigationController {
    /*
    * UITableViewDelegate
    */
    override func bindCellToEntity(cell: WrapperTableViewCell, entity: AnyObject, location: CLLocation?) {
        super.bindCellToEntity(cell, entity: entity, location: location)
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = ChannelSectionView()
        header.name.text = "Channels"
        header.addButton.addTarget(self, action: #selector(NavigationController.addAction(_:)), forControlEvents: .TouchUpInside)
        return header
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
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
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 40
    }
}