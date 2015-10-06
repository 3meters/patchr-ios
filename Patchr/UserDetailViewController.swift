//
//  UserDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-29.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class UserDetailViewController: BaseDetailViewController {

	private var isCurrentUser                             = false
    private var isGuest                                   = false

	/* Outlets are initialized before viewDidLoad is called */

	@IBOutlet weak var userName:       UILabel!
	@IBOutlet weak var userEmail:      UILabel!
	@IBOutlet weak var userPhoto:      AirImageView!
	@IBOutlet weak var watchingButton: UIButton!
	@IBOutlet weak var ownsButton:     UIButton!
    @IBOutlet weak var likesButton:    UIButton!

	/*--------------------------------------------------------------------------------------------
	 * Lifecycle
	 *--------------------------------------------------------------------------------------------*/

	override func viewDidLoad() {
        
        self.isCurrentUser = (self.entity == nil && self.entityId == nil)
        self.isGuest = !UserController.instance.authenticated
        
        if !self.isGuest && self.isCurrentUser {
            self.entity = UserController.instance.currentUser
        }
        
        self.queryName = DataStoreQueryName.MessagesByUser.rawValue
        
		super.viewDidLoad()

        /* Clear any old content */
        self.userName.text?.removeAll(keepCapacity: false)
        self.userEmail.text?.removeAll(keepCapacity: false)
        
        if isCurrentUser && isGuest {
            let signinButton = UIBarButtonItem(title: "Sign in", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("actionSignin"))
            let settingsButton = UIBarButtonItem(title: "Settings", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("actionSettings"))
            self.navigationItem.rightBarButtonItems = [settingsButton]
            self.navigationItem.leftBarButtonItems = [signinButton]
            self.navigationItem.title = "Guest"
        }
        else if isCurrentUser {
            let editImage = UIImage(named: "imgEdit2Light")
            let editButton = UIBarButtonItem(image: editImage, style: UIBarButtonItemStyle.Plain, target: self, action: Selector("actionEdit"))
            let signoutButton = UIBarButtonItem(title: "Sign out", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("actionSignout"))
            let settingsButton = UIBarButtonItem(title: "Settings", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("actionSettings"))
            let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
            spacer.width = SPACER_WIDTH
            self.navigationItem.rightBarButtonItems = [settingsButton, spacer, editButton]
            self.navigationItem.leftBarButtonItems = [signoutButton]
            self.navigationItem.title = "Me"
        }
	}

	override func viewWillAppear(animated: Bool) {
        /* Triggers query processing by results controller */
		super.viewWillAppear(animated)
        setScreenName("UserDetail")
        if self.entity != nil || self.isGuest {
            draw()
        }
	}
    
    override func viewDidAppear(animated: Bool){
        super.viewDidAppear(animated)
        bind(true)
    }

	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/

    @IBAction func actionBrowseFavorites(sender: UIButton) {
        if !self.isGuest {
            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            if let controller = storyboard.instantiateViewControllerWithIdentifier("PatchTableViewController") as? PatchTableViewController {
                controller.filter = .Favorite
                controller.user = self.entity as! User
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
	@IBAction func actionBrowseWatching(sender: UIButton) {
        if !self.isGuest {
            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            if let controller = storyboard.instantiateViewControllerWithIdentifier("PatchTableViewController") as? PatchTableViewController {
                controller.filter = .Watching
                controller.user = self.entity as! User
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
	}

	@IBAction func actionBrowseOwned(sender: UIButton) {
        if !self.isGuest {
            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            if let controller = storyboard.instantiateViewControllerWithIdentifier("PatchTableViewController") as? PatchTableViewController {
                controller.filter = .Owns
                controller.user = self.entity as! User
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
	}

    @IBAction func unwindFromUserEdit(segue: UIStoryboardSegue) {
        // Refresh results when unwinding from User edit/create screen to pickup any changes.
        self.bind(false)
    }
    
	func actionSignout() {

		DataController.proxibase.signOut {
			response, error in
            
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

    override func bind(force: Bool = false) {
        if !self.isGuest {
            super.bind(force)
        }
    }
    
	override func draw() {
        
        if self.isGuest {
            self.userName.text = "Guest"
            self.userEmail.text = "discover@3meters.com"
            self.userPhoto.image = UIImage(named: "imgDefaultUser")
            self.watchingButton.setTitle("Watching: --", forState: .Normal)
            self.ownsButton.setTitle("Owner: --", forState: .Normal)
            self.likesButton.setTitle("Favorites: --", forState: .Normal)
        }
        else {
            if let entity = self.entity as? User {
                self.userName.text = entity.name
                self.userEmail.text = entity.email
                self.userPhoto.setImageWithPhoto(entity.getPhotoManaged(), animate: false)
                
                if entity.patchesWatching != nil {
                    let count = entity.patchesWatchingValue == 0 ? "--" : String(entity.patchesWatchingValue)
                    self.watchingButton.setTitle("Watching: \(count)", forState: .Normal)
                }
                if entity.patchesOwned != nil {
                    let count = entity.patchesOwnedValue == 0 ? "--" : String(entity.patchesOwnedValue)
                    self.ownsButton.setTitle("Owner: \(count)", forState: .Normal)
                }
                if entity.patchesLikes != nil {
                    let count = entity.patchesLikesValue == 0 ? "--" : String(entity.patchesLikesValue)
                    self.likesButton.setTitle("Favorites: \(count)", forState: .Normal)
                }
            }
        }
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