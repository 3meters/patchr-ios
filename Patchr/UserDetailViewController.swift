//
//  UserDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-29.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class UserDetailViewController: QueryTableViewController {

	var user:  User! = nil
    var userId: String?

	private var selectedMessage:      Message?
	private var messageDateFormatter: NSDateFormatter!
	private var offscreenCells:       NSMutableDictionary = NSMutableDictionary()
	private var isCurrentUser                             = false
    private var isGuest                                   = false
    private var patchListFilter:      PatchListFilter?    = nil

	/* Outlets are initialized before viewDidLoad is called */

	@IBOutlet weak var userName:       UILabel!
	@IBOutlet weak var userEmail:      UILabel!
	@IBOutlet weak var userPhoto:      AirImageButton!
	@IBOutlet weak var watchingButton: UIButton!
	@IBOutlet weak var ownsButton:     UIButton!
    @IBOutlet weak var likesButton:    UIButton!

	private var _query: Query!

	override func query() -> Query {
		if self._query == nil {
			let query = Query.insertInManagedObjectContext(DataController.instance.managedObjectContext) as! Query
			query.name = DataStoreQueryName.MessagesByUser.rawValue
            query.pageSize = DataController.proxibase.pageSizeDefault            
            query.validValue = (user != nil || userId != nil)
            if query.validValue {
                query.parameters = [:]
                if user != nil {
                    query.parameters["entity"] = user
                }
                if userId != nil {
                    query.parameters["entityId"] = userId
                }
            }
			DataController.instance.managedObjectContext.save(nil)
			self._query = query
		}
		return self._query
	}

	/*--------------------------------------------------------------------------------------------
	 * Lifecycle
	 *--------------------------------------------------------------------------------------------*/

	override func viewDidLoad() {
        
        isCurrentUser = (self.user == nil && self.userId == nil)
        isGuest = !UserController.instance.authenticated
        
        if !isGuest && isCurrentUser {
            self.user = UserController.instance.currentUser
        }
        
        if user != nil {
            userId = user.id_
        }
        
        self.contentViewName = "MessageView"
        super.showEmptyLabel = false
        
		super.viewDidLoad()

        /* UI prep */
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None;
        /* Clear any old content */
        userName.text?.removeAll(keepCapacity: false)
        userEmail.text?.removeAll(keepCapacity: false)
        userPhoto.imageView?.image = nil        
        
        if isCurrentUser && isGuest {
            var signinButton = UIBarButtonItem(title: "Sign in", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("actionSignin"))
            var settingsButton = UIBarButtonItem(title: "Settings", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("actionSettings"))
            self.navigationItem.rightBarButtonItems = [settingsButton]
            self.navigationItem.leftBarButtonItems = [signinButton]
            self.navigationItem.title = "Guest"
        }
        else if isCurrentUser {
            let editImage = UIImage(named: "imgEditLight")
            var editButton = UIBarButtonItem(image: editImage, style: UIBarButtonItemStyle.Plain, target: self, action: Selector("actionEdit"))
            var signoutButton = UIBarButtonItem(title: "Sign out", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("actionSignout"))
            var settingsButton = UIBarButtonItem(title: "Settings", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("actionSettings"))
            var spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
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
        
        if user != nil || isGuest {
            draw()
        }
	}
    
    override func viewDidAppear(animated: Bool){
        super.viewDidAppear(animated)
        refresh(force: true)
    }

	private func refresh(force: Bool = false) {

		/* Refreshes the top object but not the message list */
        if !isGuest {
            DataController.instance.withUserId(userId!, refresh: force) {
                user in
                self.refreshControl?.endRefreshing()
                if user != nil {
                    self.user = user
                    self.draw()
                }
            }
        }
	}

	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/

    @IBAction func actionBrowseFavorites(sender: UIButton) {
        if !isGuest {
            patchListFilter = PatchListFilter.Favorite
            self.performSegueWithIdentifier("PatchListSegue", sender: self)
        }
    }
    
	@IBAction func actionBrowseWatching(sender: UIButton) {
        if !isGuest {
            patchListFilter = PatchListFilter.Watching
            self.performSegueWithIdentifier("PatchListSegue", sender: self)
        }
	}

	@IBAction func actionBrowseOwned(sender: UIButton) {
        if !isGuest {
            patchListFilter = PatchListFilter.Owns
            self.performSegueWithIdentifier("PatchListSegue", sender: self)
        }
	}

	@IBAction func actionUserPhoto(sender: AnyObject) {
        Shared.showPhotoBrowser(userPhoto.imageForState(.Normal), view: sender as! UIView, viewController: self, entity: nil)
	}

    @IBAction func unwindFromUserEdit(segue: UIStoryboardSegue) {
        // Refresh results when unwinding from User edit/create screen to pickup any changes.
        self.refresh()
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
			let destinationViewController = UIStoryboard(name: "Lobby", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("LobbyNavigationController") as! UIViewController
			appDelegate.window!.setRootViewController(destinationViewController, animated: true)
		}
	}
    
    func actionSignin() {
        
        LocationController.instance.clearLastLocationAccepted()
        let storyboard: UIStoryboard = UIStoryboard(name: "Lobby", bundle: NSBundle.mainBundle())
        if let controller = storyboard.instantiateViewControllerWithIdentifier("SignInEditViewController") as? UIViewController {
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
	func actionEdit() {
		self.performSegueWithIdentifier("UserEditSegue", sender: nil)
	}

	func actionSettings() {
		self.performSegueWithIdentifier("SettingsSegue", sender: nil)
	}

	/*--------------------------------------------------------------------------------------------
	 * Methods
	 *--------------------------------------------------------------------------------------------*/

	private func draw() {
        
        if isGuest {
            userName.text = "Guest"
            userEmail.text = "discover@3meters.com"
            userPhoto.imageView?.contentMode = UIViewContentMode.ScaleAspectFill
            userPhoto.setImage(UIImage(named: "imgDefaultUser"), forState: .Normal)
            watchingButton.setTitle("Watching: --", forState: .Normal)
            ownsButton.setTitle("Owner: --", forState: .Normal)
            likesButton.setTitle("Favorites: --", forState: .Normal)
        }
        else {
            userName.text = user!.name
            userEmail.text = user!.email
            userPhoto.imageView?.contentMode = UIViewContentMode.ScaleAspectFill
            userPhoto.setImageWithPhoto(user!.getPhotoManaged(), animate: userPhoto.imageView?.image == nil)
            
            if user!.patchesWatching != nil {
                let count = user!.patchesWatchingValue == 0 ? "--" : String(user!.patchesWatchingValue)
                watchingButton.setTitle("Watching: \(count)", forState: .Normal)
            }
            if user!.patchesOwned != nil {
                let count = user!.patchesOwnedValue == 0 ? "--" : String(user!.patchesOwnedValue)
                ownsButton.setTitle("Owner: \(count)", forState: .Normal)
            }
            if user!.patchesLikes != nil {
                let count = user!.patchesLikesValue == 0 ? "--" : String(user!.patchesLikesValue)
                likesButton.setTitle("Favorites: \(count)", forState: .Normal)
            }
        }
	}
    
    override func bindCell(cell: UITableViewCell, object: AnyObject, tableView: UITableView?) {
        
        let view = cell.contentView.viewWithTag(1) as! MessageView
        Message.bindView(view, object: object, tableView: tableView, sizingOnly: false)
        if let label = view.description_ as? TTTAttributedLabel {
            label.delegate = self
        }
        view.delegate = self
    }
    
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == nil {
			return
		}

		switch segue.identifier! {
			case "PatchListSegue":
				if let controller = segue.destinationViewController as? PatchTableViewController {
					controller.filter = patchListFilter!
					controller.user = self.user
					patchListFilter = nil
				}
			case "UserEditSegue":
                if let navigationController = segue.destinationViewController as? UINavigationController {
                    if let controller = navigationController.topViewController as? UserEditViewController {
                        controller.entity = self.user
                    }
                }
			case "MessageDetailSegue":
				if let controller = segue.destinationViewController as? MessageDetailViewController {
					controller.message = selectedMessage
				}
			default: ()
		}
	}

	override func pullToRefreshAction(sender: AnyObject?) -> Void {
        if !isGuest {
            self.refresh(force: true)
            self.refreshQueryItems(force: true)
        }
        else {
            self.refreshControl?.endRefreshing()
        }
	}
}

extension  UserDetailViewController: UITableViewDelegate {

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as? QueryItem {
			if let message = queryResult.object as? Message {
				self.selectedMessage = message
				self.performSegueWithIdentifier("MessageDetailSegue", sender: self)
				return
			}
		}
		assert(false, "Couldn't set selectedMessage")
	}

	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

		// https://github.com/smileyborg/TableViewCellWithAutoLayout

		var cell = self.offscreenCells.objectForKey(CELL_IDENTIFIER) as? UITableViewCell

        if cell == nil {
            cell = buildCell(self.contentViewName!)
            configureCell(cell!)
            self.offscreenCells.setObject(cell!, forKey: CELL_IDENTIFIER)
        }

        /* Bind view to data for this row */
        let queryResult = self.fetchedResultsController.objectAtIndexPath(indexPath) as! QueryItem
        let view = Message.bindView(cell!.contentView.viewWithTag(1)!, object: queryResult.object, tableView: tableView, sizingOnly: true) as! MessageView

        /* Get the actual height required for the cell */
		var height = cell!.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height + 1

		return height
	}
}

extension UserDetailViewController: ViewDelegate {
    
    func view(container: UIView, didTapOnView view: UIView) {
        if let view = view as? AirImageView, container = container as? MessageView {
            if view.image != nil {
                Shared.showPhotoBrowser(view.image, view: view, viewController: self, entity: container.entity)
            }
        }
    }
}

extension UserDetailViewController: TTTAttributedLabelDelegate {
    
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        UIApplication.sharedApplication().openURL(url)
    }
}

