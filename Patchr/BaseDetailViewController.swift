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
    var queryId: String!
    var patchNameVisible: Bool = true
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        
        if self.entity != nil {
            self.entityId = self.entity!.id_
        }
		
        self.showEmptyLabel = false
        self.showProgress = true
        self.progressOffsetY = 80
		self.loadMoreMessage = "LOAD MORE MESSAGES"
		self.listType = .Messages
        
        /* Use cached entity if available in the data model */
        if self.entityId != nil {
            if let entity: Entity? = Entity.fetchOneById(self.entityId!, inManagedObjectContext: DataController.instance.mainContext) {
                self.entity = entity
            }
        }
        
        /* Use cached query if available in the data model */
		if self.entityId != nil {
			let id = "query.\(self.entityId!)"
			let query: Query? = Query.fetchOneById(id, inManagedObjectContext: DataController.instance.mainContext)
			if query != nil {
				self._query = query
				self.showProgress = false
			}
		}
		
        super.viewDidLoad()
		
		/* Turn off estimate so rows are measured up front */
		self.tableView.estimatedRowHeight = 150
		
		if self._query != nil {
			if self._query!.moreValue {
				if self.tableView.tableFooterView == nil {
					self.tableView.tableFooterView = self.footerView
				}
				if let button = self.footerView.viewWithTag(1) as? UIButton,
					spinner = self.footerView.viewWithTag(2) as? UIActivityIndicatorView {
						button.hidden = false
						spinner.hidden = true
						spinner.stopAnimating()
				}
			}
		}
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    override func query() -> Query {
        
        if self._query == nil {
			
			let id = self.entityId != nil ? "query.\(self.entityId)" : "query.guest"
            var query: Query? = Query.fetchOneById(id, inManagedObjectContext: DataController.instance.mainContext)
            
            if query == nil {
				
                query = Query.fetchOrInsertOneById(id, inManagedObjectContext: DataController.instance.mainContext) as Query
                query!.name = self.queryName
                query!.pageSize = DataController.proxibase.pageSizeDefault
                query!.parameters = [:]
				
                if self.entity != nil {
                    query!.parameters["entity"] = self.entity
                }
                if self.entityId != nil {
                    query!.parameters["entityId"] = self.entityId
                }
				
				if self.entityId == nil && self.entity == nil {
					query?.enabledValue = false	// Zombies it so it doesn't get executed
				}
				
                DataController.instance.saveContext()
            }
            
            self._query = query
        }
        
        return self._query
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
									/* Refresh list too */
									if entity.refreshedValue {
										entity.refreshedValue = false
										self?.bindQueryItems(true)
									}
									
									self?.entity = entity
									self?.entityId = entity.id_
									if let patch = entity as? Patch {
										DataController.instance.currentPatch = patch    // Used for context for messages
									}
									self?.drawButtons()
									self?.draw()
								}
								else {
									Shared.Toast("Item has been deleted")
									Utils.delay(2.0) {
										() -> () in
										self?.navigationController?.popViewControllerAnimated(true)
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
        if force || !self._query.executedValue || paging {
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

