//
//  BaseDetailViewController.swift
//  Patchr
//
//  Created by Jay Massena on 9/23/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class BaseDetailViewController: BaseTableViewController {

    var entity: Entity?
    var entityId: String?
    var deleted = false
    var queryName: String!
    var patchNameVisible: Bool = true
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        
        self.showEmptyLabel = false
        self.showProgress = true
        self.progressOffsetY = 80
		self.loadMoreMessage = "LOAD MORE MESSAGES"
		self.listType = .Messages
        
        super.viewDidLoad()
		
		/* Turn off estimate so rows are measured up front */
		self.tableView.estimatedRowHeight = 150		
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
		
		super.viewWillAppear(animated)
		
		if self.entity != nil {
			draw()
		}
	}
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
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

			DataController.instance.saveContext(false)
		}

        return query!
    }

	func queryId() -> String {
		return "query.\(self.queryName!.lowercaseString).\(self.entityId!)"
	}
	
    internal func bind(force: Bool = false) {
        
        /* Refreshes the top object but not the message list */
		DataController.instance.backgroundOperationQueue.addOperationWithBlock {
			
			DataController.instance.withEntityId(self.entityId!, refresh: force) {
				[weak self] objectId, error in
				
				if self != nil {
					NSOperationQueue.mainQueue().addOperationWithBlock {
						
						Utils.delay(0.0) {
							self?.refreshControl?.endRefreshing()
							
							if error == nil {
								if objectId != nil {
									let entity = DataController.instance.mainContext.objectWithID(objectId!) as! Entity
									
									/* Refresh list too if context entity was updated */
									if entity.refreshedValue {
										entity.refreshedValue = false
										self?.bindQueryItems(true)	// Only place we cascade the refresh to the list otherwise a pullToRefresh is required
										DataController.instance.saveContext(false)
									}
									
									self?.entity = entity
									self?.entityId = entity.id_
									if let patch = entity as? Patch {
										DataController.instance.currentPatch = patch    // Used for context for messages
									}
									self?.drawButtons()	// Refresh so owner only commands can be displayed
									self?.draw()
									NSNotificationCenter.defaultCenter().postNotificationName(Events.BindingComplete, object: nil)
								}
								else {
									Shared.Toast("Item has been deleted")
									Utils.delay(2.0) {
										() -> () in
										self?.navigationController?.popViewControllerAnimated(true)
										NSNotificationCenter.defaultCenter().postNotificationName(Events.BindingComplete, object: nil, userInfo: ["deleted":true])
									}
								}
							}
						}
					}
				}
			}
		}
    }
	
    override func bindQueryItems(force: Bool = false, paging: Bool = false) {
        if force || !self.query.executedValue || paging {
            super.bindQueryItems(force, paging: paging)
        }
    }
	
    internal func draw() {
        assert(false, "This method must be overridden in subclass")
    }
    
    internal func drawButtons() { /* Optional */ }
    
    override func pullToRefreshAction(sender: AnyObject?) -> Void {
        self.bind(true)
        self.bindQueryItems(true, paging: false)
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
	override func bindCell(cell: AirTableViewCell, entity object: AnyObject, location: CLLocation?) -> UIView? {
		
		if let view = super.bindCell(cell, entity: object, location: location) as? MessageView {
			/* Hookup up delegates */
			view.description_?.delegate = self
			view.showPatchName = self.patchNameVisible
			view.patchName.hidden = !self.patchNameVisible
			view.photo?.addTarget(self, action: Selector("photoAction:"), forControlEvents: .TouchUpInside)
		}
		return nil
	}
    /*
     * UITableViewDelegate 
     * These are shared by patch and user detail views.
     */
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem,
            let entity = queryResult.object as? Message,
            let controller = storyboard.instantiateViewControllerWithIdentifier("MessageDetailViewController") as? MessageDetailViewController {
                controller.message = entity
                self.navigationController?.pushViewController(controller, animated: true)
        }
    }
	
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		if let height = quickHeight(indexPath) {
			return height
		}
		else {
			return 0
		}
	}
	
	func quickHeight(indexPath: NSIndexPath) -> CGFloat? {
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
				
				let height = MessageView.quickHeight(self.tableView.width(), showPatchName:self.patchNameVisible, entity:entity )
				
				if entity.id_ != nil {
					self.rowHeights[entity.id_] = CGFloat(height)
				}
				
				return CGFloat(height + 1)	// Add one for row separator
		}
		else {
			return nil
		}
	}
}

