//
//  QueryTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-22.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class BaseTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
	
    var query				: Query!
	var processingQuery		= false
	var listType			: ItemClass = .Patches
	/*
	 * Used to monitor whether list is stale because context entity has a fresher activityDate.
	 * For lists without a standard context entity, we use the DataController as a proxy. That
	 * includes nearby, notifications, and explore. We also use DataController as a proxy for
	 * owned and watching just as an optimization.
	 */
	var firstAppearance		= true

	var activity			= UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
	var footerView			= UIView()
	var loadMoreButton		= UIButton(type: UIButtonType.RoundedRect)
	var loadMoreActivity	= UIActivityIndicatorView(activityIndicatorStyle: .White)
	var loadMoreMessage		= "LOAD MORE"
	
	var emptyLabel			= AirLabel(frame: CGRectZero)
	var emptyMessage:		String?
    var showEmptyLabel		= true
    var showProgress		= true
    var progressOffsetY     = Float(-48)
	var progressOffsetX     = Float(8)

	var rowHeights			: NSMutableDictionary = [:]
	
    /*--------------------------------------------------------------------------------------------
    * MARK:- Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
        /* Hookup refresh control */
		self.refreshControl = UIRefreshControl()
        self.refreshControl!.tintColor = Theme.colorActivityIndicator
		self.refreshControl?.addTarget(self, action: "pullToRefreshAction:", forControlEvents: UIControlEvents.ValueChanged)
		
		/* Simple activity indicator (frame sizing) */
		self.activity.color = Theme.colorActivityIndicator
		self.activity.hidesWhenStopped = true
		self.view.addSubview(activity)
		
		/* Footer */
		self.loadMoreButton.tag = 1
		self.loadMoreButton.backgroundColor = Theme.colorBackgroundTile
		self.loadMoreButton.layer.cornerRadius = 8
		self.loadMoreButton.addTarget(self, action: Selector("loadMore:"), forControlEvents: UIControlEvents.TouchUpInside)
		self.loadMoreButton.setTitle(self.loadMoreMessage, forState: .Normal)
		self.footerView.addSubview(self.loadMoreButton)
		
		self.loadMoreActivity.tag = 2
		self.loadMoreActivity.color = Theme.colorActivityIndicator
		self.loadMoreActivity.hidden = true
		
		self.footerView.frame.size.height = CGFloat(48 + 16)
		self.footerView.addSubview(self.loadMoreActivity)
		self.footerView.backgroundColor = Theme.colorBackgroundTileList
		
        /* Empty label */
        if self.showEmptyLabel {
            self.emptyLabel.alpha = 0
            self.emptyLabel.layer.borderWidth = 1
            self.emptyLabel.layer.borderColor = Theme.colorRule.CGColor
			self.emptyLabel.layer.backgroundColor = Theme.colorBackgroundEmptyBubble.CGColor
			self.emptyLabel.layer.cornerRadius = 80
            self.emptyLabel.font = Theme.fontTextDisplay
            self.emptyLabel.text = self.emptyMessage
            self.emptyLabel.numberOfLines = 0
			self.emptyLabel.insets = UIEdgeInsetsMake(16, 16, 16, 16)
			self.emptyLabel.textAlignment = NSTextAlignment.Center
			self.emptyLabel.textColor = Theme.colorTextPlaceholder
			
            self.tableView.addSubview(self.emptyLabel)
        }
		
		/*
		* Setting the estimated row height prevents the table view from calling 
		* tableView:heightForRowAtIndexPath: for every row in the table on
		* first load; it will only be called as cells are about to scroll onscreen. 
		* This is a major performance optimization.
		*/
		self.tableView.estimatedRowHeight = 136
		
		/* Self sizing table view cells require this setting */
		self.tableView.rowHeight = 136
		
        /* A bit of UI tweaking */
        self.tableView.backgroundColor = Theme.colorBackgroundWindow
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None;
        self.tableView.separatorInset = UIEdgeInsetsZero
        self.clearsSelectionOnViewWillAppear = false;
		
		/* Hookup query */
		self.query = loadQuery()
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "willFetchQuery:", name: Events.WillFetchQuery, object: self)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "didFetchQuery:", name: Events.DidFetchQuery, object: self)
	}
	
	override func viewWillLayoutSubviews() {
		/*
		* Called right after viewWillAppear. Gets called
		* multiple times during appearance cycle.
		*/
		super.viewWillLayoutSubviews()
		
		let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.bounds.size.width)
		self.tableView.bounds.size.width = viewWidth
		self.view.fillSuperview()
		
		self.footerView.frame.size.height = CGFloat(48 + 16)
		self.loadMoreButton.anchorTopCenterFillingWidthWithLeftAndRightPadding(8, topPadding: 8, height: 48)
		self.loadMoreActivity.anchorTopCenterWithTopPadding(8, width: 48, height: 48)
		
		self.activity.anchorInCenterWithWidth(20, height: 20)
		self.activity.frame.origin.y += CGFloat(self.progressOffsetY)
		self.activity.frame.origin.x += CGFloat(self.progressOffsetX)
		
		let statusHeight = UIApplication.sharedApplication().statusBarFrame.size.height
		let navHeight = self.navigationController?.navigationBar.height() ?? 0
		self.emptyLabel.anchorInCenterWithWidth(160, height: 160)
		self.emptyLabel.frame.origin.y -= (statusHeight + navHeight)
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated) // Base implementation does nothing
		
		self.refreshControl!.endRefreshing()
		try! self.fetchedResultsController.performFetch()
		self.tableView.reloadData()		// Reload cells so any changes while gone will show
		
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRowAtIndexPath(indexPath, animated: animated)
		}
	}
	
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
		
		if self.query.executedValue {
			if self.query.moreValue {
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
			else {
				self.tableView.tableFooterView = nil
			}
			self.tableView.setNeedsLayout()
		}
		else {
			try! self.fetchedResultsController.performFetch()
		}
		
		self.firstAppearance = false
    }
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
	}

    override func viewDidDisappear(animated: Bool) {
		/*
		 * Called when switching between patch view controllers.
		 */
		super.viewDidDisappear(animated)
		self.activity.stopAnimating()
		if self.refreshControl!.refreshing {
			refreshControl!.endRefreshing()
		}
    }
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

    /*--------------------------------------------------------------------------------------------
    * MARK:- Events
    *--------------------------------------------------------------------------------------------*/
    
    func pullToRefreshAction(sender: AnyObject?) -> Void {
		Utils.delay(0.5) {	// Give the refresh animation to settle before party on the main thread
			self.fetchQueryItems(force: true, paging: false, queryDate: self.getActivityDate())
		}
    }
	
	func photoAction(sender: AnyObject?) {
		
		if let control = sender as? AirImageView, let container = sender?.superview as? BaseView {
			if control.image != nil {
				Shared.showPhotoBrowser(control.image, animateFromView: control, viewController: self, entity: container.entity)
			}
		}
		
		if let control = sender as? UIButton, let container = sender?.superview as? BaseView {
			if control.imageView!.image != nil {
				Shared.showPhotoBrowser(control.imageView!.image, animateFromView: control, viewController: self, entity: container.entity)
			}
		}
	}
	
	func willFetchQuery(notification: NSNotification) {
		if !self.refreshControl!.refreshing && !self.query.executedValue {
			/* Wacky activity control for body */
			if self.showProgress {
				self.activity.startAnimating()
			}
		}
		
		if self.showEmptyLabel && self.emptyLabel.alpha > 0 {
			self.emptyLabel.fadeOut()
		}
	}
	
	func didFetchQuery(notification: NSNotification) {
		self.activity.stopAnimating()
		if let userInfo = notification.userInfo where userInfo["count"] != nil {
			if self.showEmptyLabel && userInfo["count"] as! Int == 0 {
				self.emptyLabel.fadeIn()
			}
		}
		
		if self.query.moreValue {
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
		else {
			self.tableView.tableFooterView = nil
		}
	}
	
    /*--------------------------------------------------------------------------------------------
    * MARK:- Methods
    *--------------------------------------------------------------------------------------------*/
	
	func loadMore(sender: AnyObject?) {
		
		if let button = self.footerView.viewWithTag(1) as? UIButton,
			spinner = self.footerView.viewWithTag(2) as? UIActivityIndicatorView {
				button.hidden = true
				spinner.hidden = false
				spinner.startAnimating()
		}
		
		self.fetchQueryItems(force: false, paging: true, queryDate: nil)
	}

	func fetchQueryItems(force force: Bool, paging: Bool, queryDate: Int64?) {
        
        guard !self.processingQuery else {
            return
        }
        
		self.processingQuery = true
		
		NSNotificationCenter.defaultCenter().postNotificationName(Events.WillFetchQuery, object: self, userInfo: nil)
        /*
         * Check to see of any subclass wants to inject using the sidecar. Currently
         * used to add locally cached nearby notifications.
         */
        if !paging {
            populateSidecar(self.query)
        }
		
		let queryObjectId = self.query.objectID
		
		DataController.instance.backgroundOperationQueue.addOperationWithBlock {
			
			DataController.instance.refreshItemsFor(queryObjectId, force: force, paging: paging, completion: {
				[weak self] results, query, error in
				
				NSOperationQueue.mainQueue().addOperationWithBlock {
					
					if let refreshControl = self?.refreshControl where refreshControl.refreshing {
						refreshControl.endRefreshing()
					}
					
					// Delay seems to be necessary to avoid visual glitch with UIRefreshControl
					Utils.delay(0.5) {
						
						self?.processingQuery = false
						var userInfo: [NSObject:AnyObject] = ["error": (error != nil)]
						
						let query = DataController.instance.mainContext.objectWithID(queryObjectId) as! Query
						
						if error == nil {
							query.executedValue = true
							if queryDate != nil {
								query.activityDateValue = queryDate!
							}
							if self?.fetchedResultsController.delegate != nil {	// Delegate is unset when view controller disappears
								if let fetchedObjects = self?.fetchedResultsController.fetchedObjects as [AnyObject]? {
									query.offsetValue = Int32(fetchedObjects.count)
									userInfo["count"] = fetchedObjects.count
								}
							}
							/* Find oldest (smallest) date in the set */
							var oldestDate = NSDate()
							for item in query.queryItems {
								if let queryItem = item as? QueryItem,
									let entity = queryItem.object as? Entity,
									let sortDate = entity.sortDate {
									if sortDate < oldestDate {
										oldestDate = sortDate
									}
								}
							}
							query.offsetDate = oldestDate
							/*
							 * Saving commits changes to the data model and the fetch controller notices
							 * if that changes the results it has associated with it's fetch request.
							 * The fetched results delegate is informed of any changes that should
							 * cause an update to the table view.
							 */
							DataController.instance.saveContext(false)
							self?.tableView.reloadData()		// Update cells to show any changes
						}
						
						if self != nil {
							NSNotificationCenter.defaultCenter().postNotificationName(Events.DidFetchQuery, object: self!, userInfo: userInfo)
						}
						
						return
					}
				}
			})
		}
    }
	
	func didRefreshItems(query: Query) { }
	
    func populateSidecar(query: Query) { }

	func loadQuery() -> Query {
		preconditionFailure("This method must be overridden in subclass")
	}
	
	func getActivityDate() -> Int64 {
		preconditionFailure("This method must be overridden in subclass")
	}
	
	/*--------------------------------------------------------------------------------------------
	* MARK:- Properties
	*--------------------------------------------------------------------------------------------*/
	
    internal lazy var fetchedResultsController: NSFetchedResultsController = {
		/*
		* Creates controller instance first time the field is accessed.
		*/
        let fetchRequest = NSFetchRequest(entityName: QueryItem.entityName())
		
        if self.query.name == DataStoreQueryName.NearbyPatches.rawValue {
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "distance", ascending: true)
            ]
        }
        else if self.query.name == DataStoreQueryName.NotificationsForCurrentUser.rawValue {
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
        
        fetchRequest.predicate = NSPredicate(format: "query == %@", self.query)
		fetchRequest.fetchBatchSize = 20
        
        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: DataController.instance.mainContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        controller.delegate = self
        
        return controller
    }()
}

