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

	var activity			= UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
	var footerView			= UIView()
	var loadMoreButton		= UIButton(type: UIButtonType.roundedRect)
	var loadMoreActivity	= UIActivityIndicatorView(activityIndicatorStyle: .white)
	var loadMoreMessage		= "LOAD MORE"
	
	var emptyLabel			= AirLinkButton(frame: CGRect.zero)
	var emptyMessage		: String?
    var showEmptyLabel		= true
    var showProgress		= true
    var progressOffsetY     = Float(-48)
	var progressOffsetX     = Float(8)
	var disableCells		= false

	/* Only used for row sizing */
	var rowHeights			: NSMutableDictionary = [:]
	var itemTemplate		: BaseView?
	var itemPadding			= UIEdgeInsets.zero
	
    /*--------------------------------------------------------------------------------------------
    * MARK:- Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
	override func viewDidLoad() {
		super.viewDidLoad()

        /* Hookup refresh control */
		self.refreshControl = UIRefreshControl()
		self.refreshControl!.tintColor = Theme.colorActivityIndicator
		self.refreshControl?.addTarget(self, action: #selector(BaseTableViewController.pullToRefreshAction(sender:)), for: UIControlEvents.valueChanged)
		self.refreshControl?.endRefreshing()

		/* Simple activity indicator (frame sizing) */
		self.activity.color = Theme.colorActivityIndicator
		self.activity.hidesWhenStopped = true
		self.view.addSubview(activity)

		/* Footer */
		self.loadMoreButton.tag = 1
		self.loadMoreButton.backgroundColor = Theme.colorBackgroundTile
		self.loadMoreButton.layer.cornerRadius = 8
		self.loadMoreButton.addTarget(self, action: #selector(BaseTableViewController.loadMore(sender:)), for: UIControlEvents.touchUpInside)
		self.loadMoreButton.setTitle(self.loadMoreMessage, for: .normal)
		self.footerView.addSubview(self.loadMoreButton)

		self.loadMoreActivity.tag = 2
		self.loadMoreActivity.color = Theme.colorActivityIndicator
		self.loadMoreActivity.isHidden = true

		self.footerView.frame.size.height = CGFloat(48 + 16)
		self.footerView.addSubview(self.loadMoreActivity)
		self.footerView.backgroundColor = Theme.colorBackgroundTileList

        /* Empty label */
        if self.showEmptyLabel {
            self.emptyLabel.alpha = 0
            self.emptyLabel.layer.borderWidth = 1
            self.emptyLabel.layer.borderColor = Theme.colorRule.cgColor
			self.emptyLabel.layer.backgroundColor = Theme.colorBackgroundEmptyBubble.cgColor
			self.emptyLabel.layer.cornerRadius = 80
            self.emptyLabel.titleLabel!.font = Theme.fontTextDisplay
            self.emptyLabel.titleLabel!.numberOfLines = 0
			self.emptyLabel.titleEdgeInsets = UIEdgeInsetsMake(16, 16, 16, 16)
            self.emptyLabel.titleLabel!.textAlignment = NSTextAlignment.center
            self.emptyLabel.setTitleColor(Theme.colorTextPlaceholder, for: .normal)
			self.emptyLabel.setTitle(self.emptyMessage, for: .normal)

            self.tableView.addSubview(self.emptyLabel)
        }

		self.tableView.estimatedRowHeight = 100						// Zero turns off estimates
		self.tableView.rowHeight = UITableViewAutomaticDimension	// Actual height is handled in heightForRowAtIndexPath

        /* A bit of UI tweaking */
        self.tableView.backgroundColor = Theme.colorBackgroundTable
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none;
        self.tableView.separatorInset = UIEdgeInsets.zero

		/* Hookup query */
		self.query = loadQuery()

		NotificationCenter.default.addObserver(self, selector: #selector(BaseTableViewController.willFetchQuery(notification:)), name: NSNotification.Name(rawValue: Events.WillFetchQuery), object: self)
		NotificationCenter.default.addObserver(self, selector: #selector(BaseTableViewController.didFetchQuery(notification:)), name: NSNotification.Name(rawValue: Events.DidFetchQuery), object: self)
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
		self.loadMoreButton.anchorTopCenterFillingWidth(withLeftAndRightPadding: 8, topPadding: 8, height: 48)
		self.loadMoreActivity.anchorTopCenter(withTopPadding: 8, width: 48, height: 48)
		
		self.activity.anchorInCenter(withWidth: 20, height: 20)
		self.activity.frame.origin.y += CGFloat(self.progressOffsetY)
		self.activity.frame.origin.x += CGFloat(self.progressOffsetX)
		
		let navHeight = self.navigationController?.navigationBar.height() ?? 0
		let statusHeight = UIApplication.shared.statusBarFrame.size.height

		self.emptyLabel.anchorInCenter(withWidth: 160, height: 160)
		self.emptyLabel.frame.origin.y -= (statusHeight + navHeight)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated) // Base implementation does nothing
		
		try! self.fetchedResultsController.performFetch()
	}
	
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
		
		if self.query.executedValue {
			
			self.tableView.reloadData()		// Reload cells so any changes while gone will show
			
			/* Configure paging button in footer */
			if self.query.moreValue {
				if self.tableView.tableFooterView == nil {
					self.tableView.tableFooterView = self.footerView
				}
				if let button = self.footerView.viewWithTag(1) as? UIButton,
					let spinner = self.footerView.viewWithTag(2) as? UIActivityIndicatorView {
						button.isHidden = false
						spinner.isHidden = true
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
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
	}

    override func viewDidDisappear(_ animated: Bool) {
		/*
		 * Called when switching between patch view controllers.
		 */
		super.viewDidDisappear(animated)
		self.activity.stopAnimating()
		self.refreshControl?.endRefreshing()
    }
	
	deinit {
		NotificationCenter.default.removeObserver(self)
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
				UIShared.showPhoto(image: control.image, animateFromView: control, viewController: self, entity: container.entity)
			}
		}
		
		if let recognizer = sender as? UITapGestureRecognizer,
			let control = recognizer.view as? AirImageView,
			let container = control.superview as? BaseView {
			if control.image != nil {
				UIShared.showPhoto(image: control.image, animateFromView: control, viewController: self, entity: container.entity)
			}
		}
		
		if let control = sender as? UIButton, let container = sender?.superview as? BaseView {
			if control.imageView!.image != nil {
				UIShared.showPhoto(image: control.imageView!.image, animateFromView: control, viewController: self, entity: container.entity)
			}
		}
		
		
	}
	
	func willFetchQuery(notification: NSNotification) {
		if (self.refreshControl == nil || !self.refreshControl!.isRefreshing) && !self.query.executedValue {
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
		if let userInfo = notification.userInfo , userInfo["count"] != nil {
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
				let spinner = self.footerView.viewWithTag(2) as? UIActivityIndicatorView {
					button.isHidden = false
					spinner.isHidden = true
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
			let spinner = self.footerView.viewWithTag(2) as? UIActivityIndicatorView {
				button.isHidden = true
				spinner.isHidden = false
				spinner.startAnimating()
		}
		
		self.fetchQueryItems(force: false, paging: true, queryDate: nil)
	}
	
	func beginRefreshingTableView() {
		self.refreshControl?.beginRefreshing()
        self.tableView.setContentOffset(CGPoint(x:0, y:self.tableView.contentOffset.y - (self.refreshControl?.height())!), animated: true)
		pullToRefreshAction(sender: nil)
	}

	func fetchQueryItems(force: Bool, paging: Bool, queryDate: Int64?) {
        
        guard !self.processingQuery else { return }
		guard !self.query.isDeleted else { return }
        
		self.processingQuery = true
		
		NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.WillFetchQuery), object: self)
        /*
         * Check to see of any subclass wants to inject using the sidecar. Currently
         * used to add locally cached nearby notifications.
         */
        if !paging {
            populateSidecar(query: self.query)
        }
		
		let queryObjectId = self.query.objectID
		
		DataController.instance.backgroundOperationQueue.addOperation {
			
			DataController.instance.refreshItemsFor(queryId: queryObjectId!, force: force, paging: paging, completion: {
				[weak self] results, query, error in
				
				OperationQueue.main.addOperation {
					
					self?.refreshControl?.endRefreshing()
					
					// Delay seems to be necessary to avoid visual glitch with UIRefreshControl
					Utils.delay(0.5) {
						
						self?.processingQuery = false
						var userInfo: [AnyHashable: Any] = ["error": (error != nil)]
						
						let query = DataController.instance.mainContext.object(with: queryObjectId!) as! Query
                        
                        if let error = ServerError(error) {
                            self!.handleError(error)
                        }
                        else {
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
                            var oldestDate = Date()
                            for item in query.queryItems {
                                if let queryItem = item as? QueryItem,
                                    let entity = queryItem.object as? Entity,
                                    let sortDate = entity.sortDate {
                                    if sortDate < oldestDate as Date {
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
                            DataController.instance.saveContext(wait: BLOCKING)
                            self?.tableView.reloadData()		// Update cells to show any changes
                            if paging {
                                Reporting.track("Paged List")
                            }
                            
                            DispatchQueue.main.async(execute: { () -> Void in
                                if self != nil {
                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.DidFetchQuery), object: self!, userInfo: userInfo)
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
	
	func scrollToFirstRow(animated: Bool = true) {
		self.tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: animated)
	}
	
	func getActivityDate() -> Int64 {
		preconditionFailure("This method must be overridden in subclass")
	}
	
	/*--------------------------------------------------------------------------------------------
	* MARK:- Properties
	*--------------------------------------------------------------------------------------------*/
	
    internal lazy var fetchedResultsController: NSFetchedResultsController<QueryItem> = {
		/*
		* Creates controller instance first time the field is accessed.
		*/
        let fetchRequest = NSFetchRequest<QueryItem>(entityName: QueryItem.entityName())
		
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
		else if self.listType == .Patches {
            let view = ChannelView(frame: CGRect(x:0, y:0, width:self.view.width(), height:40))
			let cell = WrapperTableViewCell(view: view, padding: self.itemPadding, reuseIdentifier: "cell")
            cell.separator.removeFromSuperview()
			return cell
		}
		else if self.listType == .Users {
            let view = UserView(frame: CGRect(x:0, y:0, width:self.view.width(), height:97))
			let cell = WrapperTableViewCell(view: view, padding: self.itemPadding, reuseIdentifier: "cell")
			cell.selectionStyle = .none
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
			notificationView.bindToEntity(entity: entity, location: nil)
		}
		
		if self.listType == .Patches {
			let patchView = cell.view! as! ChannelView
			patchView.bindToEntity(entity: entity, location: location)
		}
		
		if self.listType == .Users {
			let userView = cell.view! as! UserView
			userView.bindToEntity(entity: entity, location: nil)
		}
	}
	/*
	 * UITableViewDataSource
	 */
    override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let numberOfObjects = self.fetchedResultsController.sections?[section].numberOfObjects ?? 0
		return numberOfObjects
	}
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		/* Bind the cell to the entity */
		let queryResult = self.fetchedResultsController.object(at: indexPath)
		let entity = queryResult.object as? Entity
		var cell = self.tableView.dequeueReusableCell(withIdentifier: "cell") as! WrapperTableViewCell?
		
		if cell == nil {
			cell = makeCell()
			cell!.selectionStyle = .default
			let backgroundView = UIView()
			backgroundView.backgroundColor = Theme.colorBackgroundSelected
			cell!.selectedBackgroundView = backgroundView
		}
		
		guard cell != nil && entity != nil else {
			fatalError("Cannot bind to nil cell or entity")
		}
		
		bindCellToEntity(cell: cell!, entity: entity!, location: nil)
		
		return cell!
	}
	
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
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
		
		let queryResult = self.fetchedResultsController.object(at: indexPath) 
        let entity = queryResult.object as? Entity
        
        if entity?.id_ != nil {
            if let cachedHeight = self.rowHeights.object(forKey: entity?.id_) as? CGFloat {
                return cachedHeight
            }
        }
        
        let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.width())
        self.itemTemplate!.bindToEntity(entity: entity!, location: nil)
        self.itemTemplate!.bounds.size.width = viewWidth - (self.itemPadding.left + self.itemPadding.right)
        self.itemTemplate!.sizeToFit()
        let viewHeight = self.itemTemplate!.height() + (self.itemPadding.top + self.itemPadding.bottom + 1)
        
        if entity?.id_ != nil {
            self.rowHeights[entity?.id_] = viewHeight
        }
        
        return viewHeight
	}
}

extension BaseTableViewController {
	/*
	 * NSFetchedResultsControllerDelegate
	 */
	func controllerWillChangeContent(controller: NSFetchedResultsController<QueryItem>) {
		self.tableView.beginUpdates()
	}
	
	func controllerDidChangeContent(controller: NSFetchedResultsController<QueryItem>) {
		self.tableView.endUpdates()
	}
	
	func controller(controller: NSFetchedResultsController<QueryItem>, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
		switch type {
		case .insert:
			self.tableView.insertSections(NSIndexSet(index: sectionIndex) as IndexSet, with: .fade)
			
		case .delete:
			self.tableView.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet, with: .fade)
			
		default:
			return
		}
	}
	
	func controller(controller: NSFetchedResultsController<QueryItem>, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
		/*
		 * http://stackoverflow.com/a/32978387
		 * iOS 9 introduced a bug where didChangeObject can be called with an
		 * invalid change type.
		 */
		guard type.rawValue != 0 else {
			return
		}
		
		switch type {
			case .insert:	// 1
				self.tableView.insertRows(at: [newIndexPath! as IndexPath], with: .automatic)
			
			case .delete:	// 2
				self.tableView.deleteRows(at: [indexPath! as IndexPath], with: .fade)
				
			case .move:		// 3
				self.tableView.moveRow(at: indexPath! as IndexPath, to: newIndexPath! as IndexPath)

			case .update:	// 4
				self.tableView.reloadRows(at: [indexPath! as IndexPath], with: .none)
		}
	}
}

extension BaseTableViewController: TTTAttributedLabelDelegate {
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
		UIApplication.shared.openURL(url)
	}
}

enum ItemClass {
	case Messages
	case Notifications
	case Patches
	case Users
}
