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
        self.contentViewName = "MessageView"
        self.showEmptyLabel = false
        self.showProgress = true
        self.progressOffset = 80
        
        /* Use cached entity if available in the data model */
        if self.entityId != nil {
            if let entity: Entity? = Entity.fetchOneById(self.entityId!, inManagedObjectContext: DataController.instance.managedObjectContext) {
                self.entity = entity
            }
        }
        
        /* Use cached query if available in the data model */
        let id = "query.\(self.entityId!)"
        let query: Query? = Query.fetchOneById(id, inManagedObjectContext: DataController.instance.managedObjectContext)
        if query != nil {
            self._query = query
            self.showProgress = false
            if query!.moreValue {
//                self.tableView.addInfiniteScrollWithHandler({
//                    [weak self] (scrollView) -> Void in
//                    self?.bindQueryItems(false, paging: true)
//                    })
            }
        }
        
        super.viewDidLoad()
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    override func query() -> Query {
        
        if self._query == nil {
            
            let id = "query.\(self.entityId!)"
            var query: Query? = Query.fetchOneById(id, inManagedObjectContext: DataController.instance.managedObjectContext)
            
            if query == nil {
                query = Query.fetchOrInsertOneById(id, inManagedObjectContext: DataController.instance.managedObjectContext) as Query
                query!.name = self.queryName
                query!.pageSize = DataController.proxibase.pageSizeDefault
                query!.parameters = [:]
                if entity != nil {
                    query!.parameters["entity"] = self.entity
                }
                if entityId != nil {
                    query!.parameters["entityId"] = self.entityId
                }
                DataController.instance.saveContext()
            }
            
            self._query = query
        }
        
        return self._query
    }
    
    internal func bind(force: Bool = false) {
        
        /* Refreshes the top object but not the message list */
        DataController.instance.withEntityId(self.entityId!, refresh: force) {
            entity, error in
            
            self.refreshControl?.endRefreshing()
			
            if error == nil {
                if entity != nil {
					
					/* Refresh list too */
					if entity!.refreshedValue {
						entity!.refreshedValue = false
						self.bindQueryItems(true)
					}
					
                    self.entity = entity
                    self.entityId = entity!.id_
                    if let patch = entity as? Patch {
                        DataController.instance.currentPatch = patch    // Used for context for messages
                    }
                    self.drawButtons()
                    self.draw()
                }
                else {
                    Shared.Toast("Item has been deleted")
                    Utils.delay(2.0, closure: {
                        () -> () in
                        self.navigationController?.popViewControllerAnimated(true)
                    })
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
	
	/*--------------------------------------------------------------------------------------------
	* Cells
	*--------------------------------------------------------------------------------------------*/
	
	override func bindCell(cell: UITableViewCell, object: AnyObject, location: CLLocation?) -> UIView? {
		
		if let view = super.bindCell(cell, object: object, location: location) as? MessageView {
			/* Hookup up delegates */
			if let label = view.description_ as? TTTAttributedLabel {
				label.delegate = self
			}
			if !self.patchNameVisible {
				view.patchNameHeight.constant = 0
			}
			view.delegate = self
		}
		return nil
	}
}

extension BaseDetailViewController: TTTAttributedLabelDelegate {
    
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        UIApplication.sharedApplication().openURL(url)
    }
}

extension BaseDetailViewController: ViewDelegate {
    
    func view(container: UIView, didTapOnView view: UIView) {
        if let view = view as? AirImageView, container = container as? MessageView {
            if view.image != nil {
                Shared.showPhotoBrowser(view.image, view: view, viewController: self, entity: container.entity)
            }
        }
    }
}

extension BaseDetailViewController {
    /*
     * UITableViewDelegate 
     *
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
	
	override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		/*
		* Using an estimate significantly improves table view load time but we can get
		* small scrolling glitches if actual height ends up different than estimated height.
		* So we try to provide the best estimate we can and still deliver it quickly.
		*
		* Note: Called once only for each row in fetchResultController when FRC is making a data pass in
		* response to managedContext.save.
		*/
		let minHeight: CGFloat = 76
		var height: CGFloat = 76    // Base size if no description or photo
		
		if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem,
			let entity = queryResult.object as? Entity {
				
				let columnWidth: CGFloat = UIScreen.mainScreen().bounds.size.width - (24 /* spacing */ + 48 /* user photo */)
				if entity.description_ != nil {
					let description = entity.description_ as NSString
					let attributes = [NSFontAttributeName: UIFont(name:"HelveticaNeue-Light", size: 17)!]
					/* Most time is spent here */
					let rect: CGRect = description.boundingRectWithSize(CGSizeMake(columnWidth, CGFloat.max), options: [.UsesLineFragmentOrigin, .TruncatesLastVisibleLine], attributes: attributes, context: nil)
					height += rect.height
				}
				
				if entity.photo != nil {
					/* This relies on sizing and spacing of the message view */
					height += CGFloat(Int(columnWidth * 0.5625))  // 16:9 aspect ratio
				}
				
				if entity.description_ != nil && entity.photo != nil {
					height += 8
				}
		}
		
		if minHeight > height {
			height = minHeight
		}
		
		return CGFloat(height)
	}
}

