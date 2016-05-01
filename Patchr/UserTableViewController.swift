//
//  UserTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-27.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class UserTableViewController: BaseTableViewController {

	var patch:          Patch!
    var message:        Message!
	var filter:         UserTableFilter = .PatchWatchers
	var showOwnerUI		= false
	
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

	override func viewDidLoad() {
		self.itemPadding = UIEdgeInsetsMake(8, 8, 8, 8)
		
		super.viewDidLoad()
		
		guard self.patch != nil || self.message != nil else {
			fatalError("User list requires a patch or message")
		}
		
        /* Content view */
		self.listType = .Users

		switch self.filter {
			case .PatchWatchers:
				self.navigationItem.title = "Members"
                if watchListForOwner() {
					self.showOwnerUI = true
                }
			case .MessageLikers:
				self.navigationItem.title = "Liked by"
		}
		
		self.view.accessibilityIdentifier = View.Users
		self.tableView!.accessibilityIdentifier = Table.Users
	}
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        switch self.filter {
            case .PatchWatchers:
                screen("UserListPatchWatchers")
            case .MessageLikers:
                screen("UserListMessageLikers")
        }
    }
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		if getActivityDate() != self.query.activityDateValue {
			self.fetchQueryItems(force: true, paging: false, queryDate: getActivityDate())
		}
	}
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	override func getActivityDate() -> Int64 {
		switch self.filter {
		case .PatchWatchers:
			return self.patch.activityDate?.milliseconds ?? 0
		case .MessageLikers:
			return self.message.activityDate?.milliseconds ?? 0
		}
	}

    override func loadQuery() -> Query {

		let id = queryId()
		var query: Query? = Query.fetchOneById(id, inManagedObjectContext: DataController.instance.mainContext)

		if query == nil {
			query = Query.fetchOrInsertOneById(id, inManagedObjectContext: DataController.instance.mainContext) as Query

			switch self.filter {
				case .PatchWatchers:
					query!.name = DataStoreQueryName.WatchersForPatch.rawValue
					query!.pageSize = DataController.proxibase.pageSizeDefault
					query!.contextEntity = self.patch

				case .MessageLikers:
					query!.name = DataStoreQueryName.LikersForMessage.rawValue
					query!.pageSize = DataController.proxibase.pageSizeDefault
					query!.contextEntity = self.message
			}

			DataController.instance.saveContext(BLOCKING)
		}

        return query!
    }
	
	func queryId() -> String {
		
		var queryId: String!
		switch self.filter {
			case .PatchWatchers:
				queryId = "query.\(DataStoreQueryName.WatchersForPatch.rawValue.lowercaseString).\(self.patch.id_)"
			case .MessageLikers:
				queryId = "query.\(DataStoreQueryName.LikersForMessage.rawValue.lowercaseString).\(self.message.id_)"
		}
		
		guard queryId != nil else {
			fatalError("Unassigned query id")
		}
		
		return queryId
	}
	
	override func didRefreshItems(query: Query) {
		/* 
		 * This is an attempt to have the owner sort at the top of the list 
		 */
		if self.filter == .PatchWatchers {
			if self.patch != nil {
				for item in query.queryItems {
					let queryItem = item as! QueryItem
					let user = queryItem.object as! User
					if user.id_ == self.patch.ownerId {
						queryItem.positionValue = -1
					}
				}
			}
		}
	}
	
    func watchListForOwner() -> Bool {
        if self.filter == .PatchWatchers && self.patch.visibility == "private" {
            if let currentUser = UserController.instance.currentUser {
                if currentUser.id_ == self.patch.ownerId {
                    return true
                }
            }
        }
        return false
    }
}

/*--------------------------------------------------------------------------------------------
 * Extensions
 *--------------------------------------------------------------------------------------------*/

extension UserTableViewController {
	/*
	 * Cells
	 */
	override func bindCellToEntity(cell: WrapperTableViewCell, entity: AnyObject, location: CLLocation?) {
		
		super.bindCellToEntity(cell, entity: entity, location: location)
		
		if let view = cell.view as? UserView {
			
			let user = entity as! User
			if self.filter == .PatchWatchers {
				if self.patch != nil {
					view.owner.hidden = !(user.id_ == self.patch.ownerId)
				}
				
				if self.showOwnerUI {
					if let currentUser = UserController.instance.currentUser {
						if user.id_ != currentUser.id_ {
							view.approvedSwitch.on = false
							if (user.link != nil && user.link.type == "watch") {
								view.approvedSwitch.on = user.link.enabledValue
							}
							view.showOwnerUI()
						}
					}
				}
			}
			view.cell = cell
			view.delegate = self
		}
	}
	
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 97
	}
}

extension UserTableViewController: UserApprovalViewDelegate {
    
	func userView(userView: UserView, approvalSwitchValueChanged approvalSwitch: UISwitch) {
        
		if let indexPath = self.tableView.indexPathForCell(userView.cell!) {
			if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem {
				if let user = queryResult.object as? User {
					approvalSwitch.enabled = false
					let linkEnabled = approvalSwitch.on
					
					DataController.proxibase.enableLinkById(user.link.id_, enabled: linkEnabled, completion: {
						response, error in
                        
						NSOperationQueue.mainQueue().addOperationWithBlock {
							if let error = ServerError(error) {
								approvalSwitch.on = !linkEnabled
								self.handleError(error, errorActionType: .ALERT)
							}
							else {
								Reporting.track(linkEnabled ? "Approved Member" : "Unapproved Member", properties: nil)
								user.link.enabledValue = linkEnabled
								DataController.instance.saveContext(BLOCKING)
							}
							approvalSwitch.enabled = true
						}
					})
				}
			}
		}
	}

	func userView(userView: UserView, removeButtonTapped removeButton: UIButton) {
		
		self.DeleteConfirmationAlert(
			"Confirm Remove",
			message: "Do you want to remove the request to join your patch?",
			actionTitle: "Remove", cancelTitle: "Cancel", delegate: self) {
				doIt in
				if doIt {
					self.removeWatchRequest(userView)
				}
		}
	}
	
	func removeWatchRequest(userView: UserView) {
		if let indexPath = self.tableView.indexPathForCell(userView.cell!) {
			if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem {
				if let user = queryResult.object as? User {
					
					DataController.proxibase.deleteLinkById(user.link.id_, completion: {
						response, error in
						
						NSOperationQueue.mainQueue().addOperationWithBlock {
							if let error = ServerError(error) {
								self.handleError(error, errorActionType: .ALERT)
							}
							else {
								Reporting.track("Removed Member Request", properties: nil)
								DataController.instance.mainContext.deleteObject(user.link)
								DataController.instance.mainContext.deleteObject(queryResult)
								DataController.instance.saveContext(BLOCKING)
							}
						}
					})
				}
			}
		}
	}
}

enum UserTableFilter {
    case PatchWatchers
    case MessageLikers
}