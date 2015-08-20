//
//  MessageDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class MessageDetailViewController: UITableViewController {

    var progress:  MBProgressHUD?
	var message:   Message!
	var messageId: String?
    var deleted = false
    private var shareButtonFunctionMap = [Int: ShareButtonFunction]()

    private var isOwner: Bool {
        if let currentUser = UserController.instance.currentUser {
            if message != nil && message.creator != nil {
                return currentUser.id_ == message.creator.entityId
            }
        }
        return false
    }
    
    private var isPatchOwner: Bool {
        if let currentUser = UserController.instance.currentUser {
            if message != nil && message.patch != nil && message.patch.ownerId != nil {
                return currentUser.id_ == message.patch.ownerId
            }
        }
        return false
    }

	/* Outlets are initialized before viewDidLoad is called */

	@IBOutlet weak var patchName:       UIButton!
	@IBOutlet weak var patchPhoto:      AirImageButton!
	@IBOutlet weak var userPhoto:       AirImageButton!
	@IBOutlet weak var userName:        UIButton!
	@IBOutlet weak var createdDate:     UILabel!
	@IBOutlet weak var messagePhoto:    AirImageButton!
	@IBOutlet weak var likeButton:      AirLikeButton!
	@IBOutlet weak var likesButton:     UIButton!
    @IBOutlet weak var description_:    TTTAttributedLabel!
    @IBOutlet weak var shareHolder:     UIView!
    @IBOutlet weak var recipients:      UILabel!
    
    @IBOutlet weak var patchCell:       UITableViewCell!
    @IBOutlet weak var toolbarCell:     UITableViewCell!
    @IBOutlet weak var recipientsCell:  UITableViewCell!
    @IBOutlet weak var shareHolderCell: UITableViewCell!
	/*--------------------------------------------------------------------------------------------
	 * Lifecycle
	 *--------------------------------------------------------------------------------------------*/

	override func viewDidLoad() {

		if message != nil {
			messageId = message.id_
		}

		super.viewDidLoad()

        /* Ui tweaks */
		self.messagePhoto.imageView?.contentMode = UIViewContentMode.ScaleAspectFill
		self.userPhoto.imageView?.contentMode = UIViewContentMode.ScaleAspectFill
		self.patchPhoto.imageView?.contentMode = UIViewContentMode.ScaleAspectFill
        
        let linkColor = Colors.brandColorDark
        let linkActiveColor = Colors.brandColorLight
        
        self.description_.linkAttributes = [kCTForegroundColorAttributeName : linkColor]
        self.description_.activeLinkAttributes = [kCTForegroundColorAttributeName : linkActiveColor]
        self.description_.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
        self.description_.delegate = self

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
        else if isPatchOwner {
            let removeImage    = UIImage(named: "imgCancelLight")
            var removeButton   = UIBarButtonItem(image: removeImage, style: UIBarButtonItemStyle.Plain, target: self, action: Selector("removeAction:"))
            var spacer       = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
            spacer.width = SPACER_WIDTH
            self.navigationItem.rightBarButtonItems = [shareButton, spacer, removeButton]
        }
        else {
            self.navigationItem.rightBarButtonItems = [shareButton]
        }

		/* Make sure any old content is cleared */
		self.description_.text?.removeAll(keepCapacity: false)
		self.createdDate.text?.removeAll(keepCapacity: false)
		self.messagePhoto.imageView?.image = nil
		self.patchName.setTitle(nil, forState: .Normal)
		self.patchPhoto.imageView?.image = nil
		self.userName.setTitle(nil, forState: .Normal)
		self.userPhoto.imageView?.image = nil
        self.likesButton.setTitle(nil, forState: .Normal)
        
        /* Wacky activity control for body */
        progress = MBProgressHUD(view: self.view)
        progress!.mode = MBProgressHUDMode.Indeterminate
        progress!.square = true
        progress!.opacity = 0.0
        progress!.userInteractionEnabled = false
        progress!.activityIndicatorColor = Colors.brandColorDark
        self.view.addSubview(progress!)
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
        
        self.view.window?.backgroundColor = Colors.windowColor
        
		super.viewWillAppear(animated)

		if self.message != nil {
			draw()
		}
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "likeDidChange:", name: Events.LikeDidChange, object: nil)
        setScreenName("MessageDetail")        
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
        if (self.message == nil) {
            self.progress?.minShowTime = 1
            self.progress?.removeFromSuperViewOnHide = true
            self.progress?.show(true)
        }
        
		DataController.instance.withMessageId(messageId!, refresh: force) {
			message in
            
            self.progress?.hide(true)
			self.refreshControl?.endRefreshing()
			if message != nil {
                
                /* Remove share button if this is a share message */
                if message!.type != nil && message!.type == "share" {
                    self.navigationItem.rightBarButtonItems = []
                }
                
				self.message = message
                self.tableView.beginUpdates()
				self.draw()
                self.tableView.endUpdates()
			}
            else {
                Shared.Toast("Message has been deleted")
                delay(2.0, {
                    () -> () in
                    self.navigationController?.popViewControllerAnimated(true)
                })
            }
		}
	}
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
        var browser = Shared.showPhotoBrowser(self.messagePhoto.imageForState(.Normal), view: sender as! UIView, viewController: self, entity: self.message)
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
    
    @IBAction func removeAction(sender: AnyObject) {
        self.ActionConfirmationAlert(
            title: "Confirm Remove",
            message: "Are you sure you want to remove this message from the patch?",
            actionTitle: "Remove", cancelTitle: "Cancel", delegate: self) {
                doIt in
                if doIt {
                    self.remove()
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

    func shareBrowseAction(sender: AnyObject){
        if message.message != nil {
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            if let controller = storyboard.instantiateViewControllerWithIdentifier("MessageDetailViewController") as? MessageDetailViewController {
                controller.messageId = message.message.entityId
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
        else if message.patch != nil {
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            if let controller = storyboard.instantiateViewControllerWithIdentifier("PatchDetailViewController") as? PatchDetailViewController {
                controller.patchId = message.patch.entityId
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
	func shareAction() {
        
        if self.message != nil {
            let sheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: nil)
            
            shareButtonFunctionMap[sheet.addButtonWithTitle("Share")] = .Share
            shareButtonFunctionMap[sheet.addButtonWithTitle("Share via")] = .ShareVia
            sheet.addButtonWithTitle("Cancel")
            sheet.cancelButtonIndex = sheet.numberOfButtons - 1
            
            sheet.showInView(self.view)
        }
	}
    
    func dismissAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
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
        
        if message!.type != nil && message!.type == "share" {
            self.recipientsCell.hidden = true
            self.shareHolderCell.hidden = false
            
            /* Share entity */
            
            var view: BaseView!
            if message.message != nil {
                view = NSBundle.mainBundle().loadNibNamed("MessageView", owner: self, options: nil)[0] as! BaseView
                view.frame.size.width = self.shareHolder.bounds.size.width
                Message.bindView(view, object: message.message!, tableView: self.tableView)
                
                /* Tweak the message view to suit display as static */
                if let messageView = view as? MessageView {
                    messageView.toolbarHeight.constant = 0
                    if let recognizers = messageView.photo.gestureRecognizers {
                        for recognizer in recognizers {
                            messageView.photo.removeGestureRecognizer(recognizer as! UIGestureRecognizer)
                        }
                    }
                }
                
                view.frame.size.height = view.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height + 1
                self.shareHolder?.addSubview(view)
            }
            else if message.patch != nil {
                view = NSBundle.mainBundle().loadNibNamed("PatchNormalView", owner: self, options: nil)[0] as! BaseView
                view.frame.size.width = self.shareHolder.bounds.size.width
                Patch.bindView(view, object: message.patch!, tableView: self.tableView)
                self.shareHolder?.addSubview(view)
            }
            
            let views = Dictionary(dictionaryLiteral: ("view", view))
            let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: nil, metrics: nil, views: views)
            let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: nil, metrics: nil, views: views)
            self.shareHolder?.addConstraints(horizontalConstraints)
            self.shareHolder?.addConstraints(verticalConstraints)
            
            var tap = UITapGestureRecognizer(target: self, action: "shareBrowseAction:");
            self.shareHolder?.addGestureRecognizer(tap)
        }
        else {
            self.toolbarCell.hidden = false
            
            /* Patch */
            if message!.patch != nil {
                self.patchCell.hidden = false
                self.patchPhoto.setImageWithPhoto(message!.patch.getPhotoManaged())
                self.patchName.setTitle(message!.patch.name, forState: .Normal)
            }
        }

		/* Message */

		self.createdDate.text = Utils.messageDateFormatter.stringFromDate(message!.createdDate)
		if message!.description_ != nil {
			self.description_.text = message!.description_
			self.description_.sizeToFit()
			self.description_.hidden = false
		}
        
        /* Photo */

		if message!.photo != nil {
			self.messagePhoto.hidden = false
            if !self.messagePhoto.linkedToPhoto(self.message!.photo) {
                self.messagePhoto.setImageWithPhoto(message!.photo)
            }
		}
		else {
			self.messagePhoto.hidden = true
			self.messagePhoto.frame.size.height = 0
			self.messagePhoto.sizeToFit()
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
			self.userName.setTitle("Deleted", forState: .Normal)
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
    
    func remove() {
                
        if let fromId = self.message!.id_, toId = self.message!.patchId {
            DataController.proxibase.deleteLink(fromId, toId: toId, linkType: LinkType.Content) {
                response, error in
                
                if let error = ServerError(error) {
                    UIViewController.topMostViewController()!.handleError(error)
                }
                else {
                    DataController.instance.managedObjectContext.deleteObject(self.message!)
                    if DataController.instance.managedObjectContext.save(nil) {
                        self.navigationController?.popViewControllerAnimated(true)
                    }
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

    func shareUsing(patchr: Bool = true) {
        
        if patchr {
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            let controller = storyboard.instantiateViewControllerWithIdentifier("MessageEditViewController") as? MessageEditViewController
            /* viewDidLoad hasn't fired yet but awakeFromNib has */
            controller?.shareEntity = self.message
            controller?.shareSchema = Schema.ENTITY_MESSAGE
            controller?.shareId = self.messageId!
            controller?.messageType = .Share
            self.presentViewController(UINavigationController(rootViewController: controller!), animated: true, completion: nil)
        }
        else {
            Branch.getInstance().getShortURLWithParams(["entityId":self.messageId!, "entitySchema":"message"], andChannel: "patchr-ios", andFeature: BRANCH_FEATURE_TAG_SHARE, andCallback: {
                (url: String?, error: NSError?) -> Void in
                
                if let error = ServerError(error) {
                    UIViewController.topMostViewController()!.handleError(error)
                }
                else {
                    Log.d("Branch link created: \(url!)")
                    var message: MessageItem = MessageItem(entity: self.message!, shareUrl: url!)
                    
                    let activityViewController = UIActivityViewController(
                        activityItems: [message],
                        applicationActivities: nil)
                    
                    self.presentViewController(activityViewController, animated: true, completion: nil)
                }
            })
        }
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
            
            if message.type != nil && message.type == "share" {
                if indexPath.row == 0 {
                    return 0
                }
                else if indexPath.row == 5 {
                    return 0
                }
                else if indexPath.row == 6 {
                    if message.message != nil {
                        return self.shareHolder.bounds.size.height + 16
                    }
                    return 143
                }
                else if indexPath.row == 7 {
                    return 48
                }
            }
        }
        
        var height = super.tableView(tableView, heightForRowAtIndexPath: indexPath) as CGFloat!
        return height
	}
}

extension MessageDetailViewController: UIActionSheetDelegate {
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex != actionSheet.cancelButtonIndex {
            // There are some strange visual artifacts with the share sheet and the presented
            // view controllers. Adding a small delay seems to prevent them.
            delay(0.4, {
                () -> () in
                switch self.shareButtonFunctionMap[buttonIndex]! {
                case .Share:
                    self.shareUsing(patchr: true)
                    
                case .ShareVia:
                    self.shareUsing(patchr: false)
                }
            })
        }
    }
}

extension MessageDetailViewController: TTTAttributedLabelDelegate {
    
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        UIApplication.sharedApplication().openURL(url)
    }
}

class MessageItem: NSObject, UIActivityItemSource {
    
    var entity: Message
    var shareUrl: String
    
    init(entity: Message, shareUrl: String) {
        self.entity = entity
        self.shareUrl = shareUrl
    }
    
    func activityViewControllerPlaceholderItem(activityViewController: UIActivityViewController) -> AnyObject {
        return ""
    }
    
    func activityViewController(activityViewController: UIActivityViewController, itemForActivityType activityType: String) -> AnyObject? {
        
        var text = "Check out \(UserController.instance.currentUser.name)'s message to the \(self.entity.patch.name) patch! \(self.shareUrl) \n"
        if activityType == UIActivityTypeMail {
            return text
        }
        else {
            return text
        }
    }
    
    func activityViewController(activityViewController: UIActivityViewController, subjectForActivityType activityType: String?) -> String {
        if activityType == UIActivityTypeMail || activityType == "com.google.Gmail.ShareExtension" {
            return "Message by \(UserController.instance.currentUser.name) on Patchr"
        }
        return ""
    }
}

private enum ShareButtonFunction {
    case Share
    case ShareVia
}
