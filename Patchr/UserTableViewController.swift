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
		super.viewDidLoad()
		
		guard self.patch != nil || self.message != nil else {
			fatalError("User list requires a patch or message")
		}
		
        /* Content view */
		self.listType = .Users

		switch self.filter {
			case .PatchWatchers:
				self.navigationItem.title = "Watched by"
                if watchListForOwner() {
					self.showOwnerUI = true
                }
			case .MessageLikers:
				self.navigationItem.title = "Liked by"
		}
		
		self.tableView.estimatedRowHeight = 97
		self.tableView.rowHeight = 97
	}
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        switch self.filter {
            case .PatchWatchers:
                setScreenName("UserListPatchWatchers")
            case .MessageLikers:
                setScreenName("UserListMessageLikers")
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

			DataController.instance.saveContext(false)
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
	override func bindCell(cell: WrapperTableViewCell, entity: AnyObject, location: CLLocation?) -> UIView? {
		
		if let view = super.bindCell(cell, entity: entity, location: location) as? UserView {
			
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
		return nil
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
								user.link.enabledValue = linkEnabled
								DataController.instance.saveContext(false)
							}
							approvalSwitch.enabled = true
						}
					})
				}
			}
		}
	}

	func userView(userView: UserView, removeButtonTapped removeButton: UIButton) {
		
		self.ActionConfirmationAlert(
			"Confirm Remove",
			message: "Do you want to remove the request to watch your patch?",
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
								DataController.instance.mainContext.deleteObject(user.link)
								DataController.instance.mainContext.deleteObject(queryResult)
								DataController.instance.saveContext(false)
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