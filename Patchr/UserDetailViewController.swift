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
	
	private var isCurrentUser: Bool {
		return (ZUserController.instance.authenticated
			&& ZUserController.instance.currentUser != nil
			&& self.entityId == ZUserController.instance.userId)
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
		
		let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.width())
		let viewHeight = CGFloat(208)
        self.tableView.tableHeaderView?.bounds.size = CGSize(width:viewWidth, height:viewHeight)	// Triggers layoutSubviews on header
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)	// calls bind
		
		if self.invalidated {
			Log.d("Resetting user and messages because user logged in")
			fetch(strategy: .IgnoreCache, resetList: true)
		}
		else if self.isCurrentUser && self.firstAppearance {
			fetch(strategy: .IgnoreCache, resetList: true)
		}
		else {
			fetch(strategy: .UseCacheAndVerify)
		}
	}
    
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.progress?.hide(true)
	}

	override func viewDidDisappear(_ animated: Bool) {
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
		let controller = ZProfileEditViewController()
		let navController = AirNavigationController()
		controller.inputUser = self.entity as? User
		navController.viewControllers = [controller]
		self.navigationController?.present(navController, animated: true, completion: nil)
	}

	func settingsAction() {
		let controller = SettingsTableViewController()
        self.navigationController?.pushViewController(controller, animated: true)
	}
	
	/*--------------------------------------------------------------------------------------------
	 * Methods
	 *--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		
		Reporting.screen(self.profileMode ? "UserProfile" : "UserDetail")

		self.queryName = DataStoreQueryName.MessagesByUser.rawValue

		self.header = UserDetailView()
		self.tableView = AirTableView(frame: self.tableView.frame, style: .plain)
		
		self.showEmptyLabel = false
		if self.profileMode {
			self.showEmptyLabel = true
			self.emptyMessage = "Browse your posted messages here"
			self.emptyLabel.setTitle(self.emptyMessage, for: .normal)
		}
		
		self.showProgress = true
		self.progressOffsetY = 40
		self.loadMoreMessage = "LOAD MORE MESSAGES"
		
		/* Navigation bar buttons */
		drawNavBarButtons()
	}
	
	override func bind() {
		if let user = self.entity as? User {
			let header = self.header as! UserDetailView
			header.bindToEntity(entity: user)
			if self.tableView.tableHeaderView == nil {
                header.frame = CGRect(x:0, y:0, width:self.tableView.width(), height:CGFloat(208))
				header.setNeedsLayout()
				header.layoutIfNeeded()
				self.tableView.tableHeaderView = header	// Triggers table binding
				self.tableView.reloadData()
			}
		}
	}
	
	override func drawNavBarButtons() {
		if self.profileMode {
			if self.isCurrentUser {
				let editButton = UIBarButtonItem(image: Utils.imageEdit, style: UIBarButtonItemStyle.plain, target: self, action: #selector(UserDetailViewController.editAction))
				let settingsButton = UIBarButtonItem(title: "Settings", style: UIBarButtonItemStyle.plain, target: self, action: #selector(UserDetailViewController.settingsAction))
				
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
	override func numberOfSections(in: UITableView) -> Int {
		return self.entityId == nil ? 0 : 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.entityId == nil ? 0 : self.fetchedResultsController.sections?[section].numberOfObjects ?? 0
	}
}
