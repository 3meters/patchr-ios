//
//  NotificationsTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-27.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class NotificationsTableViewController: QueryResultTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerNib(UINib(nibName: "NotificationTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
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
        query.name = "Notifications for current user"
        query.limitValue = 25
        query.path = "do/getNotifications"
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
            if let notification = queryResult.entity_ as? Notification {
                if let notificationCell = cell as? NotificationTableViewCell {
                    var notificationSummaryAttributedText = NSMutableAttributedString(HTML: notification.summary)
                    notificationSummaryAttributedText.enumerateFontsInRange(NSMakeRange(0, notificationSummaryAttributedText.length), includeUndefined: true, usingBlock: { (font, range, stop) -> Void in
                        var newFont = font
                        if newFont == nil {
                            newFont = NSAttributedString.defaultFont()
                        }
                        newFont = newFont.fontWithSize(notificationCell.summaryLabel.font.pointSize)
                        notificationSummaryAttributedText.setFont(newFont, range: range)
                    })
                    notificationCell.summaryLabel.attributedText = notificationSummaryAttributedText
                    notificationCell.notificationImageView.image = nil
                    if let photo = notification.photoBig {
                        notificationCell.notificationImageMaxHeightConstraint.constant = 10000
                        notificationCell.notificationImageView.setImageWithURL(photo.photoURL())
                    } else {
                        notificationCell.notificationImageMaxHeightConstraint.constant = 0
                    }
                } else {
                    cell.textLabel?.text = notification.summary
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
}
