//
//  NotificationsTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-27.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class NotificationsTableViewController: QueryResultTableViewController, NotificationTableViewCellDelegate {
    
    private var selectedDetailImage: UIImage?
    
    private var _query: Query!
    override func query() -> Query {
        if self._query == nil {
            let query = Query.insertInManagedObjectContext(self.managedObjectContext) as Query
            query.name = "Notifications for current user"
            self.managedObjectContext.save(nil)
            self._query = query
        }
        return self._query
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerNib(UINib(nibName: "NotificationTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        // TODO: consolidate this workaround across the table view controllers
        // iOS 7 doesn't support the new style self-sizing cells
        // http://stackoverflow.com/a/26283017/2247399
        if NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1 {
            self.tableView.rowHeight = UITableViewAutomaticDimension;
            self.tableView.estimatedRowHeight = 100.0;
        } else {
            // iOS 7
            self.tableView.rowHeight = 100
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.clearsSelectionOnViewWillAppear = false;
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow() {
            self.tableView.deselectRowAtIndexPath(selectedIndexPath, animated: animated)
        }
    }
    
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
        case "ImageDetailSegue":
            if let imageDetailViewController = segue.destinationViewController as? ImageDetailViewController {
                imageDetailViewController.image = self.selectedDetailImage
                self.selectedDetailImage = nil
            }
        default: ()
        }
    }
    
    override func configureCell(cell: UITableViewCell, object: AnyObject) {
        let queryResult = object as QueryResult
        let notification = queryResult.entity_ as Notification
        let notificationCell = cell as NotificationTableViewCell
        notificationCell.delegate = self
        notificationCell.summaryLabel.text = notification.summary
        notificationCell.summaryLabel.sizeToFit()
        
        notificationCell.notificationImageView.image = nil
        if let photo = notification.photoBig {
            notificationCell.notificationImageMaxHeightConstraint.constant = 10000
            notificationCell.notificationImageView.setImageWithURL(photo.photoURL())
        } else {
            notificationCell.notificationImageMaxHeightConstraint.constant = 0
        }
        
        notificationCell.avatarImageView.image = nil;
        if let avatarPhotoURL = notification.photo?.photoURL() {
            notificationCell.avatarImageView.setImageWithURL(avatarPhotoURL)
        } else {
            notificationCell.avatarImageView.image = UIImage(named: "Placeholder other user profile")
        }
        
        notificationCell.dateLabel.text = notification.createdDate.description
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //self.performSegueWithIdentifier("PatchDetailSegue", sender: self)
    }
    
    // MARK: NotificationTableViewCellDelegate
    func tableViewCell(cell: NotificationTableViewCell, didTapOnView view: UIView) {
        if view == cell.notificationImageView && cell.notificationImageView.image != nil {
            self.selectedDetailImage = cell.notificationImageView.image
            self.performSegueWithIdentifier("ImageDetailSegue", sender: view)
        }
    }
}
