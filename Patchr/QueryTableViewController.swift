//
//  QueryTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-22.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class QueryTableViewController: FetchedResultsTableViewController {
    
    var progress: MBProgressHUD?
    var showEmptyLabel: Bool = true
    var emptyLabel: AirLabel = AirLabel(frame: CGRectMake(100, 100, 100, 100))
    var emptyMessage: String?
    
	private lazy var fetchControllerDelegate: FetchControllerDelegate = {
		return FetchControllerDelegate(tableView: self.tableView, onUpdate: {
			[weak self] (cell, object) -> Void in
			return self?.configureCell(cell, object: object) ?? ()
		})
	}()

    /* Required override */
	internal lazy var fetchedResultsController: NSFetchedResultsController = {
        
		let fetchRequest = NSFetchRequest(entityName: QueryItem.entityName())
        
        let query: Query = self.query()
        
        if query.name == DataStoreQueryName.NearbyPatches.rawValue {
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "distance", ascending: true)
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

		controller.performFetch(nil)
		controller.delegate = self.fetchControllerDelegate

		return controller
	}()

	internal func query() -> Query {
		assert(false, "This method must be overridden in subclass")
		return Query()
	}

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
	override func viewDidLoad() {
		super.viewDidLoad()
        
        let window = UIApplication.sharedApplication().delegate?.window!
        
        /* Hookup refresh control */
		let refreshControl = UIRefreshControl()
        refreshControl.tintColor = Colors.brandColor
		refreshControl.addTarget(self, action: "pullToRefreshAction:", forControlEvents: UIControlEvents.ValueChanged)
		self.refreshControl = refreshControl
        
        /* Wacky activity control for body */
        progress = MBProgressHUD.showHUDAddedTo(window, animated: true)
        progress!.mode = MBProgressHUDMode.Indeterminate
        progress!.square = true
        progress!.opacity = 0.0
        progress!.removeFromSuperViewOnHide = true
        progress!.userInteractionEnabled = false
        progress!.activityIndicatorColor = Colors.brandColorDark
        progress!.show(true)
        
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
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
        
		clearsSelectionOnViewWillAppear = false;
		if let selectedIndexPath = tableView.indexPathForSelectedRow() {
			tableView.deselectRowAtIndexPath(selectedIndexPath, animated: animated)
		}
	}
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if !self.query().executedValue {
            self.refreshQueryItems(force: false)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.progress!.hide(false)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.refreshControl?.endRefreshing()
        self.tableView.finishInfiniteScroll()
    }
    
	override func fetchedResultsControllerForViewController(viewController: UIViewController) -> NSFetchedResultsController {
		return fetchedResultsController
	}

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

	func pullToRefreshAction(sender: AnyObject?) -> Void {
        self.refreshQueryItems(force: true)
	}

    func refreshQueryItems(force: Bool = false, paging: Bool = false) {
        
        if !self.query().executedValue {
            self.progress?.show(true)
        }
        
        if self.showEmptyLabel && self.emptyLabel.alpha > 0 {
            self.emptyLabel.fadeOut()
        }
        
        DataController.instance.refreshItemsFor(query(), force: force, paging: paging, completion: {
            [weak self] results, query, error in
            
            // Delay seems to be necessary to avoid visual glitch with UIRefreshControl
            delay(0.5, {
                () -> () in
                
                self?.refreshControl?.endRefreshing()
                self?.progress!.hide(true)
                self?.tableView.finishInfiniteScroll()
                
                if query.moreValue {
                    self?.tableView.addInfiniteScrollWithHandler({(scrollView) -> Void in
                        self?.refreshQueryItems(force: false, paging: true)
                    })
                }
                else {
                    self?.tableView.removeInfiniteScroll()
                }
                
                if let error = ServerError(error) {
                    self?.handleError(error)
                }
                else {
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
    
	@IBAction func unwindFromCreatePatch(segue: UIStoryboardSegue) {
        self.refreshQueryItems(force: false)
	}

    @IBAction func unwindFromPatchEdit(segue: UIStoryboardSegue) {
        self.refreshQueryItems(force: false)
    }
}

func delay(delay: Double, closure: () -> ()) {
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW
			, Int64(delay * Double(NSEC_PER_SEC)))
			, dispatch_get_main_queue()
			, closure)
}
