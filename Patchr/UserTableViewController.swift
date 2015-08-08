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

	var patch:          Patch!
    var message:        Message!
	var selectedUser:   User?
	var filter:         UserTableFilter = .PatchWatchers
    
    var watchListForOwner: Bool {
        if self.filter == .PatchWatchers && self.patch.visibility == "private" {
            if let currentUser = UserController.instance.currentUser {
                if currentUser.id_ == self.patch.ownerId {
                    return true
                }
            }
        }
        return false
    }
    
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
        
        /* Content view */
        self.contentViewName = "UserView"

		switch self.filter {
			case .PatchWatchers:
				self.navigationItem.title = "Watchers"
                if watchListForOwner {
                    self.contentViewName = "UserApprovalView"
                }
			case .PatchLikers, .MessageLikers:
				self.navigationItem.title = "Likers"
		}
	}
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        switch self.filter {
        case .PatchLikers:
            setScreenName("UserListPatchLikers")
        case .PatchWatchers:
            setScreenName("UserListPatchWatchers")
        case .MessageLikers:
            setScreenName("UserListMessageLikers")
        }
    }
    
    override func bindCell(cell: UITableViewCell, object: AnyObject, tableView: UITableView?, sizingOnly: Bool = false) {
        
        let view = cell.contentView.viewWithTag(1) as! UserView
        User.bindView(view, object: object, tableView: tableView, sizingOnly: sizingOnly)
        let user = object as! User
        if self.patch != nil {
            view.owner.text = (user.id_ == self.patch.ownerId) ? "OWNER" : nil
        }
        if let view = view as? UserApprovalView {
            view.delegate = self
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

extension UserTableViewController: UserApprovalViewDelegate {
    
	func userView(userView: UserApprovalView, approvalSwitchValueChanged approvalSwitch: UISwitch) {
        
		if let indexPath = self.tableView.indexPathForCell(userView.cell!) {
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

	func userView(userView: UserApprovalView, removeButtonTapped removeButton: UIButton) {
        
		if let indexPath = self.tableView.indexPathForCell(userView.cell!) {
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