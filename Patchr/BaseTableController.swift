//
//  BaseViewController.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import FirebaseDatabaseUI
import FirebaseAuth

class BaseTableController: UIViewController {
    
    var handleAuth: FIRAuthStateDidChangeListenerHandle!
	
    var tableView = UITableView(frame: CGRect.zero, style: .plain)
    var queryController: DataSourceController!
    var activity = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    var controllerIsActive = false
    var statusBarHidden: Bool = false {
        didSet {
            UIView.animate(withDuration: 0.5) { () -> Void in
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    
    var presentedShallow: Bool {
        return self.presentingViewController?.presentedViewController == self
            || (self.navigationController?.presentingViewController?.presentedViewController == self.navigationController)
    }
    
	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.controllerIsActive = (UIApplication.shared.applicationState == .active)
    }
    
    override func viewWillLayoutSubviews() {
        let viewWidth = min(Config.contentWidthMax, self.view.width())
        self.view.anchorTopCenter(withTopPadding: 0, width: viewWidth, height: self.view.height())
    }
	
	/*--------------------------------------------------------------------------------------------
	* Notifications
	*--------------------------------------------------------------------------------------------*/
    
    func viewDidBecomeActive(sender: NSNotification) {
        /* User either switched to app, launched app, or turned their screen back on with app in foreground. */
        self.controllerIsActive = true
    }
    
    func viewWillResignActive(sender: NSNotification) {
        /* User either switched away from app or turned their screen off. */
        self.controllerIsActive = false
    }

	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	func initialize() {
        self.handleAuth = FIRAuth.auth()?.addStateDidChangeListener() { auth, user in
            if user == nil && self.queryController != nil {
                self.queryController.unbind()
            }
        }
        self.view.backgroundColor = Theme.colorBackgroundForm
        self.activity.color = Theme.colorActivityIndicator
        self.activity.hidesWhenStopped = true
        NotificationCenter.default.addObserver(self, selector: #selector(viewWillResignActive(sender:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(viewDidBecomeActive(sender:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
	}
	
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }
    
    override var prefersStatusBarHidden: Bool {
        return self.statusBarHidden
    }
	
	func dismissKeyboard(sender: NSNotification) {
		self.view.endEditing(true)
	}
    
    func emptyToNull(_ value: String?) -> NSObject {
        if value == nil || value!.isEmpty {
            return NSNull()
        }
        return (value! as NSString)
    }
	
    func emptyToNil(_ value: String?) -> String? {
        if value == nil || value!.isEmpty {
            return nil
        }
        return value
    }
    
	func nullToNil(_ value: AnyObject?) -> AnyObject? {
		if value is NSNull {
			return nil
		} else {
			return value
		}
	}
	
	func nilToNull(_ value: Any?) -> NSObject {
		if value == nil {
			return NSNull()
		} else {
			return value as! NSObject
		}
	}
	
	func stringsAreEqual(string1: String?, string2: String?) -> Bool {
		if isEmptyString(value: string1) != isEmptyString(value: string2) {
			/* We know one is empty and one is not */
			return false
		}
		else if !isEmptyString(value: string1) {
			/* Both have a value */
			return string1 == string2
		}
		return true // Both are empty
	}
	
	func isEmptyString(value : String?) -> Bool {
		return (value == nil || value!.isEmpty)
	}	
}

class DataSourceController: NSObject, FUICollectionDelegate, UITableViewDataSource {

    weak var delegate: FUICollectionDelegate?
    var tableView: UITableView!
    var name: String!
    
    var populate: ((UITableView, IndexPath, Any) -> UITableViewCell)!
    var matcher: ((String, Any) -> Bool)?
    var mapper: ((FIRDataSnapshot, @escaping ((Any?) -> Void)) -> Void)?
    
    var snapshots: FUIArray! // Contains snapshots
    private var dataScreened = [Any]() // Does NOT stay synchronized beyond initial pass
    private var dataFiltered = [Any]() // Pulls from active array
    
    var filterActive = false
    var mapperActive = false
    var startEmpty = false
    
    var items: [Any] {
        get {
            if self.startEmpty {
                return self.dataFiltered
            }
            else if self.mapperActive {
                return self.filterActive ? self.dataFiltered : self.dataScreened
            }
            else {
                return self.filterActive ? self.dataFiltered : self.snapshots.items
            }
        }
    }
    
    init(name: String) {
        self.name = name
        super.init()
    }

    func bind(to tableView: UITableView, populateCell: @escaping (UITableView, IndexPath, Any) -> UITableViewCell) {
        self.tableView = tableView
        self.populate = populateCell
        self.tableView.dataSource = self
    }
    
    func bind(to tableView: UITableView, query: FUIDataObservable, populateCell: @escaping (UITableView, IndexPath, Any) -> UITableViewCell) {
        self.tableView = tableView
        self.populate = populateCell
        self.tableView.dataSource = self
        self.snapshots = FUIArray(query: query)
        self.snapshots.delegate = self
        self.snapshots.observeQuery()
    }
    
    func unbind() {
        self.tableView.dataSource = nil
        self.tableView = nil
        self.snapshots?.invalidate()
    }
    
    func snapshot(at index: Int) -> FIRDataSnapshot {
        let item = self.items.at(index)
        return item as! FIRDataSnapshot
    }
    
    func filter(searchText text: String?) {
        guard self.matcher != nil else {
            fatalError("Filtering requires filterMatcher")
        }
        self.dataFiltered.removeAll()
        self.filterActive = false
        if text != nil {
            let items = (self.dataScreened.count > 0) ? self.dataScreened : self.snapshots.items
            for item in items {
                if self.matcher!(text!, item) {
                    self.dataFiltered.append(item)
                }
            }
            self.filterActive = true
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        return
    }
    
    func clearFilter() {
        self.dataFiltered.removeAll()
        self.filterActive = false
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = self.items.at(indexPath.row)
        let cell = self.populate(tableView, indexPath, data!)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = self.items.count
        return count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func arrayDidEndUpdates(_ collection: FUICollection) {
        if self.mapper != nil {
            self.dataScreened.removeAll()
            var remaining = self.snapshots.count
            for snap in self.snapshots.items {
                self.mapper!(snap as! FIRDataSnapshot) { any in
                    if any != nil {
                        self.dataScreened.append(any!)
                    }
                    remaining -= 1
                    if remaining == 0 {
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }

    func array(_ array: FUICollection, didAdd object: Any, at index: UInt) {
        if self.filterActive || self.mapperActive || self.startEmpty { return }
        self.tableView.insertRows(at: [IndexPath(row: Int(index), section: 0)], with: .automatic)
    }
    
    func array(_ array: FUICollection, didMove object: Any, from fromIndex: UInt, to toIndex: UInt) {
        if self.filterActive || self.mapperActive || self.startEmpty { return }
        self.tableView.moveRow(at: IndexPath(row: Int(fromIndex), section: 0), to: IndexPath(row: Int(toIndex), section: 0))
    }
    
    func array(_ array: FUICollection, didRemove object: Any, at index: UInt) {
        if self.filterActive || self.mapperActive || self.startEmpty { return }
        self.tableView.deleteRows(at: [IndexPath(row: Int(index), section: 0)], with: .automatic)
    }
    
    func array(_ array: FUICollection, didChange object: Any, at index: UInt) {
        if self.filterActive || self.mapperActive || self.startEmpty { return }
        self.tableView.reloadRows(at: [IndexPath(row: Int(index), section: 0)], with: .automatic)
        self.delegate?.array?(array, didChange: object, at: index)
    }
    
    func array(_ array: FUICollection, queryCancelledWithError error: Error) {
        self.delegate?.array?(array, queryCancelledWithError: error)
    }
}
