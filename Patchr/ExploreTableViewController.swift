//
//  MostPopularTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-29.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class ExploreTableViewController: QueryResultTableViewController {
    
    var selectedPatch: Patch?
    
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
        self.searchDisplayController?.searchResultsTableView.rowHeight = self.tableView.rowHeight
        self.searchDisplayController?.searchResultsTableView.estimatedRowHeight = self.tableView.estimatedRowHeight
        
        let query = Query.insertInManagedObjectContext(self.managedObjectContext) as Query
        query.name = "Explore patches"
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
    
    // TODO consolidate the duplicated segue logic
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == nil {
            return
        }
        
        switch segue.identifier! {
        case "PatchDetailSegue":
            if let patchDetailViewController = segue.destinationViewController as? PatchDetailViewController {
                patchDetailViewController.managedObjectContext = self.managedObjectContext
                patchDetailViewController.dataStore = self.dataStore
                patchDetailViewController.patch = self.selectedPatch
                self.selectedPatch = nil
            }
        case "MapViewSegue":
            if let mapViewController = segue.destinationViewController as? FetchedResultsMapViewController {
                mapViewController.managedObjectContext = self.managedObjectContext
                mapViewController.fetchRequest = self.fetchedResultsController.fetchRequest
            }
        default: ()
        }
    }

    override func configureCell(cell: UITableViewCell, object: AnyObject) {
        let queryResult = object as QueryResult
        let patch = queryResult.entity_ as Patch
        let patchCell = cell as PatchTableViewCell
        patchCell.nameLabel.text = patch.name
        patchCell.nameLabel.sizeToFit()
        patchCell.categoryLabel.text = patch.category.name
        patchCell.detailsLabel.text = "\(patch.numberOfMessages) Messages  \(patch.numberOfWatchers) Watching"
        patchCell.imageViewThumb.image = nil
        if patch.photo != nil && patch.photo.photoURL() != nil {
            patchCell.imageViewThumb.setImageWithURL(patch.photo.photoURL())
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryResult {
            if let patch = queryResult.entity_ as? Patch {
                self.selectedPatch = patch
                self.performSegueWithIdentifier("PatchDetailSegue", sender: self)
                return
            }
        }
        assert(false, "Couldn't set selectedPatch")
    }

    @IBAction func unwindFromCreatePatch(segue: UIStoryboardSegue) {}
}
