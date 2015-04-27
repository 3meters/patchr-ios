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
    private var messageDateFormatter: NSDateFormatter!
    
    private var selectedPatch: Patch?
    
    private var _query: Query!
    override func query() -> Query {
        if self._query == nil {
            let query = Query.insertInManagedObjectContext(self.managedObjectContext) as! Query
            query.name = "Notifications for current user"
            self.managedObjectContext.save(nil)
            self._query = query
        }
        return self._query
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
         NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleRemoteNotification:", name: PAApplicationDidReceiveRemoteNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleApplicationDidBecomeActiveWithNonZeroBadge:", name: PAapplicationDidBecomeActiveWithNonZeroBadge, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerNib(UINib(nibName: cellNibName, bundle: nil), forCellReuseIdentifier: "Cell")
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.doesRelativeDateFormatting = true
        self.messageDateFormatter = dateFormatter
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.tabBarItem.badgeValue = nil
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
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
        
        let queryResult = object as! QueryResult
        let notification = queryResult.result as! Notification
        let notificationCell = cell as! NotificationTableViewCell
        notificationCell.delegate = self
        notificationCell.messageBodyLabel.text = notification.summary
        
        notificationCell.messageImageView.image = nil
        if let photo = notification.photoBig {
            let imageMarginTop : CGFloat = 10.0;
            notificationCell.messageImageContainerHeight.constant = notificationCell.messageImageView.frame.height + imageMarginTop
            notificationCell.messageImageView.pa_setImageWithURL(photo.photoURL())
        } else {
            notificationCell.messageImageContainerHeight.constant = 0
        }
        
        notificationCell.userAvatarImageView.pa_setImageWithURL(notification.photo?.photoURL(), placeholder: UIImage(named: "UserAvatarDefault"))        
        notificationCell.createdDateLabel.text = self.messageDateFormatter.stringFromDate(notification.createdDate)
        
        notificationCell.iconImageView.tintColor = self.view.window?.tintColor
        if notification.type == "media" {
            notificationCell.iconImageView.image = UIImage(named: "NotificationIconMediaLight")
        } else if notification.type == "message" {
            notificationCell.iconImageView.image = UIImage(named: "NotificationIconMessageLight")
        } else if notification.type == "watch" {
            notificationCell.iconImageView.image = UIImage(named: "NotificationIconWatchLight")
        }
    }

    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as! QueryResult
        let notification = queryResult.result as! Notification
        self.segueWith(notification.targetId, parentId: notification.parentId)
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
        let notificationCell = cell as! NotificationTableViewCell
        if view == notificationCell.messageImageView && notificationCell.messageImageView.image != nil {
            self.selectedDetailImage = notificationCell.messageImageView.image
            self.performSegueWithIdentifier("ImageDetailSegue", sender: view)
        }
    }
    
    // MARK: Private Internal
    
    func handleRemoteNotification(notification: NSNotification) {

        if let userInfo = notification.userInfo {
            
            if let stateRaw = userInfo["receivedInApplicationState"] as? Int {
                
                if let applicationState = UIApplicationState(rawValue: stateRaw) {
                    
                    let parentId = userInfo["parentId"] as? String
                    let targetId = userInfo["targetId"] as? String
                    
                    // Only refresh notifications if view has already been loaded
                    if self.isViewLoaded() {
                        self.refreshControl?.beginRefreshing()
                        self.pullToRefreshAction(self.refreshControl)
                    }
                    
                    switch applicationState {
                    case .Active: // App was active when remote notification was received
                        
                        if self.tabBarController?.selectedViewController == self.navigationController && self.navigationController?.topViewController == self {
                            // This view controller is currently visible. Don't badge.
                        } else {
                            self.navigationController?.tabBarItem.badgeValue = ""
                        }

                    case .Inactive: // App was resumed or launched via remote notification
                        
                        // Select the notifications tab and then segue as if the user had selected the notification
                        self.tabBarController?.selectedViewController = self.navigationController
                        
                        // Pop back to root if necessary
                        if self.navigationController?.topViewController != self {
                            self.navigationController?.popToRootViewControllerAnimated(false)
                        }
                        
                        self.segueWith(targetId, parentId: parentId, refreshEntities: true)
                        
                        // Clear tab badge here if it was previously set
                        self.navigationController?.tabBarItem.badgeValue = nil
                        
                    case .Background:
                        ()
                    }
                }
            }
        }
    }
    
    func handleApplicationDidBecomeActiveWithNonZeroBadge(notification: NSNotification) {
        
        // Badge the tab if it isn't already selected
        if self.tabBarController?.selectedViewController != self.navigationController {
            self.navigationController?.tabBarItem.badgeValue = ""
        }
        
        // Only refresh notifications if view has already been loaded
        if self.isViewLoaded() {
            self.refreshControl?.beginRefreshing()
            self.pullToRefreshAction(self.refreshControl)
        }
    }
    
    func segueWith(targetId: String?, parentId: String?, refreshEntities: Bool = false) {
        if targetId == nil { return }
        self.dataStore.withEntity(targetId!, refresh: refreshEntities) { (entity) -> Void in
            if let patch = entity as? Patch {
                self.selectedPatch = patch
                self.performSegueWithIdentifier("PatchDetailSegue", sender: self)
            } else {
                // Try again with the parentId.
                if parentId == nil { return }
                self.dataStore.withEntity(parentId!, refresh: refreshEntities, completion: { (entity) -> Void in
                    if let patch = entity as? Patch {
                        self.selectedPatch = patch
                        self.performSegueWithIdentifier("PatchDetailSegue", sender: self)
                    }
                })
            }
        }
    }
}
