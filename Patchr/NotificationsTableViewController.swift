//
//  NotificationsTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-27.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class NotificationsTableViewController: QueryResultTableViewController, TableViewCellDelegate {
    
    private let cellNibName = "NotificationTableViewCell"
    
    private var selectedDetailImage: UIImage?
    private var offscreenCells: NSMutableDictionary = NSMutableDictionary()
    
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
        self.tableView.registerNib(UINib(nibName: cellNibName, bundle: nil), forCellReuseIdentifier: "Cell")
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
        
        // The cell width seems to incorrect occassionally
        if CGRectGetWidth(cell.bounds) != CGRectGetWidth(self.tableView.bounds) {
            cell.bounds = CGRect(x: 0, y: 0, width: CGRectGetWidth(self.tableView.bounds), height: CGRectGetHeight(cell.frame))
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
        }
        
        let queryResult = object as QueryResult
        let notification = queryResult.entity_ as Notification
        let notificationCell = cell as NotificationTableViewCell
        notificationCell.delegate = self
        notificationCell.messageBodyLabel.text = notification.summary
        
        notificationCell.messageImageView.image = nil
        if let photo = notification.photoBig {
            let imageMarginTop : CGFloat = 10.0;
            notificationCell.messageImageContainerHeight.constant = notificationCell.messageImageView.frame.height + imageMarginTop
            notificationCell.messageImageView.setImageWithURL(photo.photoURL())
        } else {
            notificationCell.messageImageContainerHeight.constant = 0
        }
        
        notificationCell.userAvatarImageView.image = nil;
        if let avatarPhotoURL = notification.photo?.photoURL() {
            notificationCell.userAvatarImageView.setImageWithURL(avatarPhotoURL)
        } else {
            notificationCell.userAvatarImageView.image = UIImage(named: "Placeholder other user profile")
        }
        
        notificationCell.createdDateLabel.text = notification.createdDate.description
        notificationCell.iconImageView.backgroundColor = UIColor.orangeColor()
    }

    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //self.performSegueWithIdentifier("PatchDetailSegue", sender: self)
    }
    
    // TODO: This is duplicated in PatchDetailViewController
    // https://github.com/smileyborg/TableViewCellWithAutoLayout
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let reuseIdentifier = "Cell"
        var cell = self.offscreenCells.objectForKey(reuseIdentifier) as? UITableViewCell
        if cell == nil {
            let nibObjects = NSBundle.mainBundle().loadNibNamed(cellNibName, owner: self, options: nil)
            cell = nibObjects[0] as? UITableViewCell
            self.offscreenCells.setObject(cell!, forKey: reuseIdentifier)
        }
        
        let object: AnyObject = self.fetchedResultsController.objectAtIndexPath(indexPath)
        self.configureCell(cell!, object: object)
        cell?.setNeedsUpdateConstraints()
        cell?.updateConstraintsIfNeeded()
        cell?.bounds = CGRect(x: 0, y: 0, width: CGRectGetWidth(self.tableView.bounds), height: CGRectGetHeight(cell!.frame))
        cell?.setNeedsLayout()
        cell?.layoutIfNeeded()
        var height = cell!.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
        height += 1
        return height
    }
    
    // MARK: TableViewCellDelegate
    
    func tableViewCell(cell: UITableViewCell, didTapOnView view: UIView) {
        let notificationCell = cell as NotificationTableViewCell
        if view == notificationCell.messageImageView && notificationCell.messageImageView.image != nil {
            self.selectedDetailImage = notificationCell.messageImageView.image
            self.performSegueWithIdentifier("ImageDetailSegue", sender: view)
        }
    }
}
