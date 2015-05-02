//
//  PatchTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-10.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class PatchTableViewController: QueryResultTableViewController {

    var selectedPatch: Patch?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerNib(UINib(nibName: "PatchTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
    }
    
    // TODO: consolidate the duplicated segue logic
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
        
        // The cell width seems to incorrect occassionally
        if CGRectGetWidth(cell.bounds) != CGRectGetWidth(self.tableView.bounds) {
            cell.bounds = CGRect(x: 0, y: 0, width: CGRectGetWidth(self.tableView.bounds), height: CGRectGetHeight(cell.frame))
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
        }
        
        let queryResult = object as! QueryResult
        let patch = queryResult.result as! Patch
        let patchCell = cell as! PatchTableViewCell
        patchCell.nameLabel.text = patch.name
        patchCell.categoryLabel.text = patch.category.name
        
        if let numberOfMessages = patch.numberOfMessages {
            patchCell.detailsLabel.text = "\(numberOfMessages) Messages"
        }
        
        if let numberOfWatchers = patch.numberOfWatchers {
            patchCell.detailsLabel.text = (patchCell.detailsLabel.text ?? "") + " \(numberOfWatchers) Watching"
        }
        
        patchCell.imageViewThumb.pa_setImageWithURL(patch.photo?.photoURL(), placeholder: UIImage(named: "PatchDefault"))
        patchCell.visibilityImageView.image = (patch.visibilityValue == PAVisibilityLevel.Private) ? UIImage(named: "TableViewCellLock") : nil
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryResult {
            if let patch = queryResult.result as? Patch {
                self.selectedPatch = patch
                self.performSegueWithIdentifier("PatchDetailSegue", sender: self)
                return
            }
        }
        assert(false, "Couldn't set selectedPatch")
    }
}

extension UIImageView {
    
    func pa_setImageWithURL(url: NSURL?, placeholder: UIImage?) {
        
        if url == nil {
            self.image = placeholder
            return
        }
        
        self.sd_setImageWithURL(url, placeholderImage: placeholder, completed: { (image, error, cacheType, url) -> Void in
            
            if error != nil {
                return
            }
            
            if cacheType == SDImageCacheType.None || cacheType == SDImageCacheType.Disk {
                // Animate if image wasn't cached
                UIView.transitionWithView(self, duration: 0.3, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: { () -> Void in
                    self.image = image;
                    }, completion: nil)
            } else {
                self.image = image
            }
            
        })
    }
    
    func pa_setImageWithURL(url: NSURL?) {
        self.pa_setImageWithURL(url, placeholder: nil)
    }
}