extension BaseTableViewController {
	/*
	 * Cells
	 */
	func makeCell(cellType: CellType = .TextAndPhoto) -> WrapperTableViewCell {
		/*
		* Only implementation. Called externally to measure variable row heights.
		*/
		if self.listType == .Notifications {
			let view = NotificationView(cellType: cellType)
			let cell = WrapperTableViewCell(view: view, padding: UIEdgeInsetsMake(12, 12, 12, 12), reuseIdentifier: cellType.rawValue)
			return cell
		}
		else if self.listType == .Messages {
			let view = MessageView(cellType: cellType, entity: nil)
			let cell = WrapperTableViewCell(view: view, padding: UIEdgeInsetsMake(12, 12, 12, 12), reuseIdentifier: cellType.rawValue)
			return cell
		}
		else if self.listType == .Patches {
			let view = PatchView(frame: CGRectMake(0, 0, self.view.width(), 136))
			view.cornerRadius = 6
			let cell = WrapperTableViewCell(view: view, padding: UIEdgeInsetsMake(8, 8, 0, 8), reuseIdentifier: cellType.rawValue)
			cell.separator.backgroundColor = Colors.clear
			cell.backgroundColor = Theme.colorBackgroundTileList
			return cell
		}
		else if self.listType == .Users {
			let view = UserView(frame: CGRectMake(0, 0, self.view.width(), 97))
			let cell = WrapperTableViewCell(view: view, padding: UIEdgeInsetsMake(8, 8, 8, 8), reuseIdentifier: cellType.rawValue)
			cell.selectionStyle = .None
			return cell
		}
		else {
			return WrapperTableViewCell(view: UIView(), padding: UIEdgeInsetsZero, reuseIdentifier: cellType.rawValue)
		}
	}
	
