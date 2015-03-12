//
//  QueryResultTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-22.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class QueryResultTableViewController: FetchedResultsTableViewController {

    var managedObjectContext: NSManagedObjectContext!
    var dataStore: DataStore!
    
    private lazy var fetchControllerDelegate: FetchControllerDelegate = {
        return FetchControllerDelegate(tableView: self.tableView, self.configureCell)
    }()
    
    internal lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: QueryResult.entityName())
        
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: QueryResultAttributes.position, ascending: true),
            NSSortDescriptor(key: QueryResultAttributes.sortDate, ascending: false)
        ]
        fetchRequest.predicate = NSPredicate(format: "query == %@", self.query())
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        controller.performFetch(nil)
        controller.delegate = self.fetchControllerDelegate
        
        return controller
    }()
    
    override func fetchedResultsControllerForViewController(viewController: UIViewController) -> NSFetchedResultsController {
        return self.fetchedResultsController
    }
    
    internal func query() -> Query {
        assert(false, "This method must be overridden in subclass")
        return Query()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "pullToRefreshAction:", forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = refreshControl
        self.refreshControl?.beginRefreshing()
        self.pullToRefreshAction(self.refreshControl!)
    }
    
    func pullToRefreshAction(sender: AnyObject) -> Void {
        self.dataStore.refreshResultsFor(self.query(), completion: { (results, error) -> Void in
            // Delay seems to be necessary to avoid visual glitch with UIRefreshControl
            delay(0.1, { () -> () in
                self.refreshControl?.endRefreshing()
                return
            })
        })
    }
}

func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}
