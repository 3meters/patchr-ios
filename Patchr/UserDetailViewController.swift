//
//  UserDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-29.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class UserDetailViewController: BaseDetailViewController {
	
	var profileMode = true
	var progress: AirProgress?
	
	private var header:	UserDetailView!
	
	private var isGuest: Bool {
		return self.entityId == nil
	}

	private var isCurrentUser: Bool {
		return (UserController.instance.authenticated && self.entityId == UserController.instance.currentUser.id_)
	}
	
	/*--------------------------------------------------------------------------------------------
	 * Lifecycle
	 *--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		/*
		* Inputs are already available.
		*/
		super.loadView()
		initialize()
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		let viewWidth = self.tableView.width()
		let viewHeight = CGFloat(208)
		self.tableView.tableHeaderView?.bounds.size = CGSizeMake(viewWidth, viewHeight)
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		fetch(reset: false)
	}
    
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		self.progress?.hide(true)
	}

	override func viewDidDisappear(animated: Bool) {
		self.activity.stopAnimating()
	}
	
	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/

	func browseWatchingAction(sender: AnyObject?) {
		let controller = PatchTableViewController()
		controller.filter = .Watching
		controller.user = self.entity as! User
		self.navigationController?.pushViewController(controller, animated: true)
	}

	func browseOwnedAction(sender: AnyObject?) {
		let controller = PatchTableViewController()
		controller.filter = .Owns
		controller.user = self.entity as! User
		self.navigationController?.pushViewController(controller, animated: true)
	}

	func editAction() {
		let controller = ProfileEditViewController()
		let navController = UINavigationController()
		controller.inputUser = self.entity as? User
		navController.viewControllers = [controller]
		self.navigationController?.presentViewController(navController, animated: true, completion: nil)
	}

	func settingsAction() {
		let controller = SettingsTableViewController()
        self.navigationController?.pushViewController(controller, animated: true)
	}

	/*--------------------------------------------------------------------------------------------
	 * Methods
	 *--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		
		setScreenName(self.profileMode ? "UserProfile" : "UserDetail")
		self.queryName = DataStoreQueryName.MessagesByUser.rawValue
		
		self.header = UserDetailView()
		self.tableView = AirTableView(frame: self.tableView.frame, style: .Plain)
		
		self.header.watchingButton.addTarget(self, action: Selector("browseWatchingAction:"), forControlEvents: UIControlEvents.TouchUpInside)
		self.header.ownsButton.addTarget(self, action: Selector("browseOwnedAction:"), forControlEvents: UIControlEvents.TouchUpInside)
		self.progressOffsetY = 40
		
		/* Navigation bar buttons */
		drawButtons()
	}
	
	override func bind() {
		if let user = self.entity as? User {
			self.header.bindToEntity(user)
			if self.tableView.tableHeaderView == nil {
				self.header.frame = CGRectMake(0, 0, self.tableView.width(), CGFloat(208))
				self.header.setNeedsLayout()
				self.header.layoutIfNeeded()
				self.tableView.tableHeaderView = self.header	// Triggers table binding
				self.tableView.reloadData()
			}
		}
	}
	
	override func drawButtons() {
		if self.profileMode {
			if self.isCurrentUser {
				let editButton = UIBarButtonItem(image: Utils.imageEdit, style: UIBarButtonItemStyle.Plain, target: self, action: Selector("editAction"))
				let settingsButton = UIBarButtonItem(title: "Settings", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("settingsAction"))
				self.navigationItem.rightBarButtonItems = [settingsButton, Utils.spacer, editButton]
				self.navigationItem.title = "Me"
			}
		}
	}
}

extension UserDetailViewController {
	/*
	* UITableViewDataSource
	*/
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return self.entityId == nil ? 0 : 1
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.entityId == nil ? 0 : self.fetchedResultsController.sections?[section].numberOfObjects ?? 0
	}
}
