//
//  NotificationsTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-27.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class NotificationsTableViewController: QueryTableViewController {

	private let cellNibName = "NotificationTableViewCell"

	private var offscreenCells:       NSMutableDictionary = NSMutableDictionary()
	private var messageDateFormatter: NSDateFormatter!
	private var selectedPatch:        Patch?
	private var selectedMessage:      Message?
    private var selectedEntityId:     String?
	private var _query:               Query!
    
	override func query() -> Query {
		if self._query == nil {
			let query = Query.insertInManagedObjectContext(DataController.instance.managedObjectContext) as! Query
			query.name = DataStoreQueryName.NotificationsForCurrentUser.rawValue
            query.pageSize = DataController.proxibase.pageSizeNotifications
			DataController.instance.managedObjectContext.save(nil)
			self._query = query
		}
		return self._query
	}
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

	override func awakeFromNib() {
		super.awakeFromNib()
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleRemoteNotification:", name: PAApplicationDidReceiveRemoteNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleApplicationDidBecomeActiveWithNonZeroBadge:", name: PAapplicationDidBecomeActiveWithNonZeroBadge, object: nil)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		tableView.registerNib(UINib(nibName: cellNibName, bundle: nil), forCellReuseIdentifier: "Cell")

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

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
	override func configureCell(cell: UITableViewCell, object: AnyObject) {

		// The cell width seems to incorrect occassionally
		if CGRectGetWidth(cell.bounds) != CGRectGetWidth(self.tableView.bounds) {
			cell.bounds = CGRect(x: 0, y: 0, width: CGRectGetWidth(self.tableView.bounds), height: CGRectGetHeight(cell.frame))
			cell.setNeedsLayout()
			cell.layoutIfNeeded()
		}

		let queryResult  = object as! QueryItem
		let notification = queryResult.object as! Notification
		let cell         = cell as! NotificationTableViewCell

		cell.delegate = self

		cell.description_.text = nil
		cell.description_.text = notification.summary

		if let photo = notification.photoBig {
            cell.photo.setImageWithPhoto(photo, animate: cell.photo.image == nil)
			cell.photoHolderHeight.constant = cell.photo.frame.height + 8
		}
		else {
			cell.photoHolderHeight.constant = 0
		}

        cell.userPhoto.setImageWithPhoto(notification.getPhotoManaged(), animate: cell.userPhoto.image == nil)
		cell.createdDate.text = self.messageDateFormatter.stringFromDate(notification.createdDate)

		if notification.type == "media" {
			cell.iconImageView.image = UIImage(named: "imgMediaLight")
		}
		else if notification.type == "message" {
			cell.iconImageView.image = UIImage(named: "imgMessageLight")
		}
		else if notification.type == "watch" {
			cell.iconImageView.image = UIImage(named: "imgWatchLight")
		}
        else if notification.type == "like" {
            cell.iconImageView.image = UIImage(named: "imgLikeLight")
        }
		else if notification.type == "share" {
			cell.iconImageView.image = UIImage(named: "imgShareLight")
		}
        cell.iconImageView.tintColor(Colors.brandColor)
	}

    func segueWith(targetId: String?, parentId: String?, refreshEntities: Bool = false) {
        if targetId == nil { return }
        
        self.selectedEntityId = targetId
        if targetId!.hasPrefix("pa.") {
            self.performSegueWithIdentifier("PatchDetailSegue", sender: self)
        }
        else if targetId!.hasPrefix("me.") {
            self.performSegueWithIdentifier("MessageDetailSegue", sender: self)
        }
        
//        DataController.instance.withEntityId(targetId!, refresh: refreshEntities) {
//            (entity) -> Void in
//            
//            if let patch = entity as? Patch {
//                self.selectedPatch = patch
//                self.performSegueWithIdentifier("PatchDetailSegue", sender: self)
//            }
//            else if let message = entity as? Message {
//                self.selectedMessage = message
//                self.performSegueWithIdentifier("MessageDetailSegue", sender: self)
//            }
//            else {
//                // Try again with the parentId.
//                if parentId == nil {
//                    return
//                }
//                DataController.instance.withEntityId(parentId!, refresh: refreshEntities, completion: {
//                    (entity) -> Void in
//                    if let patch = entity as? Patch {
//                        self.selectedPatch = patch
//                        self.performSegueWithIdentifier("PatchDetailSegue", sender: self)
//                    }
//                })
//            }
//        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == nil {
            return
        }
        
        switch segue.identifier! {
        case "PatchDetailSegue":
            if let controller = segue.destinationViewController as? PatchDetailViewController {
                controller.patchId = self.selectedEntityId
                self.selectedEntityId = nil
//                controller.patch = self.selectedPatch
//                self.selectedPatch = nil
            }
        case "MessageDetailSegue":
            if let controller = segue.destinationViewController as? MessageDetailViewController {
                controller.messageId = self.selectedEntityId
                self.selectedEntityId = nil
//                controller.message = self.selectedMessage
//                self.selectedMessage = nil
            }
        default: ()
        }
    }
    
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
							}
							else {
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

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

extension NotificationsTableViewController: UITableViewDelegate {
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let queryResult  = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem {
            if let notification = queryResult.object as? Notification {
                self.segueWith(notification.targetId, parentId: notification.parentId)
            }
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        var cell = self.offscreenCells.objectForKey("Cell") as? UITableViewCell
        
        if cell == nil {
            let nibObjects = NSBundle.mainBundle().loadNibNamed(cellNibName, owner: self, options: nil)
            cell = nibObjects[0] as? UITableViewCell
            self.offscreenCells.setObject(cell!, forKey: "Cell")
        }
        
        let object: AnyObject = self.fetchedResultsController.objectAtIndexPath(indexPath)
        
        self.configureCell(cell!, object: object)
        
        cell?.setNeedsUpdateConstraints()
        cell?.updateConstraintsIfNeeded()
        
        cell?.bounds = CGRect(x: 0, y: 0, width: CGRectGetWidth(self.tableView.bounds), height: CGRectGetHeight(cell!.frame))
        
        cell?.setNeedsLayout()
        cell?.layoutIfNeeded()
        
        var height = cell!.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height + 1
        
        return height
    }
}

extension NotificationsTableViewController: TableViewCellDelegate {
    
	func tableViewCell(cell: UITableViewCell, didTapOnView view: UIView) {
		let notificationCell = cell as! NotificationTableViewCell
		if view == notificationCell.photo && notificationCell.photo.image != nil {
			AirUi.instance.showPhotoBrowser(notificationCell.photo.image, view: view, viewController: self)
		}
	}
}