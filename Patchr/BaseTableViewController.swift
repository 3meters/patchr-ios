//
//  QueryTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-22.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class BaseTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var _query: Query!
    var progress: AirProgress?
    var showEmptyLabel: Bool = true
    var showProgress: Bool = true
    var progressOffset = Float(0)
    var processingQuery: Bool = false
    var emptyLabel: AirLabel = AirLabel(frame: CGRectMake(100, 100, 100, 100))
    var emptyMessage: String?
    var offscreenCells:       NSMutableDictionary = NSMutableDictionary()
	
	var contentViewName: String?
	var ignoreNextUpdates: Bool = false
	var rowAnimation: UITableViewRowAnimation = .Fade
	
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
	override func viewDidLoad() {
		super.viewDidLoad()
		
        /* Hookup refresh control */
		let refreshControl = UIRefreshControl()
        refreshControl.tintColor = Colors.brandColor
		refreshControl.addTarget(self, action: "pullToRefreshAction:", forControlEvents: UIControlEvents.ValueChanged)
		self.refreshControl = refreshControl
        
        /* Wacky activity control for body */
        if self.showProgress {
            if let controller = UIViewController.topMostViewController() {
                self.progress = AirProgress.showHUDAddedTo(controller.view, animated: true)
                self.progress!.mode = MBProgressHUDMode.Indeterminate
                self.progress!.styleAs(.ActivityOnly)
                self.progress!.yOffset = self.progressOffset
                self.progress!.minShowTime = 1.0
                self.progress!.removeFromSuperViewOnHide = false
                self.progress!.userInteractionEnabled = false
            }
        }
        
        /* Empty label */
        if self.showEmptyLabel {
            self.emptyLabel.alpha = 0
            self.emptyLabel.layer.borderWidth = 1
            self.emptyLabel.layer.borderColor = Colors.hintColor.CGColor
            self.emptyLabel.font = UIFont(name: "HelveticaNeue-Light", size: 19)
            self.emptyLabel.text = self.emptyMessage
            self.emptyLabel.bounds.size.width = 160
            self.emptyLabel.bounds.size.height = 160
            self.emptyLabel.numberOfLines = 0
            
            self.view.addSubview(self.emptyLabel)
            
            self.emptyLabel.center = CGPointMake(UIScreen.mainScreen().bounds.size.width / 2, (UIScreen.mainScreen().bounds.size.height / 2) - 44);
            self.emptyLabel.textAlignment = NSTextAlignment.Center
            self.emptyLabel.textColor = UIColor(red: CGFloat(0.6), green: CGFloat(0.6), blue: CGFloat(0.6), alpha: CGFloat(1))
            self.emptyLabel.layer.backgroundColor = UIColor.whiteColor().CGColor
            self.emptyLabel.layer.cornerRadius = self.emptyLabel.bounds.size.width / 2
        }
        
        /* A bit of UI tweaking */
        self.tableView.backgroundColor = Colors.windowColor
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None;
        self.tableView.separatorInset = UIEdgeInsetsZero
        self.clearsSelectionOnViewWillAppear = false;
	}

	override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)  // Triggers data fetch
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRowAtIndexPath(indexPath, animated: animated)
		}
	}
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if !self.query().executedValue {
            self.bindQueryItems(false)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.progress?.hide(false)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.progress?.hide(false)
        self.refreshControl?.endRefreshing()
        self.tableView.finishInfiniteScroll()
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    func pullToRefreshAction(sender: AnyObject?) -> Void {
        self.bindQueryItems(true, paging: false)
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func bindQueryItems(force: Bool = false, paging: Bool = false) {
        
        if self.processingQuery {
            return
        }
        
        if !self.refreshControl!.refreshing && !self.query().executedValue {
            self.progress?.show(true)
        }
        
        if self.showEmptyLabel && self.emptyLabel.alpha > 0 {
            self.emptyLabel.fadeOut()
        }
        
        /*
         * Check to see of any subclass wants to inject using the sidecar. Currently
         * used to add locally cached nearby notifications.
         */
        if !paging {
            populateSidecar(query())
        }
        
        self.processingQuery = true
        
        DataController.instance.refreshItemsFor(query(), force: force, paging: paging, completion: {
            [weak self] results, query, error in
            
            // Delay seems to be necessary to avoid visual glitch with UIRefreshControl
            Utils.delay(0.5, closure: {
                
                self?.processingQuery = false
                self?.progress?.hide(true)
                self?.refreshControl?.endRefreshing()
                self?.tableView.finishInfiniteScroll()
                
                if query.moreValue {
                    self?.tableView.addInfiniteScrollWithHandler({(scrollView) -> Void in
                        self?.bindQueryItems(false, paging: true)
                    })
                }
                else {
                    self?.tableView.removeInfiniteScroll()
                }
                
                if error == nil {
                    self?.query().executedValue = true
                    if let fetchedObjects = self?.fetchedResultsController.fetchedObjects as [AnyObject]? {
                        self?.query().offsetValue = Int32(fetchedObjects.count)
                        if self?.emptyLabel != nil && fetchedObjects.count == 0 {
                            self?.emptyLabel.fadeIn()
                        }
                    }
                }
                return
            })
        })
    }
    
    func populateSidecar(query: Query) { }

	func query() -> Query {
		preconditionFailure("This method must be overridden in subclass")
	}
	
	/*--------------------------------------------------------------------------------------------
	* Cells
	*--------------------------------------------------------------------------------------------*/
	
	func buildCell(contentViewName: String) -> UITableViewCell {
		/*
		 * Only implementation. Called externally to measure variable row heights.
		 */
		let cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: CELL_IDENTIFIER)
		cell.separatorInset = UIEdgeInsetsZero
		cell.layer.shouldRasterize = true
		cell.layer.rasterizationScale = UIScreen.mainScreen().scale
		
		if #available(iOS 8.0, *) {
			cell.layoutMargins = UIEdgeInsetsZero
			cell.preservesSuperviewLayoutMargins = false
		}
		
		let view = NSBundle.mainBundle().loadNibNamed(contentViewName, owner: self, options: nil)[0] as! BaseView
		cell.injectView(view)
		
		/* We need to set the initial width so later sizing logic has it to work with */
		cell.frame = CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 100)
		cell.contentView.frame = CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 100)
		view.frame = CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 100)
		
		configureCell(cell) // Handles contraint and layout updates
		
		return cell
	}
	
	func configureCell(cell: UITableViewCell) {
		/*
		* Default is to constrain to a tight fit. Override this in subclasses to do
		* do something else. Without this the view size explodes.
		*/
		let view = cell.contentView.viewWithTag(1) as! BaseView
		let views = Dictionary(dictionaryLiteral: ("view", view))
		let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: views)
		let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: [], metrics: nil, views: views)
		cell.contentView.addConstraints(horizontalConstraints)
		cell.contentView.addConstraints(verticalConstraints)
		
		cell.setNeedsUpdateConstraints()
		cell.updateConstraintsIfNeeded()
		cell.contentView.setNeedsLayout()
		cell.contentView.layoutIfNeeded()
	}
	
	func bindCell(cell: UITableViewCell, object: AnyObject) {
		preconditionFailure("bindCell must be overridden by subclasses")
	}
	
	/*--------------------------------------------------------------------------------------------
	* Properties
	*--------------------------------------------------------------------------------------------*/
	
    internal lazy var fetchedResultsController: NSFetchedResultsController = {
		/*
		* Creates controller instance first time the field is accessed.
		*/
        let fetchRequest = NSFetchRequest(entityName: QueryItem.entityName())
		
        let query: Query = self.query()
		
        if query.name == DataStoreQueryName.NearbyPatches.rawValue {
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "distance", ascending: true)
            ]
        }
        else if query.name == DataStoreQueryName.NotificationsForCurrentUser.rawValue {
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "sortDate", ascending: false)
            ]
        }
        else {
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "position", ascending: true),
                NSSortDescriptor(key: "sortDate", ascending: false)
            ]
        }
        
        fetchRequest.predicate = NSPredicate(format: "query == %@", query)
        
        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: DataController.instance.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        do {
            try controller.performFetch() // Ensure that the controller can be accessed without blowing up
        }
        catch {
            fatalError("Fetch error: \(error)")
        }
        
        controller.delegate = self
        
        return controller
    }()
}

