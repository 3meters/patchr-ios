//
//  NearbyPatchesTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-28.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class NearbyPatchesTableViewController: QueryResultTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerNib(UINib(nibName: "PatchTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        // iOS 7 doesn't support the new style self-sizing cells
        // http://stackoverflow.com/a/26283017/2247399
        if NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1 {
            self.tableView.rowHeight = UITableViewAutomaticDimension;
            self.tableView.estimatedRowHeight = 100.0;
        } else {
            // iOS 7
            self.tableView.rowHeight = 100
        }
        
        let query = Query.insertInManagedObjectContext(self.managedObjectContext) as Query
        query.name = "patches/near"
        query.limitValue = 25
        query.path = "patches/near"
        self.managedObjectContext.save(nil)
        self.query = query
        self.dataStore.loadMoreResultsFor(self.query, completion: { (results, error) -> Void in
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
    
    // TODO consolidate the duplicated segue logic
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == nil {
            return
        }
        
        switch segue.identifier! {
        case "PatchDetailSegue":
            if let queryResultTable = segue.destinationViewController as? QueryResultTableViewController {
                queryResultTable.managedObjectContext = self.managedObjectContext
                queryResultTable.dataStore = self.dataStore
            }
        default: ()
        }
    }

    override func configureCell(cell: UITableViewCell, object: AnyObject) {
        if let queryResult = object as? QueryResult {
            if let patch = queryResult.entity_ as? Patch {
                if let patchCell = cell as? PatchTableViewCell {
                    patchCell.nameLabel.text = patch.name
                    patchCell.nameLabel.sizeToFit()
                    patchCell.categoryLabel.text = patch.category.name
                    patchCell.detailsLabel.text = "\(patch.numberOfMessages) Messages  \(patch.numberOfWatchers) Watching"
                    patchCell.imageViewThumb.image = nil
                    if patch.photo != nil && patch.photo.photoURL() != nil {
                        patchCell.imageViewThumb.setImageWithURL(patch.photo.photoURL())
                    }
                } else {
                    cell.textLabel?.text = "\(patch.name)"
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
