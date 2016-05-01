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
	
	var emptyLabel			= AirLinkButton(frame: CGRectZero)
	var emptyMessage		: String?
    var showEmptyLabel		= true
    var showProgress		= true
    var progressOffsetY     = Float(-48)
	var progressOffsetX     = Float(8)
	var disableCells		= false

	/* Only used for row sizing */
	var rowHeights			: NSMutableDictionary = [:]
	var itemTemplate		: BaseView?
	var itemPadding			= UIEdgeInsetsZero
	
    /*--------------------------------------------------------------------------------------------
    * MARK:- Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
	override func viewDidLoad() {
		super.viewDidLoad()

        /* Hookup refresh control */
		self.refreshControl = UIRefreshControl()
		self.refreshControl?.accessibilityIdentifier = "refresh_control"
		self.refreshControl!.tintColor = Theme.colorActivityIndicator
		self.refreshControl?.addTarget(self, action: #selector(BaseTableViewController.pullToRefreshAction(_:)), forControlEvents: UIControlEvents.ValueChanged)
		self.refreshControl?.endRefreshing()

		/* Simple activity indicator (frame sizing) */
		self.activity.accessibilityIdentifier = "activity_view"
		self.activity.color = Theme.colorActivityIndicator
		self.activity.hidesWhenStopped = true
		self.view.addSubview(activity)

		/* Footer */
		self.loadMoreButton.tag = 1
		self.loadMoreButton.backgroundColor = Theme.colorBackgroundTile
		self.loadMoreButton.layer.cornerRadius = 8
		self.loadMoreButton.addTarget(self, action: #selector(BaseTableViewController.loadMore(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		self.loadMoreButton.setTitle(self.loadMoreMessage, forState: .Normal)
		self.footerView.addSubview(self.loadMoreButton)

		self.loadMoreActivity.tag = 2
		self.loadMoreActivity.accessibilityIdentifier = "activity_more"
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
            self.emptyLabel.titleLabel!.font = Theme.fontTextDisplay
            self.emptyLabel.titleLabel!.numberOfLines = 0
			self.emptyLabel.titleLabel!.textAlignment = NSTextAlignment.Center
			self.emptyLabel.titleEdgeInsets = UIEdgeInsetsMake(16, 16, 16, 16)
			self.emptyLabel.setTitle(self.emptyMessage, forState: .Normal)
			self.emptyLabel.setTitleColor(Theme.colorTextPlaceholder, forState: .Normal)

            self.tableView.addSubview(self.emptyLabel)
        }

		self.tableView.estimatedRowHeight = 100						// Zero turns off estimates
		self.tableView.rowHeight = UITableViewAutomaticDimension	// Actual height is handled in heightForRowAtIndexPath

        /* A bit of UI tweaking */
		self.tableView.accessibilityIdentifier = "table"
        self.tableView.backgroundColor = Theme.colorBackgroundTable
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None;
        self.tableView.separatorInset = UIEdgeInsetsZero

		/* Hookup query */
		self.query = loadQuery()

		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BaseTableViewController.willFetchQuery(_:)), name: Events.WillFetchQuery, object: self)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BaseTableViewController.didFetchQuery(_:)), name: Events.DidFetchQuery, object: self)
	}
	
	override func viewWillLayoutSubviews() {
		/*
		* Called right after viewWillAppear. Gets called
		* multiple times during appearance cycle.
		*/
		super.viewWillLayoutSubviews()
		
		let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.bounds.size.width)
		self.tableView.bounds.size.width = viewWidth
		
		self.footerView.frame.size.height = CGFloat(48 + 16)
		self.loadMoreButton.anchorTopCenterFillingWidthWithLeftAndRightPadding(8, topPadding: 8, height: 48)
		self.loadMoreActivity.anchorTopCenterWithTopPadding(8, width: 48, height: 48)
		
		self.activity.anchorInCenterWithWidth(20, height: 20)
		self.activity.frame.origin.y += CGFloat(self.progressOffsetY)
		self.activity.frame.origin.x += CGFloat(self.progressOffsetX)
		
		let navHeight = self.navigationController?.navigationBar.height() ?? 0
		let statusHeight = UIApplication.sharedApplication().statusBarFrame.size.height

		self.emptyLabel.anchorInCenterWithWidth(160, height: 160)
		self.emptyLabel.frame.origin.y -= (statusHeight + navHeight)
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated) // Base implementation does nothing
		
		try! self.fetchedResultsController.performFetch()
	}
	
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
		
		if self.query.executedValue {
			
			self.tableView.reloadData()		// Reload cells so any changes while gone will show
			
			/* Configure paging button in footer */
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
			
			/* Ensure that the tableview layout is current */
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
		self.refreshControl?.endRefreshing()
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
				UIShared.showPhotoBrowser(control.image, animateFromView: control, viewController: self, entity: container.entity)
			}
		}
		
		if let control = sender as? UIButton, let container = sender?.superview as? BaseView {
			if control.imageView!.image != nil {
				UIShared.showPhotoBrowser(control.imageView!.image, animateFromView: control, viewController: self, entity: container.entity)
			}
		}
	}
	
	func willFetchQuery(notification: NSNotification) {
		if (self.refreshControl == nil || !self.refreshControl!.refreshing) && !self.query.executedValue {
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
		var empty = false
		if let userInfo = notification.userInfo where userInfo["count"] != nil {
			if self.showEmptyLabel && userInfo["count"] as! Int == 0 {
				empty = true
			}
		}
		/*
		* HACK: We hide messages if the user is not a member of a private even if messages
		* were returned by the service because they are owned by the current user.
		*/
		if self.disableCells {
			empty = true
		}
	
		if empty {
			self.emptyLabel.fadeIn()
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
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
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
        
        guard !self.processingQuery else { return }
		guard !self.query.deleted else { return }
        
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
					
					self?.refreshControl?.endRefreshing()
					
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
							DataController.instance.saveContext(BLOCKING)
							self?.tableView.reloadData()		// Update cells to show any changes
							
							dispatch_async(dispatch_get_main_queue(), { () -> Void in
								if self != nil {
									NSNotificationCenter.defaultCenter().postNotificationName(Events.DidFetchQuery, object: self!, userInfo: userInfo)
								}								
							})
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
	
	func clearQueryItems() {
		self.query.queryItemsSet().removeAllObjects()
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
	
	func makeCell() -> WrapperTableViewCell {
		/*
		* Only implementation. Called externally to measure variable row heights.
		*/
		if self.listType == .Notifications {
			let view = NotificationView()
			let cell = WrapperTableViewCell(view: view, padding: self.itemPadding, reuseIdentifier: "cell")
			return cell
		}
		else if self.listType == .Messages {
			let view = MessageView()
			let cell = WrapperTableViewCell(view: view, padding: self.itemPadding, reuseIdentifier: "cell")
			if view.description_ != nil && view.description_!.isKindOfClass(TTTAttributedLabel) {
				let label = view.description_ as! TTTAttributedLabel
				label.delegate = self
			}
			view.photo?.addTarget(self, action: #selector(BaseTableViewController.photoAction(_:)), forControlEvents: .TouchUpInside)
			return cell
		}
		else if self.listType == .Patches {
			let view = PatchView(frame: CGRectMake(0, 0, self.view.width(), 136))
			view.cornerRadius = 6
			let cell = WrapperTableViewCell(view: view, padding: self.itemPadding, reuseIdentifier: "cell")
			cell.separator.backgroundColor = Colors.clear
			cell.backgroundColor = Theme.colorBackgroundTileList
			return cell
		}
		else if self.listType == .Users {
			let view = UserView(frame: CGRectMake(0, 0, self.view.width(), 97))
			let cell = WrapperTableViewCell(view: view, padding: self.itemPadding, reuseIdentifier: "cell")
			cell.selectionStyle = .None
			return cell
		}
		else {
			return WrapperTableViewCell(view: UIView(), padding: self.itemPadding, reuseIdentifier: "cell")
		}
	}
}

extension BaseTableViewController {
	/*
	 * Cells
	 */
	func bindCellToEntity(cell: WrapperTableViewCell, entity: AnyObject, location: CLLocation?) {
		
		if self.listType == .Notifications {
			let notificationView = cell.view! as! NotificationView
			notificationView.bindToEntity(entity, location: nil)
		}
		
		if self.listType == .Messages {
			let messageView = cell.view! as! MessageView
			messageView.bindToEntity(entity, location: nil)
		}
		
		if self.listType == .Patches {
			let patchView = cell.view! as! PatchView
			patchView.bindToEntity(entity, location: location)
		}
		
		if self.listType == .Users {
			let userView = cell.view! as! UserView
			userView.bindToEntity(entity, location: nil)
		}
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
		let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem
		let entity = queryResult!.object as? Entity
		var cell = self.tableView.dequeueReusableCellWithIdentifier("cell") as! WrapperTableViewCell?
		
		if cell == nil {
			cell = makeCell()
			cell!.selectionStyle = .Default
			let backgroundView = UIView()
			backgroundView.backgroundColor = Theme.colorBackgroundSelected
			cell!.selectedBackgroundView = backgroundView
		}
		
		guard cell != nil && entity != nil else {
			fatalError("Cannot bind to nil cell or entity")
		}
		
		bindCellToEntity(cell!, entity: entity!, location: nil)
		
		return cell!
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
		if self.disableCells {
			return 0
		}
		
		if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem,
			let entity = queryResult.object as? Entity {
			
			if entity.id_ != nil {
				if let cachedHeight = self.rowHeights.objectForKey(entity.id_) as? CGFloat {
					return cachedHeight
				}
			}
			
			let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.width())
			self.itemTemplate!.bindToEntity(entity, location: nil)
			self.itemTemplate!.bounds.size.width = viewWidth - (self.itemPadding.left + self.itemPadding.right)
			self.itemTemplate!.sizeToFit()
			let viewHeight = self.itemTemplate!.height() + (self.itemPadding.top + self.itemPadding.bottom + 1)
			
			if entity.id_ != nil {
				self.rowHeights[entity.id_] = viewHeight
			}
			
			return viewHeight
		}
		return 0
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
				self.tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .None)
		}
	}
}

extension BaseTableViewController: TTTAttributedLabelDelegate {
	
	func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
		UIApplication.sharedApplication().openURL(url)
	}
}



enum ItemClass {
	case Messages
	case Notifications
	case Patches
	case Users
}