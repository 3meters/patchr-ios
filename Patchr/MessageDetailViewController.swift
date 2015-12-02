//
//  MessageDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class MessageDetailViewController: UITableViewController {

	var activity:  UIActivityIndicatorView?
	var message:   Message?
	var messageId: String?
    var deleted = false

    private var shareButtonFunctionMap = [Int: ShareButtonFunction]()

    private var isOwner: Bool {
        if let currentUser = UserController.instance.currentUser {
            if self.message != nil && self.message!.creator != nil {
                return currentUser.id_ == self.message!.creator.entityId
            }
        }
        return false
    }
    
    private var isPatchOwner: Bool {
        if let currentUser = UserController.instance.currentUser {
            if self.message != nil && self.message!.patch != nil && self.message!.patch!.ownerId != nil {
                return currentUser.id_ == self.message!.patch!.ownerId
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
    @IBOutlet weak var recipients:      UILabel!
    
    @IBOutlet weak var patchCell:       UITableViewCell!
    @IBOutlet weak var toolbarCell:     UITableViewCell!
    @IBOutlet weak var recipientsCell:  UITableViewCell!
    @IBOutlet weak var shareHolderCell: UITableViewCell!
    
	/*--------------------------------------------------------------------------------------------
	 * Lifecycle
	 *--------------------------------------------------------------------------------------------*/

	override func viewDidLoad() {

		if self.message != nil {
			self.messageId = self.message!.id_
		}
		
		guard self.messageId != nil else {
			fatalError("Message detail requires message id")
		}

		super.viewDidLoad()

        /* Ui tweaks */
		self.messagePhoto.imageView?.contentMode = UIViewContentMode.ScaleAspectFill
		self.userPhoto.imageView?.contentMode = UIViewContentMode.ScaleAspectFill
		self.patchPhoto.imageView?.contentMode = UIViewContentMode.ScaleAspectFill
		self.view.window?.backgroundColor = Colors.windowColor
		
        let linkColor = Colors.brandColorDark
        let linkActiveColor = Colors.brandColorLight
        
        self.description_.linkAttributes = [kCTForegroundColorAttributeName : linkColor]
        self.description_.activeLinkAttributes = [kCTForegroundColorAttributeName : linkActiveColor]
        self.description_.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
        self.description_.delegate = self
        
		/* Navigation bar buttons */
		drawNavButtons()

		/* Make sure any old content is cleared */
		self.description_.text?.removeAll(keepCapacity: false)
		self.createdDate.text?.removeAll(keepCapacity: false)
		self.messagePhoto.imageView?.image = nil
		self.patchName.setTitle(nil, forState: .Normal)
		self.patchPhoto.imageView?.image = nil
		self.userName.setTitle(nil, forState: .Normal)
		self.userPhoto.imageView?.image = nil
        self.likesButton.setTitle(nil, forState: .Normal)
	}
	
	func drawNavButtons(shareAllowed: Bool = true){
		
		let shareButton  = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: Selector("shareAction"))
		let spacer       = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
		spacer.width = SPACER_WIDTH
		
		if self.isOwner {
			let editImage    = Utils.imageEdit
			let editButton   = UIBarButtonItem(image: editImage, style: UIBarButtonItemStyle.Plain, target: self, action: Selector("editAction"))
			let deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: Selector("deleteAction"))
			self.navigationItem.rightBarButtonItems = shareAllowed ? [shareButton, spacer, deleteButton, spacer, editButton] : [deleteButton, spacer, editButton]
		}
		else if self.isPatchOwner {
			let removeImage    = UIImage(named: "imgRemoveLight")
			let removeButton   = UIBarButtonItem(image: removeImage, style: UIBarButtonItemStyle.Plain, target: self, action: Selector("removeAction"))
			self.navigationItem.rightBarButtonItems = shareAllowed ? [shareButton, spacer, removeButton] : [removeButton]
		}
		else {
			self.navigationItem.rightBarButtonItems = shareAllowed ? [shareButton] : []
		}
	}

	override func viewWillAppear(animated: Bool) {
		
		/* Use cached entity if available in the data model */
		if self.message == nil {
			if let message: Message? = Message.fetchOneById(self.messageId!, inManagedObjectContext: DataController.instance.mainContext) {
				self.message = message
			}
		}
		else {
			/* Entity could have been delete while we were away to check it. */
			let item = ServiceBase.fetchOneById(self.messageId!, inManagedObjectContext: DataController.instance.mainContext)
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
        setScreenName("MessageDetail")        
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		refresh(true)
	}
	
    override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)
		self.activity?.stopAnimating()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

	private func refresh(force: Bool = false) {
        
        if (self.message == nil) {
			self.activity?.startAnimating()
        }
		
		DataController.instance.backgroundOperationQueue.addOperationWithBlock {
			
			DataController.instance.withMessageId(self.messageId!, refresh: force) {
				[weak self] objectId, error in
				
				if self != nil {
					NSOperationQueue.mainQueue().addOperationWithBlock {
						self?.activity?.stopAnimating()
						self?.refreshControl?.endRefreshing()
						if error == nil {
							if objectId == nil {
								Shared.Toast("Message has been deleted")
								Utils.delay(2.0) {
									self?.navigationController?.popViewControllerAnimated(true)
								}
							}
							else {
								self?.message = DataController.instance.mainContext.objectWithID(objectId!) as? Message
								/* Remove share button if this is a share message */
								if self?.message!.type != nil && self?.message!.type == "share" {
									self?.drawNavButtons(false)
								}
								self?.draw()	// TODO: Can skip if no change in activityDate and modifiedDate
							}
						}
					}
				}
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
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        if let controller = storyboard.instantiateViewControllerWithIdentifier("PatchDetailViewController") as? PatchDetailViewController {
            controller.entityId = self.message!.patch.entityId
            self.navigationController?.pushViewController(controller, animated: true)
        }
	}

	@IBAction func userAction(sender: AnyObject) {
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        if let controller = storyboard.instantiateViewControllerWithIdentifier("UserDetailViewController") as? UserDetailViewController {
            if let creator = message!.creator {
                controller.entityId = creator.entityId
				controller.profileMode = false
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
	}

	@IBAction func photoAction(sender: AnyObject) {
        let browser = Shared.showPhotoBrowser(self.messagePhoto.imageForState(.Normal), animateFromView: sender as! UIView, viewController: self, entity: self.message)
        browser.target = self
	}

	@IBAction func reportAction(sender: AnyObject) {
		Alert("Not implemented")
	}
    
	@IBAction func likesAction(sender: AnyObject) {
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        if let controller = storyboard.instantiateViewControllerWithIdentifier("UserTableViewController") as? UserTableViewController {
            controller.message = self.message
            controller.filter = .MessageLikers
            self.navigationController?.pushViewController(controller, animated: true)
        }
	}

    func shareBrowseAction(sender: AnyObject){
		if let view = sender as? UIView {
			view.backgroundColor = Colors.windowColor
		}
        if self.message?.message != nil {
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            if let controller = storyboard.instantiateViewControllerWithIdentifier("MessageDetailViewController") as? MessageDetailViewController {
                controller.messageId = self.message!.message!.entityId
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
        else if self.message?.patch != nil {
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            if let controller = storyboard.instantiateViewControllerWithIdentifier("PatchDetailViewController") as? PatchDetailViewController {
                controller.entityId = self.message!.patch!.entityId
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
    
	func editAction() {
        /* Has its own nav because we segue modally and it needs its own stack */
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        if let controller = storyboard.instantiateViewControllerWithIdentifier("MessageEditViewController") as? MessageEditViewController {
            controller.inputEntity = self.message
            let navController = UINavigationController()
            navController.navigationBar.tintColor = Colors.brandColorDark
            navController.viewControllers = [controller]
            self.navigationController?.presentViewController(navController, animated: true, completion: nil)
        }
	}
    
    func deleteAction() {
        self.ActionConfirmationAlert(
            "Confirm Delete",
            message: "Are you sure you want to delete this?",
            actionTitle: "Delete", cancelTitle: "Cancel", delegate: self) {
                doIt in
                if doIt {
                    self.delete()
                }
        }
    }
    
    func removeAction() {
        self.ActionConfirmationAlert(
            "Confirm Remove",
            message: "Are you sure you want to remove this message from the patch?",
            actionTitle: "Remove", cancelTitle: "Cancel", delegate: self) {
                doIt in
                if doIt {
                    self.remove()
                }
        }
    }
    
    func dismissAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func likeDidChange(sender: NSNotification) {
        self.draw()
    }

	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/

	func draw() {
		
		Log.d("MessageDetail.draw called: \(self.message!.id_!)")
        
        if self.message!.type != nil && self.message!.type == "share" {
			
            self.recipientsCell.hidden = true
            self.shareHolderCell.hidden = false
			
            /* Share entity */
			
			let holderView = UIView()
			holderView.clipsToBounds = true
			holderView.borderColor = Colors.gray80pcntColor
			holderView.borderWidth = 1
			holderView.cornerRadius = 6
			
			if self.shareHolderCell.contentView.subviews.count == 0 {
				if self.message?.message != nil {
					
					var cellType: CellType = .TextAndPhoto
					if self.message!.message!.photo == nil {
						cellType = .Text
					}
					else if self.message!.message!.description_ == nil {
						cellType = .Photo
					}
					
					let shareView = MessageView(cellType: cellType)
					
					shareView.bindToEntity(self.message!.message!)
					
					holderView.addSubview(shareView)
					self.shareHolderCell.contentView.addSubview(holderView)
					
					/* Need correct width before layout and sizing */
					holderView.fillSuperviewWithLeftPadding(12, rightPadding: 12, topPadding: 0, bottomPadding: 0)
					shareView.fillSuperviewWithLeftPadding(12, rightPadding: 12, topPadding: 12, bottomPadding: 12)
					
					shareView.setNeedsLayout()
					shareView.layoutIfNeeded()
					shareView.sizeToFit()
					
					/* Row height not set until reloadData called below */
					self.shareHolderCell.contentView.frame.size.height = shareView.bounds.size.height + 24
					holderView.fillSuperviewWithLeftPadding(12, rightPadding: 12, topPadding: 0, bottomPadding: 0)

					let tap = UITapGestureRecognizer(target: self, action: "shareBrowseAction:");
					shareView.addGestureRecognizer(tap)
				}
				else if self.message?.patch != nil {
					
					let shareView = PatchView()
					
					shareView.borderColor = Colors.gray80pcntColor
					shareView.borderWidth = 1
					shareView.cornerRadius = 6
					shareView.shadow.backgroundColor = UIColor.clearColor()
					
					shareView.bindToEntity(self.message!.patch!, location: nil)
					
					self.shareHolderCell.contentView.addSubview(shareView)
					self.shareHolderCell.contentView.frame.size.height = 128
					shareView.fillSuperviewWithLeftPadding(12, rightPadding: 12, topPadding: 0, bottomPadding: 0)
					
					let tap = UITapGestureRecognizer(target: self, action: "shareBrowseAction:");
					shareView.addGestureRecognizer(tap)
				}
				else {
					/*
					 * The target of the share message has been deleted'
					 */
					let shareView = AirLabel()
					shareView.backgroundColor = Theme.colorBackgroundTileList
					shareView.text = "Deleted"
					
					holderView.addSubview(shareView)
					self.shareHolderCell.contentView.addSubview(holderView)
					
					self.shareHolderCell.contentView.frame.size.height = 48
					holderView.fillSuperview()
					shareView.fillSuperview()
				}
				
			}
        }
        else {
            self.toolbarCell.hidden = false
            
            /* Patch */
            if self.message!.patch != nil {
                self.patchCell.hidden = false
                self.patchPhoto.setImageWithPhoto(self.message!.patch.getPhotoManaged())
                self.patchName.setTitle(self.message!.patch.name, forState: .Normal)
            }
        }

		/* Message */

		self.createdDate.text = Utils.messageDateFormatter.stringFromDate(self.message!.createdDate)
		if self.message!.description_ != nil {
			self.description_.text = self.message!.description_
			self.description_.sizeToFit()
			self.description_.hidden = false
		}
        
        /* Photo */

		if message!.photo != nil {
			self.messagePhoto.hidden = false
            if !self.messagePhoto.linkedToPhoto(self.message!.photo) {
                self.messagePhoto.setImageWithPhoto(self.message!.photo)
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

		if let creator = self.message!.creator {
			self.userName.setTitle(creator.name, forState: .Normal)
			self.userPhoto.setImageWithPhoto(creator.getPhotoManaged())
		}
		else {
			self.userName.setTitle("Deleted", forState: .Normal)
            self.userPhoto.setImageWithPhoto(Entity.getDefaultPhoto("user", id: nil))
		}

		self.tableView.reloadData()
	}

    func delete() {
        
        let entityPath = "data/messages/\((self.message?.id_)!)"
        DataController.proxibase.deleteObject(entityPath) {
            response, error in
			
			NSOperationQueue.mainQueue().addOperationWithBlock {
				if let error = ServerError(error) {
					self.handleError(error)
				}
				else {
					DataController.instance.mainContext.deleteObject(self.message!)
					DataController.instance.saveContext(false)
					self.navigationController?.popViewControllerAnimated(true)
				}
			}
        }
    }
    
    func remove() {
                
        if let fromId = self.message!.id_, toId = self.message!.patchId {
            DataController.proxibase.deleteLink(fromId, toId: toId, linkType: LinkType.Content) {
                response, error in
                
				NSOperationQueue.mainQueue().addOperationWithBlock {
					if let error = ServerError(error) {
						UIViewController.topMostViewController()!.handleError(error)
					}
					else {
						DataController.instance.mainContext.deleteObject(self.message!)
						DataController.instance.saveContext(false)
						self.navigationController?.popViewControllerAnimated(true)
					}
				}
            }
        }
    }

    func shareUsing(patchr: Bool = true) {
        
        if patchr {
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            let controller = storyboard.instantiateViewControllerWithIdentifier("MessageEditViewController") as? MessageEditViewController
            /* viewDidLoad hasn't fired yet but awakeFromNib has */
            controller?.inputShareEntity = self.message
            controller?.inputShareSchema = Schema.ENTITY_MESSAGE
            controller?.inputShareId = self.messageId!
            controller?.inputMessageType = .Share
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
                    let message: MessageItem = MessageItem(entity: self.message!, shareUrl: url!)
                    
                    let activityViewController = UIActivityViewController(
                        activityItems: [message],
                        applicationActivities: nil)
                    
                    self.presentViewController(activityViewController, animated: true, completion: nil)
                }
            })
        }
    }
}

extension MessageDetailViewController {
    /*
    * UITableViewDelegate
    */
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
						return self.shareHolderCell.contentView.bounds.size.height	// Sized in draw()
                    }
                    return 143
                }
                else if indexPath.row == 7 {
                    return 48
                }
            }
        }
        
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
	}
}

extension MessageDetailViewController: UIActionSheetDelegate {
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex != actionSheet.cancelButtonIndex {
            // There are some strange visual artifacts with the share sheet and the presented
            // view controllers. Adding a small delay seems to prevent them.
            Utils.delay(0.4) {
				
                switch self.shareButtonFunctionMap[buttonIndex]! {
                case .Share:
                    self.shareUsing(true)
                    
                case .ShareVia:
                    self.shareUsing(false)
                }
            }
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
        
        let text = "Check out \(UserController.instance.currentUser.name)'s message to the \(self.entity.patch.name) patch! \(self.shareUrl) \n"
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
