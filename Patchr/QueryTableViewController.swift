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
        
        /* Hookup refresh control */
		let refreshControl = UIRefreshControl()
        refreshControl.tintColor = AirUi.brandColor
		refreshControl.addTarget(self, action: "pullToRefreshAction:", forControlEvents: UIControlEvents.ValueChanged)
		self.refreshControl = refreshControl
        
        /* Wacky activity control for body */
        progress = MBProgressHUD.showHUDAddedTo(UIApplication.sharedApplication().delegate?.window!, animated: true)
        progress!.mode = MBProgressHUDMode.Indeterminate
        progress!.square = true
        progress!.opacity = 0.0
        progress!.removeFromSuperViewOnHide = false
        progress!.userInteractionEnabled = false
        progress!.activityIndicatorColor = AirUi.brandColorDark
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
            refreshQueryItems()
        }
    }
    
	override func fetchedResultsControllerForViewController(viewController: UIViewController) -> NSFetchedResultsController {
		return fetchedResultsController
	}

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

	func pullToRefreshAction(sender: AnyObject?) -> Void {
        refreshQueryItems(force: true)
	}

    func refreshQueryItems(force: Bool = false, paging: Bool = false) {
        
        DataController.instance.refreshItemsFor(query(), force: force, paging: paging, completion: {
            (results, query, error) -> Void in
            
            // Delay seems to be necessary to avoid visual glitch with UIRefreshControl
            delay(0.5, {
                () -> () in
                self.refreshControl?.endRefreshing()
                self.progress!.hide(true)
                self.query().executedValue = true
                self.query().offsetValue = Int32(self.fetchedResultsController.fetchedObjects!.count)
                
                self.tableView.finishInfiniteScroll()
                if query.moreValue {
                    self.tableView.addInfiniteScrollWithHandler({(scrollView) -> Void in
                        self.refreshQueryItems(force: false, paging: true)
                    })
                }
                else {
                    self.tableView.removeInfiniteScroll()
                }
                return
            })
        })
    }
    
	@IBAction func unwindFromCreatePatch(segue: UIStoryboardSegue) {
        refreshQueryItems()
	}

	@IBAction func unwindFromDeletePatch(segue: UIStoryboardSegue) {
        //refreshQueryItems()
	}

    @IBAction func unwindFromPatchEdit(segue: UIStoryboardSegue) {
        refreshQueryItems()
    }
}

func delay(delay: Double, closure: () -> ()) {
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW
			, Int64(delay * Double(NSEC_PER_SEC)))
			, dispatch_get_main_queue()
			, closure)
}
