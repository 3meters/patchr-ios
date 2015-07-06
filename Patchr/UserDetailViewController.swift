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

	private let cellNibName = "MessageTableViewCell"
	private var selectedMessage:      Message?
	private var messageDateFormatter: NSDateFormatter!
	private var offscreenCells:       NSMutableDictionary = NSMutableDictionary()
	private var isCurrentUser                             = false
    private var patchListFilter: PatchListFilter? = nil

	/* Outlets are initialized before viewDidLoad is called */

	@IBOutlet weak var userName:       UILabel!
	@IBOutlet weak var userEmail:      UILabel!
	@IBOutlet weak var userPhoto:      AirImageButton!
	@IBOutlet weak var watchingButton: UIButton!
	@IBOutlet weak var ownsButton:     UIButton!

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
        
        if (user == nil && userId == nil && UserController.instance.currentUser != nil) {
            user = UserController.instance.currentUser
            isCurrentUser = true
        }
        
        if user != nil {
            userId = user.id_
        }
        
		super.viewDidLoad()

		tableView.registerNib(UINib(nibName: cellNibName, bundle: nil), forCellReuseIdentifier: "Cell")

		let dateFormatter = NSDateFormatter()
		dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
		dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
		dateFormatter.doesRelativeDateFormatting = true
		self.messageDateFormatter = dateFormatter

        /* UI prep */
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None;
        /* Clear any old content */
        userName.text?.removeAll(keepCapacity: false)
        userEmail.text?.removeAll(keepCapacity: false)
        userPhoto.imageView?.image = nil        
        
        /* Navigation bar buttons */
        if (isCurrentUser ) {
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
        
        if user != nil {
            draw()
        }
	}
    
    override func viewDidAppear(animated: Bool){
        super.viewDidAppear(animated)
        refresh(force: true)
    }

	private func refresh(force: Bool = false) {
		/* Refreshes the top object but not the message list */
		DataController.instance.withUserId(userId!, refresh: force) {
			user in
            self.refreshControl?.endRefreshing()
			if user != nil {
				self.user = user
				self.draw()
			}
		}
	}

	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/

	@IBAction func actionBrowseWatching(sender: UIButton) {
        patchListFilter = PatchListFilter.Watching
        self.performSegueWithIdentifier("PatchListSegue", sender: self)
	}

	@IBAction func actionBrowseOwned(sender: UIButton) {
        patchListFilter = PatchListFilter.Owns
        self.performSegueWithIdentifier("PatchListSegue", sender: self)
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
				NSLog("Error during logout \(error)")
			}
            
            /* Make sure state is cleared */
            LocationController.instance.locationLocked = nil

			let appDelegate               = UIApplication.sharedApplication().delegate as! AppDelegate
			let destinationViewController = UIStoryboard(name: "Lobby", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("SplashNavigationController") as! UIViewController
			appDelegate.window!.setRootViewController(destinationViewController, animated: true)
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
        
		userName.text = user!.name
		userEmail.text = user!.email
        userPhoto.imageView?.contentMode = UIViewContentMode.ScaleAspectFill
        userPhoto.setImageWithPhoto(user!.getPhotoManaged(), animate: userPhoto.imageView?.image == nil)
        
		if user!.patchesWatching != nil {
			watchingButton.setTitle("Watching: " + String(user!.patchesWatchingValue), forState: .Normal)
		}
		if user!.patchesOwned != nil {
			ownsButton.setTitle("Owner: " + String(user!.patchesOwnedValue), forState: .Normal)
		}
	}

	override func configureCell(cell: UITableViewCell, object: AnyObject) {

		// The cell width seems to incorrect occassionally
		if CGRectGetWidth(cell.bounds) != CGRectGetWidth(self.tableView.bounds) {
			cell.bounds = CGRect(x: 0, y: 0, width: CGRectGetWidth(self.tableView.bounds), height: CGRectGetHeight(cell.frame))
			cell.setNeedsLayout()
			cell.layoutIfNeeded()
		}

		let queryResult = object as! QueryItem
		let message = queryResult.object as! Message
		let messageCell = cell as! MessageTableViewCell
        
        messageCell.entity = message
		messageCell.delegate = self

		messageCell.description_.text = nil
		messageCell.userName.text = nil
		messageCell.patchName.text = nil

		messageCell.description_.text = message.description_

		if let photo = message.photo {
            messageCell.photo.setImageWithPhoto(photo, animate: messageCell.photo.image == nil)
			messageCell.photoHolderHeight.constant = messageCell.photo.frame.height + 8
		}
		else {
			messageCell.photoHolderHeight.constant = 0
		}

		if message.creator != nil {
			messageCell.userName.text = message.creator.name
            messageCell.userPhoto.setImageWithPhoto(message.creator.getPhotoManaged(), animate: messageCell.userPhoto.image == nil)
		}

		messageCell.likes.hidden = true
		if message.countLikes != nil {
			if message.countLikes?.integerValue != 0 {
				let likesTitle = message.countLikes?.integerValue == 1
						? "\(message.countLikes) like"
						: "\(message.countLikes ?? 0) likes"
				messageCell.likes.text = likesTitle
				messageCell.likes.hidden = false
			}
		}

		messageCell.createdDate.text = self.messageDateFormatter.stringFromDate(message.createdDate)
		if let patch = message.patch {
			messageCell.patchName.text = (message.type != nil && message.type == "share") ? "Shared by" : patch.name
		}
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
		self.refresh(force: true)
        self.refreshQueryItems(force: true)
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

		var cell = self.offscreenCells.objectForKey("Cell") as? UITableViewCell

		if cell == nil {
			let nibObjects = NSBundle.mainBundle().loadNibNamed(cellNibName, owner: self, options: nil)
			cell = nibObjects[0] as? UITableViewCell
			self.offscreenCells.setObject(cell!, forKey: "Cell")
		}

		let object: AnyObject = self.fetchedResultsController.objectAtIndexPath(indexPath)

		self.configureCell(cell!, object: object)

		cell?.setNeedsUpdateConstraints()
		cell?.updateConstraintsIfNeeded()
		cell?.bounds = CGRect(x: 0, y: 0, width: CGRectGetWidth(self.tableView.bounds), height: CGRectGetHeight(cell!.frame))
		cell?.setNeedsLayout()
		cell?.layoutIfNeeded()

		var height = cell!.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height + 1

		return height
	}
}

extension UserDetailViewController: TableViewCellDelegate {

	func tableViewCell(cell: UITableViewCell, didTapOnView view: UIView) {
		let messageCell = cell as! MessageTableViewCell
		if view == messageCell.photo && messageCell.photo.image != nil {
            Shared.showPhotoBrowser(messageCell.photo.image, view: view, viewController: self, entity: messageCell.entity)
		}
	}
}
