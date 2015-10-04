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
                self.tableView.addInfiniteScrollWithHandler({
                    [weak self] (scrollView) -> Void in
                    self?.bindQueryItems(force: false, paging: true)
                    })
            }
        }
        
        super.viewDidLoad()
        
        /* UI prep */
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None;
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
                DataController.instance.managedObjectContext.save(nil)
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
            super.bindQueryItems(force: force, paging: paging)
        }
    }
    
    internal func draw() {
        assert(false, "This method must be overridden in subclass")
    }
    
    internal func drawButtons() { /* Optional */ }
    
    override func bindCell(cell: UITableViewCell, object: AnyObject, tableView: UITableView?) {
        
        let view = cell.contentView.viewWithTag(1) as! MessageView
        Message.bindView(view, object: object, tableView: tableView, sizingOnly: false)
        if let label = view.description_ as? TTTAttributedLabel {
            label.delegate = self
        }
        if !self.patchNameVisible {
            view.patchNameHeight.constant = 0
        }
        view.delegate = self
    }
    
    override func pullToRefreshAction(sender: AnyObject?) -> Void {
        self.bind(force: true)
        self.bindQueryItems(force: true, paging: false)
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

extension  BaseDetailViewController: UITableViewDelegate {
    /*
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
         */
        var height: CGFloat = 86    // Base size if no description or photo
        if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem,
            let entity = queryResult.object as? Entity {
                let columnWidth: CGFloat = UIScreen.mainScreen().bounds.size.width - (24 /* spacing */ + 48 /* user photo */)
                if entity.description_ != nil {
                    let description = entity.description_ as NSString
                    let attributes = [NSFontAttributeName: UIFont(name:"HelveticaNeue-Light", size: 17)!]
                    let rect: CGRect = description.boundingRectWithSize(CGSizeMake(columnWidth, CGFloat.max), options: .UsesLineFragmentOrigin, attributes: attributes, context: nil)
                    height += rect.height
                }
                if entity.photo != nil {
                    /* This relies on sizing and spacing of the message view */
                    height += 8 + (columnWidth * 0.5625)  // 16:9 aspect ratio
                }
        }

        return CGFloat(height)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        // https://github.com/smileyborg/TableViewCellWithAutoLayout
        
        var cell = self.offscreenCells.objectForKey(CELL_IDENTIFIER) as? UITableViewCell
        
        if cell == nil {
            cell = buildCell(self.contentViewName!)
            configureCell(cell!)
            self.offscreenCells.setObject(cell!, forKey: CELL_IDENTIFIER)
        }
        
        /* Bind view to data for this row */
        let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as! QueryItem
        let view = Message.bindView(cell!.contentView.viewWithTag(1)!, object: queryResult.object, tableView: tableView, sizingOnly: true) as! MessageView
        if !self.patchNameVisible {
            view.patchNameHeight.constant = 0
        }
        
        /* Get the actual height required for the cell */
        var height = cell!.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height + 1
        
        return height
    }
}

