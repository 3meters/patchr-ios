//
//  QueryTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-22.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class BaseTableViewController: FetchedResultsTableViewController {
    
    var _query: Query!
    var progress: AirProgress?
    var showEmptyLabel: Bool = true
    var showProgress: Bool = true
    var progressOffset = Float(0)
    var processingQuery: Bool = false
    var emptyLabel: AirLabel = AirLabel(frame: CGRectMake(100, 100, 100, 100))
    var emptyMessage: String?
    var offscreenCells:       NSMutableDictionary = NSMutableDictionary()
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
	override func viewDidLoad() {
		super.viewDidLoad()
        
        /* Hookup refresh control */
		let refreshControl = UIRefreshControl()
        refreshControl.tintColor = Colors.brandColor
		refreshControl.addTarget(self, action: "pullToRefreshAction:", forControlEvents: UIControlEvents.ValueChanged)
		self.refreshControl = refreshControl
        
        /* Wacky activity control for body */
        if self.showProgress {
            if let controller = UIViewController.topMostViewController() {
                self.progress = AirProgress.showHUDAddedTo(controller.view, animated: true)
                self.progress!.mode = MBProgressHUDMode.Indeterminate
                self.progress!.styleAs(.ActivityOnly)
                self.progress!.yOffset = self.progressOffset
                self.progress!.minShowTime = 1.0
                self.progress!.removeFromSuperViewOnHide = false
                self.progress!.userInteractionEnabled = false
            }
        }
        
        /* Empty label */
        if self.showEmptyLabel {
            self.emptyLabel.alpha = 0
            self.emptyLabel.layer.borderWidth = 1
            self.emptyLabel.layer.borderColor = Colors.hintColor.CGColor
            self.emptyLabel.font = UIFont(name: "HelveticaNeue-Light", size: 19)
            self.emptyLabel.text = self.emptyMessage
            self.emptyLabel.bounds.size.width = 160
            self.emptyLabel.bounds.size.height = 160
            self.emptyLabel.numberOfLines = 0
            
            self.view.addSubview(self.emptyLabel)
            
            self.emptyLabel.center = CGPointMake(UIScreen.mainScreen().bounds.size.width / 2, (UIScreen.mainScreen().bounds.size.height / 2) - 44);
            self.emptyLabel.textAlignment = NSTextAlignment.Center
            self.emptyLabel.textColor = UIColor(red: CGFloat(0.6), green: CGFloat(0.6), blue: CGFloat(0.6), alpha: CGFloat(1))
            self.emptyLabel.layer.backgroundColor = UIColor.whiteColor().CGColor
            self.emptyLabel.layer.cornerRadius = self.emptyLabel.bounds.size.width / 2
        }
        
        /* A bit of UI tweaking */
        self.tableView.backgroundColor = Colors.windowColor
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None;
        self.tableView.separatorInset = UIEdgeInsetsZero
        self.clearsSelectionOnViewWillAppear = false;
	}

	override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)  // Triggers data fetch
		if let indexPath = tableView.indexPathForSelectedRow() {
			tableView.deselectRowAtIndexPath(indexPath, animated: animated)
		}
	}
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if !self.query().executedValue {
            self.bindQueryItems(force: false)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.progress?.hide(false)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.progress?.hide(false)
        self.refreshControl?.endRefreshing()
        self.tableView.finishInfiniteScroll()
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    @IBAction func unwindFromCreatePatch(segue: UIStoryboardSegue) {
        self.bindQueryItems(force: false, paging: false)
    }
    
    @IBAction func unwindFromPatchEdit(segue: UIStoryboardSegue) {
        self.bindQueryItems(force: false, paging: false)
    }
    
    func pullToRefreshAction(sender: AnyObject?) -> Void {
        self.bindQueryItems(force: true, paging: false)
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    internal func query() -> Query {
        assert(false, "This method must be overridden in subclass")
        return Query()
    }
    
    override func fetchedResultsControllerForViewController(viewController: UIViewController) -> NSFetchedResultsController {
        return fetchedResultsController
    }
    
    func bindQueryItems(force: Bool = false, paging: Bool = false) {
        
        if self.processingQuery {
            return
        }
        
        if !self.refreshControl!.refreshing && !self.query().executedValue {
            self.progress?.show(true)
        }
        
        if self.showEmptyLabel && self.emptyLabel.alpha > 0 {
            self.emptyLabel.fadeOut()
        }
        
        /*
         * Check to see of any subclass wants to inject using the sidecar. Currently
         * used to add locally cached nearby notifications.
         */
        if !paging {
            populateSidecar(query())
        }
        
        self.processingQuery = true
        
        DataController.instance.refreshItemsFor(query(), force: force, paging: paging, completion: {
            [weak self] results, query, error in
            
            // Delay seems to be necessary to avoid visual glitch with UIRefreshControl
            Utils.delay(0.5, closure: {
                
                self?.processingQuery = false
                self?.progress?.hide(true)
                self?.refreshControl?.endRefreshing()
                self?.tableView.finishInfiniteScroll()
                
                if query.moreValue {
                    self?.tableView.addInfiniteScrollWithHandler({(scrollView) -> Void in
                        self?.bindQueryItems(force: false, paging: true)
                    })
                }
                else {
                    self?.tableView.removeInfiniteScroll()
                }
                
                if error == nil {
                    self?.query().executedValue = true
                    if let fetchedObjects = self?.fetchedResultsController.fetchedObjects as [AnyObject]? {
                        self?.query().offsetValue = Int32(fetchedObjects.count)
                        if self?.emptyLabel != nil && fetchedObjects.count == 0 {
                            self?.emptyLabel.fadeIn()
                        }
                    }
                }
                return
            })
        })
    }
    
    func populateSidecar(query: Query) { }
    
    private lazy var fetchControllerDelegate: FetchControllerDelegate = {
        return FetchControllerDelegate(tableView: self.tableView, onUpdate: {
            [weak self] (cell, object) -> Void in
            let queryResult = object as! QueryItem
            return self?.bindCell(cell, object: queryResult.object, tableView: nil) ?? ()
        })
    }()
    
    /* 
     * Creates controller instance first time the field is accessed.
     */
    internal lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: QueryItem.entityName())
        
        let query: Query = self.query()
        
        if query.name == DataStoreQueryName.NearbyPatches.rawValue {
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "distance", ascending: true)
            ]
        }
        else if query.name == DataStoreQueryName.NotificationsForCurrentUser.rawValue {
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "sortDate", ascending: false)
            ]
        }
        else {
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "position", ascending: true),
                NSSortDescriptor(key: "sortDate", ascending: false)
            ]
        }
        
        fetchRequest.predicate = NSPredicate(format: "query == %@", query)
        
        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: DataController.instance.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        controller.performFetch(nil) // Ensure that the controller can be accessed without blowing up
        controller.delegate = self.fetchControllerDelegate
        
        return controller
    }()
}