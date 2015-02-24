//
//  QueryResultTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-22.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class QueryResultTableViewController: UITableViewController {

    var managedObjectContext: NSManagedObjectContext!
    var query : Query!
    var dataStore: DataStore!
    
    lazy var sortDescriptors: [NSSortDescriptor] = {
        return [
            NSSortDescriptor(key: QueryResultAttributes.position, ascending: true),
            NSSortDescriptor(key: QueryResultAttributes.sortDate, ascending: false)
        ]
    }()
    
    private lazy var fetchControllerDelegate: FetchControllerDelegate = {
        
        let delegate = FetchControllerDelegate(tableView: self.tableView)
        delegate.onUpdate = {
            (cell: UITableViewCell, object: AnyObject) in
            self.configureCell(cell, object: object)
        }
        return delegate
    }()
    
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: QueryResult.entityName())
        
        fetchRequest.sortDescriptors = self.sortDescriptors
        fetchRequest.predicate = NSPredicate(format: "query == %@", self.query)
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        controller.performFetch(nil)
        controller.delegate = self.fetchControllerDelegate
        
        return controller
    }()
    
    // MARK: Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections!.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fetchedResultsController.sections![section].numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // The reason for the self.tableView here is because of UISearchDisplayController.
        // There doesn't seem to be a nice way to register cells when using UISearchDisplayController,
        // so we just grab them from the original table.
        let cell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell
        var object : AnyObject = self.fetchedResultsController.sections![indexPath.section].objects[indexPath.row]
        configureCell(cell, object: object)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, object: AnyObject) {
        cell.textLabel?.text = object.description        
    }
}
