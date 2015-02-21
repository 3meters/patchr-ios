//
//  MostPopularTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-29.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class ExploreTableViewController: QueryResultTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let query = Query.insertInManagedObjectContext(self.managedObjectContext) as Query
        query.name = "stats/to/patches/from/users mostPopular"
        query.limitValue = 25
        query.path = "stats/to/patches/from/users"
        self.managedObjectContext.save(nil)
        self.query = query
        dataStore.loadMoreResultsFor(self.query, completion: { (results, error) -> Void in
            NSLog("Default query fetch for tableview")
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.clearsSelectionOnViewWillAppear = false;
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow() {
            self.tableView.deselectRowAtIndexPath(selectedIndexPath, animated: animated)
        }
    }

    override func configureCell(cell: UITableViewCell, object: AnyObject) {
        if let queryResult = object as? QueryResult {
            if let patch = queryResult.entity_ as? Patch {
                cell.textLabel?.text = "\(patch.name) (\(patch.category.name))"
                if patch.count != nil {
                    cell.textLabel?.text = cell.textLabel?.text?.stringByAppendingString(" \(patch.count) watchers")
                }
            } else {
                cell.textLabel?.text = "Unknown QueryResult entity type"
            }
        } else {
            cell.textLabel?.text = "Object \(String.fromCString(object_getClassName(object)))"
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("PatchDetailSegue", sender: self)
    }

    @IBAction func unwindFromCreatePatch(segue: UIStoryboardSegue) {}
}
