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
    var query : Query!
    var dataStore: DataStore! // TODO move this somewhere else
    
    private lazy var fetchControllerDelegate: FetchControllerDelegate = {
        return FetchControllerDelegate(tableView: self.tableView, self.configureCell)
    }()
    
    internal lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: QueryResult.entityName())
        
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: QueryResultAttributes.position, ascending: true),
            NSSortDescriptor(key: QueryResultAttributes.sortDate, ascending: false)
        ]
        fetchRequest.predicate = NSPredicate(format: "query == %@", self.query)
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        controller.performFetch(nil)
        controller.delegate = self.fetchControllerDelegate
        
        return controller
    }()
    
    override func fetchedResultsControllerForViewController(viewController: UIViewController) -> NSFetchedResultsController {
        return self.fetchedResultsController
    }
}