extension BaseTableViewController {
	/*
	 * UITableViewDataSource
	 */
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let numberOfObjects = self.fetchedResultsController.sections![section].numberOfObjects
		self.tableView.separatorStyle = numberOfObjects == 0 ? .None : .SingleLine
		return numberOfObjects
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		
		var cell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER)
		
		if cell == nil {
			cell = buildCell(self.contentViewName!)
		}
		
		/* Get the data object to bind the cell to */
		let queryResult = self.fetchedResultsController.sections![indexPath.section].objects![indexPath.row] as! QueryItem
		
		/* Bind the cell */
		bindCell(cell!, object: queryResult.object)
		
		return cell!
	}
}

extension BaseTableViewController {
	/*
	 * NSFetchedResultsControllerDelegate
	 */
	func controllerWillChangeContent(controller: NSFetchedResultsController) {
		self.tableView.beginUpdates()
	}
	
	func controllerDidChangeContent(controller: NSFetchedResultsController) {
		self.tableView.endUpdates()
	}
	
	/*
	* DidChangeSection
	*/
	func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
		switch type {
		case .Insert:
			self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
			
		case .Delete:
			self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
			
		default:
			return
		}
	}
	
	/*
	* DidChangeObject
	*/
	func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
		/*
		 * http://stackoverflow.com/a/32978387
		 * iOS 9 introduced a bug where didChangeObject can be called with an
		 * invalid change type.
		 */
		guard type.rawValue != 0 else {
			return
		}
		
		switch type {
			
		case .Insert:	// 1
			self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: self.rowAnimation)
			
		case .Delete:	// 2
			self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: self.rowAnimation)
			
		case .Move:		// 3
			self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: self.rowAnimation)
			self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: self.rowAnimation)
			
		case .Update:	// 4
			if let cell = self.tableView.cellForRowAtIndexPath(indexPath!) {
				let queryResult = anObject as! QueryItem
				bindCell(cell, object: queryResult.object)
			}
		}
	}
}
