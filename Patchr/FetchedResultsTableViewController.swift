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
        
        var cell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER) as? UITableViewCell
        
        if cell == nil {
            cell = buildCell(self.contentViewName!)
            configureCell(cell!)    // Handles contraint and layout updates
        }

        /* Get the data object to bind the cell to */
        let queryResult = self.fetchedResultsControllerForViewController(self).sections![indexPath.section].objects[indexPath.row] as! QueryItem
        
        /* Bind the cell */
        bindCell(cell!, object: queryResult.object, tableView: tableView, sizingOnly: false)
        
        return cell!
    }
    
    func buildCell(contentViewName: String) -> UITableViewCell {
        
        let cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: CELL_IDENTIFIER)
        cell.separatorInset = UIEdgeInsetsZero
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.mainScreen().scale
        
        if cell.respondsToSelector("layoutMargins") {
            cell.layoutMargins = UIEdgeInsetsZero
        }
        
        if cell.respondsToSelector("preservesSuperviewLayoutMargins") {
            cell.preservesSuperviewLayoutMargins = false
        }
        
        var view = NSBundle.mainBundle().loadNibNamed(contentViewName, owner: self, options: nil)[0] as! BaseView
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
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: nil, metrics: nil, views: views)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: nil, metrics: nil, views: views)
        cell.contentView.addConstraints(horizontalConstraints)
        cell.contentView.addConstraints(verticalConstraints)
        
        cell.setNeedsUpdateConstraints()
        cell.updateConstraintsIfNeeded()
        cell.contentView.setNeedsLayout()
        cell.contentView.layoutIfNeeded()
    }
    
    // Override this in subclasses to bind cells to data
    func bindCell(cell: UITableViewCell, object: AnyObject, tableView: UITableView?, sizingOnly: Bool = false) {
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

