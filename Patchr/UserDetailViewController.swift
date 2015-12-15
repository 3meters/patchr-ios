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

	override func viewDidLoad() {
		self.queryName = DataStoreQueryName.MessagesByUser.rawValue
		
		if UserController.instance.authenticated {
			super.viewDidLoad()
		}
		
		self.header = UserDetailView()
		self.tableView.tableHeaderView = self.header	// Triggers table binding
		self.progressOffsetY = 40
		
		if self.profileMode {
			if self.isCurrentUser {
				let editImage = Utils.imageEdit
				let editButton = UIBarButtonItem(image: editImage, style: UIBarButtonItemStyle.Plain, target: self, action: Selector("actionEdit"))
				let settingsButton = UIBarButtonItem(title: "Settings", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("actionSettings"))
				let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
				spacer.width = SPACER_WIDTH
				self.navigationItem.rightBarButtonItems = [settingsButton, spacer, editButton]
				self.navigationItem.title = "Me"
			}
		}
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		setScreenName(self.profileMode ? "UserProfile" : "UserDetail")
	}
    
    override func viewDidAppear(animated: Bool){
		super.viewDidAppear(animated)
		bind(true)
    }
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		self.progress?.hide(true)
	}

	override func viewDidDisappear(animated: Bool) {
		/*
		* Called when switching between patch view controllers.
		*/
		self.fetchedResultsController.delegate = nil
		self.activity.stopAnimating()
	}

	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/

	func actionBrowseWatching(sender: AnyObject?) {
		let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
		if let controller = storyboard.instantiateViewControllerWithIdentifier("PatchTableViewController") as? PatchTableViewController {
			controller.filter = .Watching
			controller.user = self.entity as! User
			self.navigationController?.pushViewController(controller, animated: true)
		}
	}

	func actionBrowseOwned(sender: AnyObject?) {
		let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
		if let controller = storyboard.instantiateViewControllerWithIdentifier("PatchTableViewController") as? PatchTableViewController {
			controller.filter = .Owns
			controller.user = self.entity as! User
			self.navigationController?.pushViewController(controller, animated: true)
		}
	}

	func actionEdit() {		
		let controller = ProfileEditViewController()
		let navController = UINavigationController()
		controller.inputUser = self.entity as? User
		navController.viewControllers = [controller]
		self.navigationController?.presentViewController(navController, animated: true, completion: nil)
	}

	func actionSettings() {
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        if let controller = storyboard.instantiateViewControllerWithIdentifier("SettingsTableViewController") as? SettingsTableViewController {
            self.navigationController?.pushViewController(controller, animated: true)
        }
	}

	/*--------------------------------------------------------------------------------------------
	 * Methods
	 *--------------------------------------------------------------------------------------------*/
	
	override func draw() {
		if let entity = self.entity as? User {
			self.header.bindToEntity(entity, isGuest: self.isGuest)
			self.header.watchingInfo.addTarget(self, action: Selector("actionBrowseWatching:"), forControlEvents: UIControlEvents.TouchUpInside)
			self.header.ownsInfo.addTarget(self, action: Selector("actionBrowseOwned:"), forControlEvents: UIControlEvents.TouchUpInside)
			self.tableView.reloadData()
			return
		}
		self.header.bindToEntity(nil, isGuest: self.isGuest)
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
