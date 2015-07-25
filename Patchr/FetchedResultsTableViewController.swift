//
//  FetchedResultsTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-04.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class FetchedResultsTableViewController: UITableViewController {
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // While the tableView is off-screen, the visibile cells may have missed some calls to configureCell()
        if let visibleRowIndexPaths = self.tableView.indexPathsForVisibleRows() {
            self.tableView.reloadRowsAtIndexPaths(visibleRowIndexPaths, withRowAnimation: .None)
        }
        
        self.tableView.separatorInset = UIEdgeInsetsZero
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsControllerForViewController(self).sections!.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfObjects = self.fetchedResultsControllerForViewController(self).sections![section].numberOfObjects
        if numberOfObjects == 0 {
            // Don't show cell lines when there are no objects
            tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        } else {
            tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        }
        return numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // The reason for the self.tableView here is because of UISearchDisplayController.
        // There doesn't seem to be a nice way to register cells when using UISearchDisplayController,
        // so we just grab them from the original table.
        //let cell: UITableViewCell  = UITableViewCell()
        let cell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as! UITableViewCell
        cell.separatorInset = UIEdgeInsetsZero
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.mainScreen().scale
        
        if cell.respondsToSelector("layoutMargins") {
            cell.layoutMargins = UIEdgeInsetsZero
        }
        
        if cell.respondsToSelector("preservesSuperviewLayoutMargins") {
            cell.preservesSuperviewLayoutMargins = false
        }
        var object : AnyObject = self.fetchedResultsControllerForViewController(self).sections![indexPath.section].objects[indexPath.row]
        configureCell(cell, object: object)
        return cell
    }

    // Override this in subclasses to configure cells
    func configureCell(cell: UITableViewCell, object: AnyObject, sizingOnly: Bool = false) {
        cell.textLabel?.text = object.description
    }
    
}

extension FetchedResultsTableViewController: FetchedResultsViewControllerDataSource {
    /* Override this in subclasses so they have control of the fetch configuration */
    func fetchedResultsControllerForViewController(viewController: UIViewController) -> NSFetchedResultsController {
        return NSFetchedResultsController()
    }
}

protocol FetchedResultsViewControllerDataSource {
    func fetchedResultsControllerForViewController(viewController: UIViewController) -> NSFetchedResultsController
}

