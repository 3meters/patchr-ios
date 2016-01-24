//
//  BaseDetailViewController.swift
//  Patchr
//
//  Created by Jay Massena on 9/23/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class BaseDetailViewController: BaseTableViewController {

    var entity				: Entity?
    var entityId			: String?
    var deleted				= false
    var queryName			: String!
    var patchNameVisible	: Bool = true
	var header				: UIView!
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
    override func viewDidLoad() {
		self.listType = .Messages
        super.viewDidLoad()
    }
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		let statusHeight = UIApplication.sharedApplication().statusBarFrame.size.height
		let navHeight = self.navigationController?.navigationBar.height() ?? 0
		self.emptyLabel.anchorInCenterWithWidth(160, height: 160)
		self.emptyLabel.frame.origin.y -= CGFloat(statusHeight + navHeight)
		self.emptyLabel.frame.origin.y += self.header.height() / 2
	}

	override func viewWillAppear(animated: Bool) {
		
		if self.entity != nil {
			/* Entity could have been deleted while we were away so check it. */
			let item = ServiceBase.fetchOneById(self.entityId!, inManagedObjectContext: DataController.instance.mainContext)
			if item == nil {
				self.navigationController?.popViewControllerAnimated(false)
				return
			}
		}
		else {
			/* Use cached entity if available in the data model */
			if let entity: Entity? = Entity.fetchOneById(self.entityId!, inManagedObjectContext: DataController.instance.mainContext) {
				self.entity = entity
			}
		}
		
		/* In case a row height has changed because of editing. */
		self.rowHeights.removeAllObjects()
		
		super.viewWillAppear(animated)
		
		if self.entity != nil {
			bind()
		}
	}
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	/*--------------------------------------------------------------------------------------------
	* Events
	*--------------------------------------------------------------------------------------------*/
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	override func getActivityDate() -> Int64 {
		return self.entity!.activityDate?.milliseconds ?? 0
	}
	
    override func loadQuery() -> Query {
        
		let id = queryId()
		var query: Query? = Query.fetchOneById(id, inManagedObjectContext: DataController.instance.mainContext)

		if query == nil {

			query = Query.fetchOrInsertOneById(id, inManagedObjectContext: DataController.instance.mainContext) as Query
			query!.name = self.queryName
			query!.pageSize = DataController.proxibase.pageSizeDefault
			query!.contextEntity = nil

			if self.entity != nil {
				query!.contextEntity = self.entity
			}
			if self.entityId != nil {
				query!.entityId = self.entityId
			}

			DataController.instance.saveContext(BLOCKING)
		}

        return query!
    }

	func queryId() -> String {
		let id = self.entity?.id_ ?? self.entityId
		return "query.\(self.queryName!.lowercaseString).\(id!)"
	}
	
	func fetch(reset reset: Bool = false) {
        
        /* Refreshes the top object but not the message list */
		DataController.instance.backgroundOperationQueue.addOperationWithBlock {
			
			DataController.instance.withEntityId(self.entityId!, strategy: .UseCacheAndVerify) {
				[weak self] objectId, error in
				
				if self != nil {
					NSOperationQueue.mainQueue().addOperationWithBlock {
						
						var userInfo: [NSObject:AnyObject] = ["error": (error != nil)]

						if error == nil {
							if objectId != nil {
								
								/* entity has already been saved by DataController */
								let entity = DataController.instance.mainContext.objectWithID(objectId!) as! Entity
								self?.entity = entity
								self?.entityId = entity.id_
								
								/* 
								 * Refresh list too if context entity was updated or reset = true. 
								 * We need reset because a real list refresh is needed even if the activityDate
								 * hasn't changed because that is the only way to pickup link based message 
								 * state changes such as likes.
								 */
								if self?.getActivityDate() != self?.query.activityDateValue || reset {
									self?.fetchQueryItems(force: true, paging: !reset, queryDate: self?.getActivityDate())	// Only place we cascade the refresh to the list otherwise a pullToRefresh is required
								}
								else {
									if let fetchedObjects = self?.fetchedResultsController.fetchedObjects as [AnyObject]? {
										userInfo["count"] = fetchedObjects.count
									}
									if self != nil {
										NSNotificationCenter.defaultCenter().postNotificationName(Events.DidFetchQuery, object: self!, userInfo: userInfo)
									}
								}
								
								if let patch = entity as? Patch {
									DataController.instance.currentPatch = patch    // Used for context for messages
								}
								self?.drawButtons()	// Refresh so owner only commands can be displayed
								self?.bind()
								if self != nil {
									NSNotificationCenter.defaultCenter().postNotificationName(Events.DidFetch, object: self!)
								}
							}
							else {
								UIShared.Toast("Item has been deleted")
								Utils.delay(2.0) {
									() -> () in
									self?.navigationController?.popViewControllerAnimated(true)
									if self != nil {
										NSNotificationCenter.defaultCenter().postNotificationName(Events.DidFetch, object: self!, userInfo: ["deleted":true])
									}
								}
							}
						}
					}
				}
			}
		}
    }
	
	override func fetchQueryItems(force force: Bool = false, paging: Bool = false, queryDate: Int64?) {
        if force || !self.query.executedValue || paging {
			super.fetchQueryItems(force: force, paging: paging, queryDate: queryDate)
        }
    }
	
    func bind() {
        assert(false, "This method must be overridden in subclass")
    }
    
    func drawButtons() { /* Optional */ }
    
    override func pullToRefreshAction(sender: AnyObject?) -> Void {
		self.fetch(reset: true)
    }
}

