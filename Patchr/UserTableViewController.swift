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
			case .MessageLikers:
				self.navigationItem.title = "Liked by"
		}
	}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        switch self.filter {
            case .PatchWatchers:
                Reporting.screen("UserListPatchWatchers")
            case .MessageLikers:
                Reporting.screen("UserListMessageLikers")
        }
    }
	
	override func viewDidAppear(_ animated: Bool) {
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
		var query: Query? = Query.fetchOne(byId: id, in: DataController.instance.mainContext)

		if query == nil {
			query = Query.fetchOrInsertOne(byId: id, in: DataController.instance.mainContext) as Query

			switch self.filter {
				case .PatchWatchers:
					query!.name = DataStoreQueryName.WatchersForPatch.rawValue
					query!.pageSize = DataController.proxibase.pageSizeDefault as NSNumber!
					query!.contextEntity = self.patch

				case .MessageLikers:
					query!.name = DataStoreQueryName.LikersForMessage.rawValue
					query!.pageSize = DataController.proxibase.pageSizeDefault as NSNumber!
					query!.contextEntity = self.message
			}

			DataController.instance.saveContext(wait: BLOCKING)
		}

        return query!
    }
	
	func queryId() -> String {
		
		var queryId: String!
		switch self.filter {
			case .PatchWatchers:
				queryId = "query.\(DataStoreQueryName.WatchersForPatch.rawValue.lowercased()).\(self.patch.id_)"
			case .MessageLikers:
				queryId = "query.\(DataStoreQueryName.LikersForMessage.rawValue.lowercased()).\(self.message.id_)"
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
}

/*--------------------------------------------------------------------------------------------
 * Extensions
 *--------------------------------------------------------------------------------------------*/

extension UserTableViewController {
	/*
	 * Cells
	 */
	override func bindCellToEntity(cell: WrapperTableViewCell, entity: AnyObject, location: CLLocation?) {
		
		super.bindCellToEntity(cell: cell, entity: entity, location: location)
		
		if let view = cell.view as? UserView {
			
			let user = entity as! User
			if self.filter == .PatchWatchers && self.patch != nil {
				view.owner.isHidden = !(user.id_ == self.patch.ownerId)
			}
			view.cell = cell
		}
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 97
	}
}

enum UserTableFilter {
    case PatchWatchers
    case MessageLikers
}
