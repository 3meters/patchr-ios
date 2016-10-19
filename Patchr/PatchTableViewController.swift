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
    var filter: PatchListFilter!
    var cachedLocation: CLLocation?
    var locationServicesDisabled = false
    var greetingDidPlay = false
    // Has dialog been shown at least once
    var locationDialogShot = false
    var selectedCell: WrapperTableViewCell?
    var lastContentOffset = CGFloat(0)

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

        self.itemPadding = UIEdgeInsets.zero

        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(PatchTableViewController.applicationDidBecomeActive(sender:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        switch self.filter! {
            case .Nearby:
                Reporting.screen("NearbyList")
            case .Explore:
                Reporting.screen("ExploreList")
            case .Watching:
                Reporting.screen("JoinedList")
            case .Owns:
                Reporting.screen("OwnsList")
        }
    }

    override func viewDidAppear(_ animated: Bool) {

        if self.filter == .Nearby {
            /* Refresh data and ui to catch changes while gone */
            try! self.fetchedResultsController.performFetch()
            self.tableView.reloadData()

            registerForLocationNotifications()
            var level = Level.Background
            if CLLocationManager.locationServicesEnabled() && self.locationServicesDisabled {
                level = .Update
            }
            if getActivityDate() != self.query.activityDateValue {
                level = .Update
            }
            activateNearby(Level: level)
            self.firstAppearance = false
        }
        else {
            super.viewDidAppear(animated)
            self.cachedLocation = LocationController.instance.mostRecentAvailableLocation()
            if getActivityDate() != self.query.activityDateValue {
                fetchQueryItems(force: true, paging: false, queryDate: getActivityDate())
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
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
            super.pullToRefreshAction(sender: sender)
        }
    }

    func mapAction(sender: AnyObject?) {
        /* Called from dynamically generated segment controller */
        let controller = PatchTableMapViewController()
        controller.fetchRequest = self.fetchedResultsController.fetchRequest
        self.navigationController?.pushViewController(controller, animated: true)
    }

    func addAction(type: String) {
        let controller = PatchEditViewController()
        let navController = AirNavigationController()
        controller.inputState = .Creating
        controller.inputType = type
        navController.viewControllers = [controller]
        self.present(navController, animated: true, completion: nil)
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
        super.didFetchQuery(notification: notification)

        if self.filter == .Nearby {
            if let userInfo = notification.userInfo {
                if UserDefaults.standard.bool(forKey: PatchrUserDefaultKey(subKey: "SoundEffects")) {
                    if !self.greetingDidPlay && userInfo["count"] != nil && userInfo["count"] as! Int > 0 {
                        AudioController.instance.play(sound: Sound.greeting.rawValue)
                        Log.d("Play some sparkle!")
                        self.greetingDidPlay = true
                    }
                }
            }
        }
    }

    func locationWasUpdated(notification: NSNotification) {
        refreshForLocation()
    }

    func locationWasDenied(sender: NSNotification?) {

        self.emptyLabel.setTitle("Location Services disabled for Patchr", for: .normal)

        if !CLLocationManager.locationServicesEnabled() {
            self.emptyLabel.setTitle("Location Services turned off", for: .normal)
            self.locationServicesDisabled = true
        }
        else {
            self.emptyLabel.setTitleColor(Theme.colorButtonTitle, for: .normal)
            self.emptyLabel.addTarget(self, action: #selector(PatchTableViewController.presentPermissionAction(sender:)), for: .touchUpInside)
        }

        clearQueryItems()
        if self.showEmptyLabel && self.emptyLabel.alpha == 0 {
            self.emptyLabel.fadeIn()
        }
        self.refreshControl?.endRefreshing()
        self.activity.stopAnimating()
    }

    func locationWasAllowed(sender: NSNotification) {
        self.emptyLabel.setTitle(self.emptyMessage, for: .normal)
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
            viewDidAppear(true)
        }
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func makePopupView(image: UIImage, color: UIColor, size: Int) -> UIView {

        let imageView = UIImageView(image: image)
        imageView.tintColor = Colors.white

        let view = UIView(frame: CGRect(x:0, y:0, width:CGFloat(size), height: CGFloat(size)))
        view.addSubview(imageView)
        imageView.fillSuperview(withLeftPadding: 8, rightPadding: 8, topPadding: 8, bottomPadding: 8)

        view.backgroundColor = color

        view.layer.cornerRadius = view.frame.size.width / 2    // Round
        view.showShadow(rounded: true, cornerRadius: view.layer.cornerRadius)

        return view;
    }

    func presentLocationPermission(Force force: Bool = false) -> Bool {

        if CLLocationManager.authorizationStatus() == .denied {
            locationWasDenied(sender: nil)    // Configure UI
            if force || !self.locationDialogShot {
                UIShared.askToEnableLocationService()
                self.locationDialogShot = true
            }
            return false
        }
        else if CLLocationManager.authorizationStatus() == .notDetermined {
            if force || !self.locationDialogShot {
                LocationController.instance.guardedRequestAuthorization(message: nil)
            }
            self.locationDialogShot = true
        }
        return true
    }

    func activateNearby(Level level: Level) {

        if CLLocationManager.authorizationStatus() == .denied {
            locationWasDenied(sender: nil)    // Configure UI
            return
        }
        else if CLLocationManager.authorizationStatus() == .notDetermined {
            locationWasDenied(sender: nil)
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
            if CLLocationManager.authorizationStatus() == .restricted {
                self.refreshControl?.endRefreshing()
                UIShared.Toast(message: "Waiting for location...")
                return
            }

            /* We want a fresh location fix */
            if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
                LocationController.instance.startUpdates(force: true)
                if self.refreshControl == nil || !self.refreshControl!.isRefreshing {
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

        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            LocationController.instance.startUpdates(force: false)
        }

        /* Cleanup fallback in case we never get a location. */
        Utils.delay(10) {
            if self.refreshControl == nil || self.refreshControl!.isRefreshing {
                self.refreshControl?.endRefreshing()
            }
            /* Wacky activity control for body */
            if self.activity.isAnimating {
                self.activity.stopAnimating()
            }
        }
    }

    func deactivateNearby() {
        unregisterForLocationNotifications()
        LocationController.instance.stopUpdates()
    }

    override func getActivityDate() -> Int64 {
        switch self.filter! {
            case .Nearby:
                return DataController.instance.activityDateInsertDeletePatch
            case .Explore:
                return 1    // Causes one update only
            case .Watching:
                return DataController.instance.activityDateWatching
            case .Owns:
                return DataController.instance.activityDateInsertDeletePatch
        }
    }

    override func loadQuery() -> Query {

        let id = queryId()
        var query: Query? = Query.fetchOne(byId: id, in: DataController.instance.mainContext)

        if query == nil {
            query = Query.fetchOrInsertOne(byId: id, in: DataController.instance.mainContext) as Query

            switch self.filter! {
                case .Nearby:
                    query!.name = DataStoreQueryName.NearbyPatches.rawValue
                    query!.pageSize = DataController.proxibase.pageSizeNearby as NSNumber!
                case .Explore:
                    query!.name = DataStoreQueryName.ExplorePatches.rawValue
                    query!.pageSize = DataController.proxibase.pageSizeExplore as NSNumber!
                case .Watching:
                    query!.name = DataStoreQueryName.PatchesUserIsWatching.rawValue
                    query!.pageSize = DataController.proxibase.pageSizeDefault as NSNumber!
                    query!.contextEntity = self.user
                case .Owns:
                    query!.name = DataStoreQueryName.PatchesByUser.rawValue
                    query!.pageSize = DataController.proxibase.pageSizeDefault as NSNumber!
                    query!.contextEntity = self.user
            }

            DataController.instance.saveContext(wait: true)
        }

        return query!
    }

    func queryId() -> String {

        var queryId: String!
        switch self.filter! {
            case .Nearby:
                queryId = "query.\(DataStoreQueryName.NearbyPatches.rawValue.lowercased())"
            case .Explore:
                queryId = "query.\(DataStoreQueryName.ExplorePatches.rawValue.lowercased())"
            case .Watching:
                queryId = "query.\(DataStoreQueryName.PatchesUserIsWatching.rawValue.lowercased()).\(self.user.id_)"
            case .Owns:
                queryId = "query.\(DataStoreQueryName.PatchesByUser.rawValue.lowercased()).\(self.user.id_)"
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

        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.WillFetchQuery), object: self)

        let queryId = self.query.objectID

        DataController.instance.backgroundOperationQueue.addOperation {
            Reporting.updateCrashKeys()

            DataController.instance.refreshItemsFor(queryId: queryId!, force: false, paging: false, completion: {
                [weak self] results, query, error in
                /*
                 * Called on main thread
                 */
                OperationQueue.main.addOperation {
                    self?.refreshControl?.endRefreshing()

                    Utils.delay(0.5) {
                        self?.processingQuery = false
                        self?.activity.stopAnimating()
                        var userInfo: [AnyHashable: Any] = ["error": (error != nil)]

                        if let error = ServerError(error) {
                            /* Always reset location after a network error */
                            LocationController.instance.clearLastLocationAccepted()
                            self!.handleError(error)
                            return
                        }

                        if let fetchedObjects = self?.fetchedResultsController.fetchedObjects as [AnyObject]? {
                            userInfo["count"] = fetchedObjects.count
                        }

                        let query = DataController.instance.mainContext.object(with: queryId!) as! Query
                        query.executedValue = true
                        query.activityDateValue = (self?.getActivityDate())!

                        DataController.instance.saveContext(wait: BLOCKING)    // Enough to trigger table update

                        if self != nil {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.DidFetchQuery), object: self!, userInfo: userInfo)
                        }

                        return
                    }
                }
            })
        }
    }

    func registerForLocationNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(PatchTableViewController.locationWasDenied(sender:)), name: NSNotification.Name(rawValue: Events.LocationWasDenied), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PatchTableViewController.locationWasAllowed(sender:)), name: NSNotification.Name(rawValue: Events.LocationWasAllowed), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PatchTableViewController.locationWasUpdated(notification:)), name: NSNotification.Name(rawValue: Events.LocationWasUpdated), object: nil)
    }

    func unregisterForLocationNotifications() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Events.LocationWasDenied), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Events.LocationWasAllowed), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Events.LocationWasUpdated), object: nil)
    }
}

/*--------------------------------------------------------------------------------------------
 * Extensions
 *--------------------------------------------------------------------------------------------*/

extension PatchTableViewController: CKRadialMenuDelegate {
    func radialMenu(_ radialMenu: CKRadialMenu!, didSelectPopoutWithIndentifier identifier: String!) {
        self.addAction(type: identifier)
    }
}

extension PatchTableViewController {
    /*
    * UITableViewDelegate
    */
    override func bindCellToEntity(cell: WrapperTableViewCell, entity: AnyObject, location: CLLocation?) {

        var location = self.cachedLocation
        if self.filter == .Nearby || location == nil {
            if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
                location = LocationController.instance.mostRecentAvailableLocation()
            }
        }

        super.bindCellToEntity(cell: cell, entity: entity, location: location)
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

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
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
