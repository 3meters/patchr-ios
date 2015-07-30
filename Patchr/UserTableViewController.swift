//
//  UserTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-27.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

enum UserTableFilter {
	case PatchLikers
	case PatchWatchers
    case MessageLikers
}

class UserTableViewController: QueryTableViewController {

	private let cellNibName = "UserTableViewCell"

	var patch:          Patch!
    var message:        Message!
	var selectedUser:   User?
	var filter:         UserTableFilter = .PatchWatchers
	private var _query: Query!

	override func query() -> Query {
		if self._query == nil {
			let query = Query.insertInManagedObjectContext(DataController.instance.managedObjectContext) as! Query

			switch self.filter {
				case .PatchLikers:
					query.name = DataStoreQueryName.LikersForPatch.rawValue
                    query.pageSize = DataController.proxibase.pageSizeDefault
                    query.parameters = ["entity": patch]
				case .PatchWatchers:
					query.name = DataStoreQueryName.WatchersForPatch.rawValue
                    query.pageSize = DataController.proxibase.pageSizeDefault
                    query.parameters = ["entity": patch]
                case .MessageLikers:
                    query.name = DataStoreQueryName.LikersForMessage.rawValue
                    query.pageSize = DataController.proxibase.pageSizeDefault
                    query.parameters = ["entity": message]
			}

			DataController.instance.managedObjectContext.save(nil)
			self._query = query
		}
		return self._query
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView.registerNib(UINib(nibName: cellNibName, bundle: nil), forCellReuseIdentifier: CELL_IDENTIFIER)

		switch self.filter {
			case .PatchWatchers:
				self.navigationItem.title = "Watchers"
			case .PatchLikers, .MessageLikers:
				self.navigationItem.title = "Likers"
		}
	}

    override func configureCell(cell: UITableViewCell, object: AnyObject, sizingOnly: Bool = false) {

		// The cell width seems to incorrect occassionally
		if CGRectGetWidth(cell.bounds) != CGRectGetWidth(self.tableView.bounds) {
			cell.bounds = CGRect(x: 0, y: 0, width: CGRectGetWidth(self.tableView.bounds), height: CGRectGetHeight(cell.frame))
			cell.setNeedsLayout()
			cell.layoutIfNeeded()
		}

		let queryResult = object as! QueryItem
		let user = queryResult.object as! User
		let cell = cell as! UserTableViewCell
		cell.delegate = self

		cell.userName.text = user.name
        cell.userPhoto.setImageWithPhoto(user.getPhotoManaged(), animate: cell.userPhoto.image == nil)
		cell.area.text = user.area?.uppercaseString
        if self.patch != nil {
            cell.owner.text = user.id_ == self.patch.ownerId ? "OWNER" : nil
        }

		cell.userName.hidden = cell.userName.text == nil
		cell.area.hidden = cell.area.text == nil
		cell.owner.hidden = cell.owner.text == nil

		// Private patch owner controls controls
        cell.removeButton?.hidden = true
        cell.approved?.hidden = true
        cell.approvedSwitch?.hidden = true
        
		if self.filter == .PatchWatchers && self.patch.visibility == "private" {
            
            if let currentUser = UserController.instance.currentUser {
                if currentUser.id_ == self.patch.ownerId {
                    if user.id_ != currentUser.id_ {
                        cell.removeButton?.hidden = false
                        cell.approved?.hidden = false
                        cell.approvedSwitch?.hidden = false
                        cell.approvedSwitch?.on = false
                        if (user.link != nil && user.link.type == "watch") {
                            cell.approvedSwitch?.on = user.link.enabledValue
                        }
                    }
                }
            }
		}
	}
}

/*--------------------------------------------------------------------------------------------
 * Extensions
 *--------------------------------------------------------------------------------------------*/

extension UserTableViewController: UITableViewDelegate {
    
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem {
			if let user = queryResult.object as? User {
				self.selectedUser = user
				self.performSegueWithIdentifier("UserDetailSegue", sender: self)
				return
			}
		}
		assert(false, "Couldn't set selectedUser")
	}
}

extension UserTableViewController: UserTableViewCellDelegate {
    
	func userTableViewCell(userTableViewCell: UserTableViewCell, approvalSwitchValueChanged approvalSwitch: UISwitch) {
        
		if let indexPath = self.tableView.indexPathForCell(userTableViewCell) {
			if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem {
				if let user = queryResult.object as? User {
					approvalSwitch.enabled = false
					let linkEnabled = approvalSwitch.on
					DataController.proxibase.enableLinkById(user.link.id_, enabled: linkEnabled, completion: {
						response, error in
                        
                        if let error = ServerError(error) {
                            approvalSwitch.on = !linkEnabled
                            self.handleError(error, errorActionType: .ALERT)
                        }
                        else {
							user.link.enabledValue = linkEnabled
							DataController.instance.managedObjectContext.save(nil)
						}
						approvalSwitch.enabled = true
					})
				}
			}
		}
	}

	func userTableViewCell(userTableViewCell: UserTableViewCell, removeButtonTapped removeButton: UIButton) {
        
		if let indexPath = self.tableView.indexPathForCell(userTableViewCell) {
			if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem {
				if let user = queryResult.object as? User {
					DataController.proxibase.deleteLinkById(user.link.id_, completion: {
						response, error in
                        
                        if let error = ServerError(error) {
                            self.handleError(error, errorActionType: .ALERT)
                        }
                        else {
							DataController.instance.managedObjectContext.deleteObject(user.link)
							DataController.instance.managedObjectContext.deleteObject(queryResult)
							DataController.instance.managedObjectContext.save(nil)
						}
					})
				}
			}
		}
	}
}