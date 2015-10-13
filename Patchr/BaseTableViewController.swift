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
	var activity: UIActivityIndicatorView?
    var showEmptyLabel: Bool = true
    var showProgress: Bool = true
    var progressOffset = Float(-40)
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
		
		/* Simple activity indicator */
		self.activity = addActivityIndicatorTo(self.view, offsetY: self.progressOffset)
		
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
		
		/*
		* Self-sizing table view cells in iOS 8 are enabled when the estimatedRowHeight property of
		* the table view is set to a non-zero value. Setting the estimated row height prevents the
		* table view from calling tableView:heightForRowAtIndexPath: for every row in the table on
		* first load; it will only be called as cells are about to scroll onscreen. This is a major
		* performance optimization.
		*/
		self.tableView.estimatedRowHeight = 300
		
		/* Self sizing table view cells require this setting */
		self.tableView.rowHeight = UITableViewAutomaticDimension
		
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
		/*
		* Called when switching between patch view controllers.
		*/
        super.viewWillDisappear(animated)
		self.activity?.stopAnimating()
    }
    
    override func viewDidDisappear(animated: Bool) {
		/*
		 * Called when switching between patch view controllers.
		 */
        super.viewDidDisappear(animated)
		self.activity?.stopAnimating()
        self.refreshControl?.endRefreshing()
//		self.tableView.finishInfiniteScroll()
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
			/* Wacky activity control for body */
			if self.showProgress {
				self.activity?.startAnimating()
			}
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
				self?.activity?.stopAnimating()
                self?.refreshControl?.endRefreshing()
//				self?.tableView.finishInfiniteScroll()
				
//                if query.moreValue {
//                    self?.tableView.addInfiniteScrollWithHandler({(scrollView) -> Void in
//                        self?.bindQueryItems(false, paging: true)
//                    })
//                }
//                else {
//                    self?.tableView.removeInfiniteScroll()
//                }
				
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
		cell.layer.shouldRasterize = true		// Faster layout animations
		cell.layer.rasterizationScale = UIScreen.mainScreen().scale
		
		cell.layoutMargins = UIEdgeInsetsZero
		cell.preservesSuperviewLayoutMargins = false
		
		/* Inject view into contentView */
		let view = NSBundle.mainBundle().loadNibNamed(contentViewName, owner: self, options: nil)[0] as! BaseView
		view.tag = 1
		view.cell = cell
		view.translatesAutoresizingMaskIntoConstraints = false
		cell.contentView.addSubview(view)
		
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
		
		
		if self.isKindOfClass(PatchTableViewController) {
			cell.contentView.backgroundColor = Colors.windowColor
			let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-8-[view]-8-|", options: [], metrics: nil, views: views)
			let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-8-[view]|", options: [], metrics: nil, views: views)
			cell.contentView.addConstraints(horizontalConstraints)
			cell.contentView.addConstraints(verticalConstraints)
		}
		else {
			let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: views)
			let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: [], metrics: nil, views: views)
			cell.contentView.addConstraints(horizontalConstraints)
			cell.contentView.addConstraints(verticalConstraints)
		}
		
		cell.setNeedsUpdateConstraints()
		cell.updateConstraintsIfNeeded()
		cell.contentView.setNeedsLayout()
		cell.contentView.layoutIfNeeded()
	}
	
	func bindCell(cell: UITableViewCell, object: AnyObject, location: CLLocation?) -> UIView? {
		
		if let view = cell.contentView.viewWithTag(1) {
			if self.isKindOfClass(NotificationsTableViewController) {
				Notification.bindView(view, object: object)
			}
			else if self.isKindOfClass(BaseDetailViewController) {
				Message.bindView(view, object: object)
			}
			else if self.isKindOfClass(PatchTableViewController) {
				Patch.bindView(view, object: object, location: location)
			}
			else if self.isKindOfClass(UserTableViewController) {
				User.bindView(view, object: object)
			}
			
//			view.setNeedsUpdateConstraints()
//			view.updateConstraintsIfNeeded()
//			cell.contentView.setNeedsUpdateConstraints()
//			cell.contentView.updateConstraints()
//			
//			cell.setNeedsUpdateConstraints()
//			cell.updateConstraintsIfNeeded()
//			cell.contentView.setNeedsLayout()
//			cell.contentView.layoutIfNeeded()
			
			return view
		}
		return nil
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
		bindCell(cell!, object: queryResult.object, location: nil)
		
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
				bindCell(cell, object: queryResult.object, location: nil)
			}
		}
	}
}
