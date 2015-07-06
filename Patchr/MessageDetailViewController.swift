//
//  MessageDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class MessageDetailViewController: UITableViewController {

	var message:   Message!
	var messageId: String?
    var deleted = false

	var messageDateFormatter: NSDateFormatter!
    
    private var isOwner: Bool {
        if let currentUser = UserController.instance.currentUser {
            if message != nil {
                return currentUser.id_ == message.creator.entityId
            }
        }
        return false
    }
    
	/* Outlets are initialized before viewDidLoad is called */

	@IBOutlet weak var patchName:    UIButton!
	@IBOutlet weak var patchPhoto:   AirImageButton!
	@IBOutlet weak var userPhoto:    AirImageButton!
	@IBOutlet weak var userName:     UIButton!
	@IBOutlet weak var description_: UILabel!
	@IBOutlet weak var createdDate:  UILabel!
	@IBOutlet weak var photo:        AirImageButton!
	@IBOutlet weak var likeButton:   AirLikeButton!
	@IBOutlet weak var likesButton:  UIButton!

	/*--------------------------------------------------------------------------------------------
	 * Lifecycle
	 *--------------------------------------------------------------------------------------------*/

	override func viewDidLoad() {

		if message != nil {
			messageId = message.id_
		}

		super.viewDidLoad()

		let dateFormatter = NSDateFormatter()
		dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
		dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
		dateFormatter.doesRelativeDateFormatting = true
		self.messageDateFormatter = dateFormatter

        /* Ui tweaks */
		self.photo.imageView?.contentMode = UIViewContentMode.ScaleAspectFill
		self.userPhoto.imageView?.contentMode = UIViewContentMode.ScaleAspectFill
		self.patchPhoto.imageView?.contentMode = UIViewContentMode.ScaleAspectFill

		/* Navigation bar buttons */
        var shareButton  = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: Selector("shareAction"))
        if isOwner {
            let editImage    = UIImage(named: "imgEditLight")
            var editButton   = UIBarButtonItem(image: editImage, style: UIBarButtonItemStyle.Plain, target: self, action: Selector("editAction"))
            var spacer       = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
            var deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: Selector("deleteAction:"))
            spacer.width = SPACER_WIDTH
            self.navigationItem.rightBarButtonItems = [shareButton, spacer, deleteButton, spacer, editButton]
        }
        else {
            self.navigationItem.rightBarButtonItems = [shareButton]
        }

		/* Make sure any old content is cleared */
		self.description_.text?.removeAll(keepCapacity: false)
		self.createdDate.text?.removeAll(keepCapacity: false)
		self.photo.imageView?.image = nil
		self.patchName.setTitle(nil, forState: .Normal)
		self.patchPhoto.imageView?.image = nil
		self.userName.setTitle(nil, forState: .Normal)
		self.userPhoto.imageView?.image = nil
        self.likesButton.setTitle(nil, forState: .Normal)
	}

	override func viewWillAppear(animated: Bool) {
        /*
        * Entity could have been delete while we were away to check it.
        */
        if self.message != nil {
            let item = ServiceBase.fetchOneById(messageId, inManagedObjectContext: DataController.instance.managedObjectContext)
            if item == nil {
                self.navigationController?.popViewControllerAnimated(false)
                return
            }
        }
        
		super.viewWillAppear(animated)

		if self.message != nil {
			draw()
		}
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "likeDidChange:", name: Events.LikeDidChange, object: nil)
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

        description_.preferredMaxLayoutWidth = description_.frame.size.width
		self.view.layoutIfNeeded()
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		refresh(force: true)
	}
    
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

	private func refresh(force: Bool = false) {
		DataController.instance.withMessageId(messageId!, refresh: force) {
			message in
			self.refreshControl?.endRefreshing()
			if message != nil {
				self.message = message
				self.draw()
			}
		}
	}

	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/

	@IBAction func patchAction(sender: AnyObject) {
		self.performSegueWithIdentifier("PatchDetailSegue", sender: self)
	}

	@IBAction func userAction(sender: AnyObject) {
		self.performSegueWithIdentifier("UserDetailSegue", sender: self)
	}

	@IBAction func photoAction(sender: AnyObject) {
        var browser = Shared.showPhotoBrowser(self.photo.imageForState(.Normal), view: sender as! UIView, viewController: self, entity: self.message)
        browser.target = self
	}

	@IBAction func reportAction(sender: AnyObject) {
		Alert("Not implemented")
	}
    
    @IBAction func deleteAction(sender: AnyObject) {
        self.ActionConfirmationAlert(
            title: "Confirm Delete",
            message: "Are you sure you want to delete this?",
            actionTitle: "Delete", cancelTitle: "Cancel", delegate: self) {
                doIt in
                if doIt {
                    self.delete()
                }
        }
    }
    
	@IBAction func likesAction(sender: AnyObject) {
		self.performSegueWithIdentifier("LikeListSegue", sender: self)
	}

	@IBAction func unwindFromMessageEdit(segue: UIStoryboardSegue) {
		// Refresh results when unwinding from message edit to pickup any changes.
		DataController.instance.withMessageId(message!.id_, refresh: true) {
			(_) -> Void in
			self.draw()
		}
	}

	func shareAction() {

		let messageURL
									   = NSURL(string: "http://patchr.com/message/\(self.message!.id_)") ?? NSURL(string: "http://patchr.com")!
		let shareText                  = "Checkout this patch message! \n\n\(messageURL.absoluteString!) \n\nGet the Patchr app at http://patchr.com"
		var activityItems: [AnyObject] = [shareText]

		let activityViewController = UIActivityViewController(
		activityItems: activityItems,
		applicationActivities: nil)

		self.presentViewController(activityViewController, animated: true, completion: nil)
	}

	func editAction() {
		self.performSegueWithIdentifier("MessageEditSegue", sender: self)
	}
    
    func likeDidChange(sender: NSNotification) {
        self.draw()
    }

	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/

	func draw() {

		/* Patch */

		if message!.patch != nil {
			self.patchPhoto.setImageWithPhoto(message!.patch.getPhotoManaged())
			self.patchName.setTitle(message!.patch.name, forState: .Normal)
		}

		/* Message */

		self.createdDate.text = self.messageDateFormatter.stringFromDate(message!.createdDate)
		if message!.description_ != nil {
			self.description_.text = message!.description_
			self.description_.sizeToFit()
			self.description_.hidden = false
		}

		//self.photo.setImage(nil, forState: UIControlState.Normal)
		if message!.photo != nil {
			self.photo.hidden = false
			self.photo.setImageWithPhoto(message!.photo)
		}
		else {
			self.photo.hidden = true
			self.photo.frame.size.height = 0
			self.photo.sizeToFit()
		}

		/* Like button */
        likeButton.bindEntity(self.message)

		/* Likes button */

		if message?.countLikesValue == 0 {
			if likesButton.alpha != 0 {
				likesButton.fadeOut()
			}
		}
		else {
			let likesTitle = self.message!.countLikesValue == 1
					? "\(self.message!.countLikes) like"
					: "\(self.message!.countLikes ?? 0) likes"
			self.likesButton.setTitle(likesTitle, forState: UIControlState.Normal)
			if likesButton.alpha == 0 {
				likesButton.fadeIn()
			}
		}

		/* User */

		if let creator = message!.creator {
			self.userName.setTitle(creator.name, forState: .Normal)
			self.userPhoto.setImageWithPhoto(creator.getPhotoManaged())
		}
		else {
			self.userName.setTitle("Unknown", forState: .Normal)
			self.userPhoto.setImageWithPhoto(Entity.getDefaultPhoto("user"))
		}

		self.tableView.reloadData()
	}
    
    func delete() {
        
        let entityPath = "data/messages/\((self.message?.id_)!)"
        DataController.proxibase.deleteObject(entityPath) {
            response, error in
            
            if let error = ServerError(error) {
                self.handleError(error)
            }
            else {
                DataController.instance.managedObjectContext.deleteObject(self.message!)
                if DataController.instance.managedObjectContext.save(nil) {
                    self.navigationController?.popViewControllerAnimated(true)
                }
            }
        }
    }

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

		if segue.identifier == nil {
			return
		}

		switch segue.identifier! {
			case "PatchDetailSegue":
				if let patchDetailViewController = segue.destinationViewController as? PatchDetailViewController {
					patchDetailViewController.patchId = self.message!.patch.entityId
				}
			case "UserDetailSegue":
				if let controller = segue.destinationViewController as? UserDetailViewController {
					if let creator = message!.creator {
						controller.userId = creator.entityId
					}
				}
			case "MessageEditSegue":
				if let navigationController = segue.destinationViewController as? UINavigationController {
					if let controller = navigationController.topViewController as? MessageEditViewController {
						controller.entity = message
					}
				}
			case "LikeListSegue":
				if let controller = segue.destinationViewController as? UserTableViewController {
					controller.message = self.message
					controller.filter = .MessageLikers
				}
			default: ()
		}
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
}

extension MessageDetailViewController: UITableViewDelegate {

	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if let message = self.message {
            if indexPath.row == 2 {
                return (message.description_ == nil)
                    ? CGFloat(0)
                    : CGFloat(self.description_.frame.origin.y * 2 + self.description_.frame.size.height)
            }
            else if indexPath.row == 4 {
                
                /* Size so photo aspect ratio is 4:3 */
                var height: CGFloat = 0
                if message.photo != nil {
                    height = ((UIScreen.mainScreen().bounds.size.width - 24) * 0.75)
                }
                return height
            }
        }
        
        var height = super.tableView(tableView, heightForRowAtIndexPath: indexPath) as CGFloat!
        return height
	}
}