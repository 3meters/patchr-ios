//
//  FetchedResultsTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-04.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class FetchedResultsTableViewController: UITableViewController {
    
    var contentViewName: String?

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let numberOfObjects = self.fetchedResultsControllerForViewController(self).sections![section].numberOfObjects
        self.tableView.separatorStyle = numberOfObjects == 0 ? .None : .SingleLine
        return numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER)
        
        if cell == nil {
            cell = buildCell(self.contentViewName!)
            configureCell(cell!)    // Handles contraint and layout updates
        }

        /* Get the data object to bind the cell to */
        let queryResult = self.fetchedResultsControllerForViewController(self).sections![indexPath.section].objects![indexPath.row] as! QueryItem
        
        /* Bind the cell */
        bindCell(cell!, object: queryResult.object, tableView: tableView)
        
        return cell!
    }
    
    func buildCell(contentViewName: String) -> UITableViewCell {
        
        let cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: CELL_IDENTIFIER)
        cell.separatorInset = UIEdgeInsetsZero
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.mainScreen().scale
        
        if #available(iOS 8.0, *) {
            cell.layoutMargins = UIEdgeInsetsZero
            cell.preservesSuperviewLayoutMargins = false
        }
        
        let view = NSBundle.mainBundle().loadNibNamed(contentViewName, owner: self, options: nil)[0] as! BaseView
        cell.injectView(view)
        
        /* We need to set the initial width so later sizing logic has it to work with */
        cell.frame = CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 100)
        cell.contentView.frame = CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 100)
        view.frame = CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 100)
        
        return cell
    }

    func configureCell(cell: UITableViewCell) {
        /*
         * Default is to constrain to a tight fit. Override this in subclasses to do
         * do something else. Without this the view size explodes.
         */
        let view = cell.contentView.viewWithTag(1) as! BaseView
        let views = Dictionary(dictionaryLiteral: ("view", view))
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: views)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: [], metrics: nil, views: views)
        cell.contentView.addConstraints(horizontalConstraints)
        cell.contentView.addConstraints(verticalConstraints)
        
        cell.setNeedsUpdateConstraints()
        cell.updateConstraintsIfNeeded()
        cell.contentView.setNeedsLayout()
        cell.contentView.layoutIfNeeded()
    }
    
    // Override this in subclasses to bind cells to data
    func bindCell(cell: UITableViewCell, object: AnyObject, tableView: UITableView?) {
        assert(false, "bindCell must be overridden by subclasses")
    }
}

/*--------------------------------------------------------------------------------------------
* Extensions
*--------------------------------------------------------------------------------------------*/

extension FetchedResultsTableViewController: FetchedResultsViewControllerDataSource {
    /* Override this in subclasses so they have control of the fetch configuration */
    func fetchedResultsControllerForViewController(viewController: UIViewController) -> NSFetchedResultsController {
        return NSFetchedResultsController()
    }
}

protocol FetchedResultsViewControllerDataSource {
    func fetchedResultsControllerForViewController(viewController: UIViewController) -> NSFetchedResultsController
}