	func bindCell(cell: WrapperTableViewCell, entity: AnyObject, location: CLLocation?) -> UIView? {
		
		if self.listType == .Notifications {
			let notificationView = cell.view! as! NotificationView
			notificationView.bindToEntity(entity)
			return notificationView
		}
		
		if self.listType == .Messages {
			let messageView = cell.view! as! MessageView
			messageView.bindToEntity(entity)
			return messageView
		}
		
		if self.listType == .Patches {
			let patchView = cell.view! as! PatchView
			patchView.bindToEntity(entity, location: location)
			return patchView
		}
		
		if self.listType == .Users {
			let userView = cell.view! as! UserView
			userView.bindToEntity(entity)
			return userView
		}
		
		return nil
	}
	
	/*
	 * UITableViewDataSource
	 */
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let numberOfObjects = self.fetchedResultsController.sections?[section].numberOfObjects ?? 0
		return numberOfObjects
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		
		/* Bind the cell to the entity */
		let queryResult = self.fetchedResultsController.sections![indexPath.section].objects![indexPath.row] as? QueryItem
		let entity = queryResult!.object as? Entity
				
		var cellType: CellType = .TextAndPhoto
		
		if self.listType == .Notifications {
			let notification = entity as! Notification
			if notification.photoBig == nil {
				cellType = .Text
			}
			else if notification.summary == nil {
				cellType = .Photo
			}
		}
		else if self.listType == .Messages {
			let message = entity as! Message
			if message.type != nil && message.type == "share" {
				cellType = .Share
			}
			else if message.photo == nil {
				cellType = .Text
			}
			else if message.description_ == nil || message.description_.isEmpty {
				cellType = .Photo
			}
		}
		
		var cell = self.tableView.dequeueReusableCellWithIdentifier(cellType.rawValue) as! WrapperTableViewCell?
		
		if cell == nil {
			cell = makeCell(cellType)
		}
			
		bindCell(cell!, entity: entity!, location: nil)
		
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
				self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
			
			case .Delete:	// 2
				self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
				
			case .Move:		// 3
				self.tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)

			case .Update:	// 4
				self.tableView.cellForRowAtIndexPath(indexPath!)	// Better than reloadRowsAtIndexPaths because no animation
		}
	}
}

enum ItemClass {
	case Messages
	case Notifications
	case Patches
	case Users
}