extension BaseDetailViewController: TTTAttributedLabelDelegate {
    
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        UIApplication.sharedApplication().openURL(url)
    }
}

extension BaseDetailViewController {
	/*
	 * Cells
	 */
	override func bindCellToEntity(cell: WrapperTableViewCell, entity: AnyObject, location: CLLocation?) {
		
		super.bindCellToEntity(cell, entity: entity, location: location)
		
		if let view = cell.view as? MessageView {
			/* Hookup up delegates */
			view.description_?.delegate = self
			view.showPatchName = self.patchNameVisible
			view.patchName.hidden = !self.patchNameVisible
			view.photo?.addTarget(self, action: Selector("photoAction:"), forControlEvents: .TouchUpInside)
		}
	}
    /*
     * UITableViewDelegate 
     * These are shared by patch and user detail views.
     */
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem,
			let entity = queryResult.object as? Message {
			let controller = MessageDetailViewController()
			controller.inputMessage = entity
			self.navigationController?.pushViewController(controller, animated: true)
        }
    }
	
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		/*
		* Using an estimate significantly improves table view load time but we can get
		* small scrolling glitches if actual height ends up different than estimated height.
		* So we try to provide the best estimate we can and still deliver it quickly.
		*
		* Note: Called once only for each row in fetchResultController when FRC is making a data pass in
		* response to managedContext.save.
		*/
		if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem,
			let entity = queryResult.object as? Message {
				
				if entity.id_ != nil {
					if let cachedHeight = self.rowHeights.objectForKey(entity.id_) as? CGFloat {
						return cachedHeight
					}
				}
				
				var cellType: CellType = .TextAndPhoto
				if entity.type != nil && entity.type == "share" {
					cellType = .Share
				}
				else if entity.photo == nil {
					cellType = .Text
				}
				else if entity.description_ == nil {
					cellType = .Photo
				}
				
				let view = MessageView(cellType: cellType, entity: nil)
				let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.width())
				view.showPatchName = self.patchNameVisible
				view.bindToEntity(entity)
				view.bounds.size.width = viewWidth - 24
				view.sizeToFit()
				
				if entity.id_ != nil {
					self.rowHeights[entity.id_] = view.height() + 24 + 1
				}
				
				return view.height() + 24 + 1	// Add one for row separator
		}
		return 0
	}
}

