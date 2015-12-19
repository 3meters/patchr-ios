//
//  QueryTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-22.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class BaseTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
	
    var query:    			Query!
	var processingQuery		= false
	var listType: ItemClass = .Patches
	
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

	var rowHeights:			NSMutableDictionary = [:]
	
    /*--------------------------------------------------------------------------------------------
    * MARK:- Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
	override func viewDidLoad() {
		super.viewDidLoad()
		
        /* Hookup refresh control */
		self.refreshControl = UIRefreshControl()
        self.refreshControl!.tintColor = Theme.colorTint
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
			self.emptyLabel.textAlignment = NSTextAlignment.Center
			self.emptyLabel.textColor = Theme.colorTextPlaceholder
			
            self.view.addSubview(self.emptyLabel)
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
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated) // Base implementation does nothing
		
		self.refreshControl!.endRefreshing()
		if self.query.executedValue {
			do {
				try self.fetchedResultsController.performFetch()
			}
			catch { fatalError("Fetch error: \(error)") }
		}
		else {
			try! self.fetchedResultsController.performFetch()
		}
		
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRowAtIndexPath(indexPath, animated: animated)
		}
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
		
		self.emptyLabel.anchorInCenterWithWidth(160, height: 160)
		self.emptyLabel.frame.origin.y -= CGFloat(64 /* Status bar + navigation bar */)
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

		if !self.query.executedValue {
			self.bindQueryItems(false)
		}
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
    
    /*--------------------------------------------------------------------------------------------
    * MARK:- Events
    *--------------------------------------------------------------------------------------------*/
    
    func pullToRefreshAction(sender: AnyObject?) -> Void {
		Utils.delay(0.5) {	// Give the refresh animation to settle before party on the main thread
			self.bindQueryItems(true, paging: false)
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
		
		self.bindQueryItems(false, paging: true)
	}

    func bindQueryItems(force: Bool = false, paging: Bool = false) {
        
        guard !self.processingQuery else {
            return
        }
        
		self.processingQuery = true
		
        if !self.refreshControl!.refreshing && !self.query.executedValue {
			/* Wacky activity control for body */
			if self.showProgress {
				self.activity.startAnimating()
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
						self?.activity.stopAnimating()
						
						let query = DataController.instance.mainContext.objectWithID(queryObjectId) as! Query
						
						if query.moreValue {
							if self?.tableView.tableFooterView == nil {
								self?.tableView.tableFooterView = self?.footerView
							}
							if let button = self?.footerView.viewWithTag(1) as? UIButton,
								spinner = self?.footerView.viewWithTag(2) as? UIActivityIndicatorView {
									button.hidden = false
									spinner.hidden = true
									spinner.stopAnimating()
							}
						}
						else {
							self?.tableView.tableFooterView = nil
						}
						
						self?.tableView.setNeedsLayout()
						
						if error == nil {
							self?.query.executedValue = true
							if self?.fetchedResultsController.delegate != nil {	// Delegate is unset when view controller disappears
								if let fetchedObjects = self?.fetchedResultsController.fetchedObjects as [AnyObject]? {
									self?.query.offsetValue = Int32(fetchedObjects.count)
									if self?.emptyLabel != nil && fetchedObjects.count == 0 {
										self?.emptyLabel.fadeIn()
									}
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
							DataController.instance.saveContext(false)
							
							do {
								try self?.fetchedResultsController.performFetch() // Reloads table
							}
							catch { fatalError("Fetch error: \(error)") }
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
	func makeCell(cellType: CellType = .TextAndPhoto) -> AirTableViewCell {
		/*
		* Only implementation. Called externally to measure variable row heights.
		*/
		if self.listType == .Notifications {
			let view = NotificationView(cellType: cellType)
			let cell = AirTableViewCell(view: view, padding: UIEdgeInsetsZero, reuseIdentifier: cellType.rawValue)
			return cell
		}
		else if self.listType == .Messages {
			let view = MessageView(cellType: cellType)
			let cell = AirTableViewCell(view: view, padding: UIEdgeInsetsMake(12, 12, 12, 12), reuseIdentifier: cellType.rawValue)
			return cell
		}
		else if self.listType == .Patches {
			let view = PatchView()
			view.cornerRadius = 6
			let cell = AirTableViewCell(view: view, padding: UIEdgeInsetsMake(8, 8, 0, 8), reuseIdentifier: cellType.rawValue)
			cell.separator.backgroundColor = Colors.clear
			cell.backgroundColor = Theme.colorBackgroundTileList
			return cell
		}
		else if self.listType == .Users {
			let view = UserView()
			let cell = AirTableViewCell(view: view, padding: UIEdgeInsetsZero, reuseIdentifier: cellType.rawValue)
			return cell
		}
		else {
			return AirTableViewCell(view: UIView(), padding: UIEdgeInsetsZero, reuseIdentifier: cellType.rawValue)
		}
	}
	
	func bindCell(cell: AirTableViewCell, entity: AnyObject, location: CLLocation?) -> UIView? {
		
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
			else if message.description_ == nil {
				cellType = .Photo
			}
		}
		
		var cell = self.tableView.dequeueReusableCellWithIdentifier(cellType.rawValue) as! AirTableViewCell?
		
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
				self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
			
			case .Delete:	// 2
				self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
				
			case .Move:		// 3
				self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
				self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
				
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