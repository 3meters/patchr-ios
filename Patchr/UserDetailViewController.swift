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
		
		super.viewDidLoad()
		
		self.queryName = DataStoreQueryName.MessagesByUser.rawValue
		self.header = UserDetailView()
		self.tableView.tableHeaderView = self.header	// Triggers table binding
		self.progressOffsetY = 40
		
		if self.profileMode {
			if self.isCurrentUser {
				let editImage = Utils.imageEdit
				let editButton = UIBarButtonItem(image: editImage, style: UIBarButtonItemStyle.Plain, target: self, action: Selector("actionEdit"))
				let signoutButton = UIBarButtonItem(title: "Sign out", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("actionSignout"))
				let settingsButton = UIBarButtonItem(title: "Settings", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("actionSettings"))
				let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
				spacer.width = SPACER_WIDTH
				self.navigationItem.rightBarButtonItems = [settingsButton, spacer, editButton]
				self.navigationItem.leftBarButtonItems = [signoutButton]
				self.navigationItem.title = "Me"
			}
			else  {
				let signinButton = UIBarButtonItem(title: "Sign in", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("actionSignin"))
				let settingsButton = UIBarButtonItem(title: "Settings", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("actionSettings"))
				self.navigationItem.rightBarButtonItems = [settingsButton]
				self.navigationItem.leftBarButtonItems = [signinButton]
				self.navigationItem.title = "Guest"
				return
			}
		}
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
	}

	override func viewWillAppear(animated: Bool) {
		setScreenName(self.profileMode ? "UserProfile" : "UserDetail")
		if !self.isGuest {
			super.viewWillAppear(animated)
		}
		else {
			draw()
		}
	}
    
    override func viewDidAppear(animated: Bool){
		if !self.isGuest {
			super.viewDidAppear(animated)
			bind(true)
		}
    }

	override func viewDidDisappear(animated: Bool) {
		/*
		* Called when switching between patch view controllers.
		*/
		self.contentOffset = self.tableView.contentOffset
		if !self.isGuest {
			self.fetchedResultsController.delegate = nil
		}
		self.activity.stopAnimating()
		self.refreshControl?.endRefreshing()
	}

	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/

	func actionBrowseWatching(sender: AnyObject?) {
        if !self.isGuest {
            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            if let controller = storyboard.instantiateViewControllerWithIdentifier("PatchTableViewController") as? PatchTableViewController {
                controller.filter = .Watching
                controller.user = self.entity as! User
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
	}

	func actionBrowseOwned(sender: AnyObject?) {
        if !self.isGuest {
            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            if let controller = storyboard.instantiateViewControllerWithIdentifier("PatchTableViewController") as? PatchTableViewController {
                controller.filter = .Owns
                controller.user = self.entity as! User
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
	}

	func actionSignout() {

		DataController.proxibase.signOut {
			response, error in
            
			NSOperationQueue.mainQueue().addOperationWithBlock {
				if error != nil {
					Log.w("Error during logout \(error)")
				}
				
				/* Make sure state is cleared */
				LocationController.instance.clearLastLocationAccepted()

				let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
				let destinationViewController = UIStoryboard(name: "Lobby", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("LobbyNavigationController") 
				appDelegate.window!.setRootViewController(destinationViewController, animated: true)
			}
		}
	}
    
    func actionSignin() {
        
        LocationController.instance.clearLastLocationAccepted()
        let storyboard: UIStoryboard = UIStoryboard(name: "Lobby", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("SignInEditViewController")
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
	func actionEdit() {
        /* Has its own nav because we segue modally and it needs its own stack */
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("UserEditViewController") as? UserEditViewController
        controller!.entity = self.entity
        let navController = UINavigationController()
        navController.navigationBar.tintColor = Colors.brandColorDark
        navController.viewControllers = [controller!]
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
			return
		}
		self.header.bindToEntity(nil, isGuest: self.isGuest)
	}
	
	override func pullToRefreshAction(sender: AnyObject?) -> Void {
        if !self.isGuest {
            super.pullToRefreshAction(sender)
        }
        else {
            self.refreshControl?.endRefreshing()
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
		return self.entityId == nil ? 0 : self.fetchedResultsController.sections![section].numberOfObjects
	}
}
