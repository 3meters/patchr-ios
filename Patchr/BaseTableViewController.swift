//
//  QueryTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-22.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class BaseTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
	
    var _query:				Query!
	var processingQuery		= false
	var listType:			ItemClass = .Patches
	var isGuest				= false
	
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
	var contentOffset		= CGPointMake(0, -64)
	
	var rowHeights:			NSMutableDictionary = [:]
	var rowAnimation:		UITableViewRowAnimation = .Fade
	
    /*--------------------------------------------------------------------------------------------
    * MARK:- Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.isGuest = !UserController.instance.authenticated
		
        /* Hookup refresh control */
		let refreshControl = UIRefreshControl()
        refreshControl.tintColor = Colors.brandColor
		refreshControl.addTarget(self, action: "pullToRefreshAction:", forControlEvents: UIControlEvents.ValueChanged)
		self.refreshControl = refreshControl
		
		/* Simple activity indicator (frame sizing) */
		self.activity.color = Colors.brandColorDark
		self.activity.hidesWhenStopped = true
		self.view.addSubview(activity)
		
		/* Footer */
		self.loadMoreButton.tag = 1
		self.loadMoreButton.backgroundColor = UIColor.whiteColor()
		self.loadMoreButton.layer.cornerRadius = 8
		self.loadMoreButton.addTarget(self, action: Selector("loadMore:"), forControlEvents: UIControlEvents.TouchUpInside)
		self.loadMoreButton.setTitle(self.loadMoreMessage, forState: .Normal)
		self.footerView.addSubview(self.loadMoreButton)
		
		self.loadMoreActivity.tag = 2
		self.loadMoreActivity.color = Colors.brandColorDark
		self.loadMoreActivity.hidden = true
		self.footerView.addSubview(self.loadMoreActivity)
		self.footerView.backgroundColor = Colors.windowColor
		
        /* Empty label */
        if self.showEmptyLabel {
            self.emptyLabel.alpha = 0
            self.emptyLabel.layer.borderWidth = 1
            self.emptyLabel.layer.borderColor = Colors.hintColor.CGColor
			self.emptyLabel.layer.backgroundColor = UIColor.whiteColor().CGColor
			self.emptyLabel.layer.cornerRadius = 80
            self.emptyLabel.font = UIFont(name: "HelveticaNeue-Light", size: 19)
            self.emptyLabel.text = self.emptyMessage
            self.emptyLabel.numberOfLines = 0
			self.emptyLabel.textAlignment = NSTextAlignment.Center
			self.emptyLabel.textColor = UIColor(red: CGFloat(0.6), green: CGFloat(0.6), blue: CGFloat(0.6), alpha: CGFloat(1))
			
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
        self.tableView.backgroundColor = Colors.windowColor
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None;
        self.tableView.separatorInset = UIEdgeInsetsZero
		self.tableView.contentInset = UIEdgeInsetsMake(64, 0.0, 44, 0.0)
		self.automaticallyAdjustsScrollViewInsets = false
		
        self.clearsSelectionOnViewWillAppear = false;
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated) // Base implementation does nothing
		/*
		 * First time this causes FRC to be instantiated, subsequent times
		 * we need to reset delegate to start monitoring the data model.
		 */
		self.fetchedResultsController.delegate = self
		
		if self.query().executedValue {
			do {
				try self.fetchedResultsController.performFetch()
				self.tableView.reloadData()
			}
			catch { fatalError("Fetch error: \(error)") }
		}
		
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRowAtIndexPath(indexPath, animated: animated)
		}
		
		self.tableView.setContentOffset(self.contentOffset, animated: true)
	}
	
	override func viewWillLayoutSubviews() {
		/*
		 * Called right after viewWillAppear. Gets called
		 * multiple times during appearance cycle.
		 */
		super.viewWillLayoutSubviews()
		
		self.footerView.frame.size.height = CGFloat(48 + 16)
		
		self.loadMoreButton.fillSuperviewWithLeftPadding(8, rightPadding: 8, topPadding: 8, bottomPadding: 8)
		self.loadMoreActivity.fillSuperview()
		
		self.activity.anchorInCenterWithWidth(20, height: 20)
		self.activity.frame.origin.y += CGFloat(self.progressOffsetY)
		self.activity.frame.origin.x += CGFloat(self.progressOffsetX)
		
		self.emptyLabel.anchorInCenterWithWidth(160, height: 160)
	}
	
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
		if !self.query().executedValue {
			self.bindQueryItems(false)
		}
    }
	
    override func viewDidDisappear(animated: Bool) {
		/*
		 * Called when switching between patch view controllers.
		 */
		super.viewDidDisappear(animated)
		self.contentOffset = self.tableView.contentOffset
		self.fetchedResultsController.delegate = nil
		self.activity.stopAnimating()
        self.refreshControl?.endRefreshing()
    }
    
    /*--------------------------------------------------------------------------------------------
    * MARK:- Events
    *--------------------------------------------------------------------------------------------*/
    
    func pullToRefreshAction(sender: AnyObject?) -> Void {
        self.bindQueryItems(true, paging: false)
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
        
		guard self.query().enabledValue else {
			self.emptyLabel.fadeIn()
			return
		}
		
		self.processingQuery = true
		
        if !self.refreshControl!.refreshing && !self.query().executedValue {
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
            populateSidecar(query())
        }
		
		dispatch_async(DataController.instance.backgroundDispatch) {
			
			DataController.instance.refreshItemsFor(self.query().objectID, force: force, paging: paging, completion: {
				[weak self] results, query, error in
				
				NSOperationQueue.mainQueue().addOperationWithBlock {
					
					// Delay seems to be necessary to avoid visual glitch with UIRefreshControl
					Utils.delay(0.5) {
						
						self?.processingQuery = false
						self?.activity.stopAnimating()
						self?.refreshControl?.endRefreshing()
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
						
						if error == nil {
							self?.query().executedValue = true
							if self?.fetchedResultsController.delegate != nil {	// Delegate is unset when view controller disappears
								if let fetchedObjects = self?.fetchedResultsController.fetchedObjects as [AnyObject]? {
									self?.query().offsetValue = Int32(fetchedObjects.count)
									if self?.emptyLabel != nil && fetchedObjects.count == 0 {
										self?.emptyLabel.fadeIn()
									}
								}
							}
						}
						return
					}
				}
			})
		}
    }
	
    func populateSidecar(query: Query) { }

	func query() -> Query {
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
            managedObjectContext: DataController.instance.mainContext,
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
			view.cornerRadius = 8
			let cell = AirTableViewCell(view: view, padding: UIEdgeInsetsMake(8, 8, 0, 8), reuseIdentifier: cellType.rawValue)
			cell.separator.backgroundColor = UIColor.clearColor()
			cell.backgroundColor = Colors.windowColor
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
			Notification.bindView(cell.view!, entity: entity)
			return cell.view
		}
		
		if self.listType == .Messages {
			Message.bindView(cell.view!, entity: entity)
			return cell.view
		}
		
		if self.listType == .Patches {
			Patch.bindView(cell.view!, entity: entity, location: location)
			return cell.view
		}
		
		if self.listType == .Users {
			User.bindView(cell.view!, entity: entity)
			return cell.view
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
		let numberOfObjects = self.fetchedResultsController.sections![section].numberOfObjects
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
			if message.photo == nil {
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
				self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: self.rowAnimation)
			
			case .Delete:	// 2
				self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: self.rowAnimation)
				
			case .Move:		// 3
				self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: self.rowAnimation)
				self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: self.rowAnimation)
				
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