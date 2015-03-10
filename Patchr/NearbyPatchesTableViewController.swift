//
//  NearbyPatchesTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-28.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class NearbyPatchesTableViewController: QueryResultTableViewController {
    
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
        
        let query = Query.insertInManagedObjectContext(self.managedObjectContext) as Query
        query.name = "Nearby patches"
        self.managedObjectContext.save(nil)
        self.query = query
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "pullToRefreshAction:", forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = refreshControl
        self.refreshControl?.beginRefreshing()
        self.pullToRefreshAction(self.refreshControl!)
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
                mapViewController.dataStore = self.dataStore
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
    
    // MARK: Private Internal
    
    func pullToRefreshAction(sender: AnyObject) -> Void {
        self.dataStore.refreshResultsFor(self.query, completion: { (results, error) -> Void in
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
