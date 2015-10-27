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
		
		self.tableView.estimatedRowHeight = 112
		self.tableView.rowHeight = 112
		
        /* Content view */
		self.listType = .Users

		switch self.filter {
			case .PatchWatchers:
				self.navigationItem.title = "Watchers"
                if watchListForOwner() {
					self.showOwnerUI = true
                }
			case .MessageLikers:
				self.navigationItem.title = "Likers"
		}
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
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    override func query() -> Query {
        if self._query == nil {
            let query = Query.insertInManagedObjectContext(DataController.instance.mainContext) as! Query
            
            switch self.filter {
                case .PatchWatchers:
                    query.name = DataStoreQueryName.WatchersForPatch.rawValue
                    query.pageSize = DataController.proxibase.pageSizeDefault
                    query.parameters = ["entity": patch]
				
                case .MessageLikers:
                    query.name = DataStoreQueryName.LikersForMessage.rawValue
                    query.pageSize = DataController.proxibase.pageSizeDefault
                    query.parameters = ["entity": message]
            }
            
			DataController.instance.saveContext()
            self._query = query
        }
        return self._query
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
	override func bindCell(cell: AirTableViewCell, entity: AnyObject, location: CLLocation?) -> UIView? {
		
		if let view = super.bindCell(cell, entity: entity, location: location) as? UserView {
			
			let user = entity as! User
			if self.filter == .PatchWatchers {
				if self.patch != nil {
					view.owner.hidden = !(user.id_ == self.patch.ownerId)
				}
				
				if self.showOwnerUI {
					if let currentUser = UserController.instance.currentUser {
						if entity.id_ != currentUser.id_ {
							view.removeButton.hidden = false
							view.approved.hidden = false
							view.approvedSwitch.hidden = false
							view.approvedSwitch.on = false
							if (entity.link != nil && user.link.type == "watch") {
								view.approvedSwitch.on = user.link.enabledValue
							}
						}
					}
				}
			}
			view.cell = cell
			view.delegate = self
		}
		return nil
	}
    /*
    * UITableViewDelegate
    */
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem,
            let entity = queryResult.object as? User,
            let controller = storyboard.instantiateViewControllerWithIdentifier("UserDetailViewController") as? UserDetailViewController {
                controller.entity = entity
                self.navigationController?.pushViewController(controller, animated: true)
        }
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
								DataController.instance.saveContext()
							}
							approvalSwitch.enabled = true
						}
					})
				}
			}
		}
	}

	func userView(userView: UserView, removeButtonTapped removeButton: UIButton) {
        
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
								DataController.instance.saveContext()
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