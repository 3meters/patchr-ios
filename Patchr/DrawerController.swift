//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseAuth

class DrawerController: BaseTableViewController, UISearchBarDelegate {

    var filter: PatchListFilter!
    var selectedCell: WrapperTableViewCell?
    var lastContentOffset = CGFloat(0)
    var header: MainDrawerHeaderView!
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
        self.itemPadding = UIEdgeInsets.zero
        
        self.header = MainDrawerHeaderView()
        self.header.searchBar.delegate = self
        self.header.switchButton.addTarget(self, action: #selector(DrawerController.switchAction(sender:)), for: .touchUpInside)

        self.tableView = AirTableView(frame: self.tableView.frame, style: .grouped)
        
        self.header.searchBar.placeholder = "Filter"
        
        let userId = FIRAuth.auth()?.currentUser?.uid
        
        FireController.instance.observe(path: "member-channels/\(userId!)", eventType: .childAdded, with: { snap in
        })

        super.viewDidLoad()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.width())
        let viewHeight = CGFloat(112)
        self.tableView.tableHeaderView?.bounds.size = CGSize(width:viewWidth, height:viewHeight)	// Triggers layoutSubviews on header
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)	// calls bind
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true;
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
    }

    func addAction(sender: AnyObject?) {
        let controller = PatchEditViewController()
        let navController = AirNavigationController()
        controller.inputState = .Creating
        controller.inputType = "group"
        navController.viewControllers = [controller]
        self.present(navController, animated: true, completion: nil)
    }
    
    func switchAction(sender: AnyObject?) {
        UIShared.Toast(message: "Show patch switching UI")
    }

    /*--------------------------------------------------------------------------------------------
    * Notifications
    *--------------------------------------------------------------------------------------------*/

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func bind() {
        self.header.name.text = "Massena Time"
        self.header.photo.bindPhoto(photoUrl: PhotoUtils.url(prefix: "us.000000.00000.000.000001_20141218_205536.jpg", source: "aircandi.images", category: SizeCategory.thumbnail), name: "Massena Time")
        if self.tableView.tableHeaderView == nil {
            self.header.frame = CGRect(x:0, y:0, width:self.tableView.width(), height:CGFloat(112))
            self.header.setNeedsLayout()
            self.header.layoutIfNeeded()
            self.tableView.tableHeaderView = self.header	// Triggers table binding
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        Log.d("Filter using: \(searchText)")
        searchActive = false;
    }
    
    override func getActivityDate() -> Int64 {
        return DataController.instance.activityDateWatching
    }

    override func loadQuery() -> Query {

        let id = queryId()
        var query: Query? = Query.fetchOne(byId: id, in: DataController.instance.mainContext)

        if query == nil {
            query = Query.fetchOrInsertOne(byId: id, in: DataController.instance.mainContext) as Query
            query!.name = DataStoreQueryName.PatchesUserIsWatching.rawValue
            query!.pageSize = DataController.proxibase.pageSizeDefault as NSNumber!
            DataController.instance.saveContext(wait: true)
        }

        return query!
    }

    func queryId() -> String {
        //        return "query.\(DataStoreQueryName.PatchesUserIsWatching.rawValue.lowercaseString).\(UserController.instance.userFire?.uid)"
        return "query.\(DataStoreQueryName.PatchesUserIsWatching.rawValue.lowercased()).grbits"
    }
}

/*--------------------------------------------------------------------------------------------
 * Extensions
 *--------------------------------------------------------------------------------------------*/

extension DrawerController {
    /*
    * UITableViewDelegate
    */
    override func bindCellToEntity(cell: WrapperTableViewCell, entity: AnyObject, location: CLLocation?) {
        super.bindCellToEntity(cell: cell, entity: entity, location: location)
    }
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = ChannelSectionView()
        header.name.text = "Channels"
        header.addButton.addTarget(self, action: #selector(DrawerController.addAction(sender:)), for: .touchUpInside)
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        /* Cell won't show highlighting when navigating back to table view */
        if let cell = self.tableView.cellForRow(at: indexPath) {
            self.selectedCell = cell as? WrapperTableViewCell
            cell.setHighlighted(false, animated: false)
            cell.setSelected(false, animated: false)
        }

        let queryResult = self.fetchedResultsController.object(at: indexPath)
        let patch = queryResult.object as? Patch
        let controller = PatchDetailViewController()
        controller.entityId = patch?.id_
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    override func numberOfSections(in: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
}
