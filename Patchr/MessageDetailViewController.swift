//
//  MessageDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class MessageDetailViewController: UITableViewController {

	var activity:       UIActivityIndicatorView?
	var inputMessage:   Message?
	var inputMessageId: String?
    var deleted = false

    private var shareButtonFunctionMap = [Int: ShareButtonFunction]()
	
	private var isShare: Bool {
		return (self.inputMessage?.type != nil && self.inputMessage!.type == "share")
	}

    private var isOwner: Bool {
        if let currentUser = UserController.instance.currentUser {
            if self.inputMessage != nil && self.inputMessage!.creator != nil {
                return currentUser.id_ == self.inputMessage!.creator.entityId
            }
        }
        return false
    }
    
    private var isPatchOwner: Bool {
        if let currentUser = UserController.instance.currentUser {
            if self.inputMessage != nil && self.inputMessage!.patch != nil && self.inputMessage!.patch!.ownerId != nil {
                return currentUser.id_ == self.inputMessage!.patch!.ownerId
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
    @IBOutlet weak var recipients:      AirLabelDisplay!
    
    @IBOutlet weak var patchCell:       UITableViewCell!
    @IBOutlet weak var toolbarCell:     UITableViewCell!
    @IBOutlet weak var recipientsCell:  UITableViewCell!
    @IBOutlet weak var shareHolderCell: UITableViewCell!
	
	/*--------------------------------------------------------------------------------------------
	 * Lifecycle
	 *--------------------------------------------------------------------------------------------*/

	override func viewDidLoad() {

		if self.inputMessage != nil {
			self.inputMessageId = self.inputMessage!.id_
		}
		
		guard self.inputMessageId != nil else {
			fatalError("Message detail requires message id")
		}

		super.viewDidLoad()

        /* Ui tweaks */
		self.view.window?.backgroundColor = Theme.colorBackgroundWindow
		self.userPhoto.imageView?.contentMode = UIViewContentMode.ScaleAspectFill
		self.patchPhoto.imageView?.contentMode = UIViewContentMode.ScaleAspectFill
		self.messagePhoto.imageView?.contentMode = UIViewContentMode.ScaleAspectFill
		self.messagePhoto.translatesAutoresizingMaskIntoConstraints = true
		self.messagePhoto.contentMode = .ScaleAspectFill
		self.messagePhoto.contentVerticalAlignment = .Fill
		self.messagePhoto.contentHorizontalAlignment = .Fill
		
        let linkColor = Theme.colorTint
        let linkActiveColor = Theme.colorTint
        
        self.description_.linkAttributes = [kCTForegroundColorAttributeName : linkColor]
        self.description_.activeLinkAttributes = [kCTForegroundColorAttributeName : linkActiveColor]
        self.description_.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
        self.description_.delegate = self
        
		/* Navigation bar buttons */
		if self.inputMessage != nil {
			drawNavButtons(true)
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
	}
	
	override func viewWillAppear(animated: Bool) {
		
		/* Use cached entity if available in the data model */
		if self.inputMessage == nil {
			if let message: Message? = Message.fetchOneById(self.inputMessageId!, inManagedObjectContext: DataController.instance.mainContext) {
				self.inputMessage = message
			}
		}
		else {
			/* Entity could have been delete while we were away to check it. */
			let item = ServiceBase.fetchOneById(self.inputMessageId!, inManagedObjectContext: DataController.instance.mainContext)
			if item == nil {
				self.navigationController?.popViewControllerAnimated(false)
				return
			}
		}
		
		super.viewWillAppear(animated)
		
		if self.inputMessage != nil {
			draw()
		}
		
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "likeDidChange:", name: Events.LikeDidChange, object: nil)
        setScreenName("MessageDetail")        
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.bounds.size.width)
		self.tableView.bounds.size.width = viewWidth
		self.messagePhoto.anchorInCenterWithWidth(viewWidth - 24, height: (viewWidth - 24) * 0.75)
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
        
        if (self.inputMessage == nil) {
			self.activity?.startAnimating()
        }
		
		DataController.instance.backgroundOperationQueue.addOperationWithBlock {
			
			let blockCriteria = (self.inputMessage != nil
				&& self.inputMessage!.type != nil
				&& self.inputMessage!.type == "share"
				&& (self.inputMessage!.message == nil && self.inputMessage!.patch == nil)
				&& !self.inputMessage!.decoratedValue)
			
			DataController.instance.withMessageId(self.inputMessageId!, refresh: force, blockCriteria: blockCriteria) {
				[weak self] objectId, error in
				
				if self != nil {
					NSOperationQueue.mainQueue().addOperationWithBlock {
						self?.activity?.stopAnimating()
						if error == nil {
							if objectId == nil {
								Shared.Toast("Message has been deleted")
								Utils.delay(2.0) {
									self?.navigationController?.popViewControllerAnimated(true)
								}
							}
							else {
								self?.inputMessage = DataController.instance.mainContext.objectWithID(objectId!) as? Message
								self?.drawNavButtons(false)
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
            controller.entityId = self.inputMessage!.patch.entityId
            self.navigationController?.pushViewController(controller, animated: true)
        }
	}

	@IBAction func userAction(sender: AnyObject) {
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        if let controller = storyboard.instantiateViewControllerWithIdentifier("UserDetailViewController") as? UserDetailViewController {
            if let creator = inputMessage!.creator {
                controller.entityId = creator.entityId
				controller.profileMode = false
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
	}

	@IBAction func photoAction(sender: AnyObject) {
        let browser = Shared.showPhotoBrowser(self.messagePhoto.imageForState(.Normal), animateFromView: sender as! UIView, viewController: self, entity: self.inputMessage)
        browser.target = self
	}

	@IBAction func reportAction(sender: AnyObject) {
		Alert("Not implemented")
	}
    
	@IBAction func likesAction(sender: AnyObject) {
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        if let controller = storyboard.instantiateViewControllerWithIdentifier("UserTableViewController") as? UserTableViewController {
            controller.message = self.inputMessage
            controller.filter = .MessageLikers
            self.navigationController?.pushViewController(controller, animated: true)
        }
	}

    func shareBrowseAction(sender: AnyObject){
		if let view = sender as? UIView {
			view.backgroundColor = Theme.colorBackgroundWindow
		}
        if self.inputMessage?.message != nil {
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            if let controller = storyboard.instantiateViewControllerWithIdentifier("MessageDetailViewController") as? MessageDetailViewController {
                controller.inputMessageId = self.inputMessage!.message!.entityId
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
        else if self.inputMessage?.patch != nil {
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            if let controller = storyboard.instantiateViewControllerWithIdentifier("PatchDetailViewController") as? PatchDetailViewController {
                controller.entityId = self.inputMessage!.patch!.entityId
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
	func shareAction() {
        
        if self.inputMessage != nil {
            let sheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: nil)
            
            shareButtonFunctionMap[sheet.addButtonWithTitle("Share using Patchr")] = .Share
            shareButtonFunctionMap[sheet.addButtonWithTitle("More")] = .ShareVia
            sheet.addButtonWithTitle("Cancel")
            sheet.cancelButtonIndex = sheet.numberOfButtons - 1
            
            sheet.showInView(self.view)
        }
	}
    
	func editAction() {
        /* Has its own nav because we segue modally and it needs its own stack */
		let controller = MessageEditViewController()
		let navController = UINavigationController()
		controller.inputEntity = self.inputMessage
		controller.inputState = .Editing
		navController.viewControllers = [controller]
		self.navigationController?.presentViewController(navController, animated: true, completion: nil)
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
		
		Log.d("MessageDetail.draw called: \(self.inputMessage!.id_!)")
        
        if self.isShare {
			
            self.recipientsCell.hidden = false
            self.shareHolderCell.hidden = false
			
			self.recipients.textColor = Theme.colorTextTitle
			
            /* Share entity */
			
			let holderView = UIView()
			holderView.clipsToBounds = true
			holderView.borderColor = Theme.colorButtonBorder
			holderView.borderWidth = 1
			holderView.cornerRadius = 6
			
			if self.shareHolderCell.contentView.subviews.count == 0 {
				if self.inputMessage?.message != nil {
					
					var cellType: CellType = .TextAndPhoto
					if self.inputMessage!.message!.photo == nil {
						cellType = .Text
					}
					else if self.inputMessage!.message!.description_ == nil {
						cellType = .Photo
					}
					
					let shareView = MessageView(cellType: cellType)
					
					shareView.bindToEntity(self.inputMessage!.message!)
					
					holderView.addSubview(shareView)
					self.shareHolderCell.contentView.addSubview(holderView)
					self.shareHolderCell.contentView.frame.size.width = self.tableView.frame.size.width
					
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
				else if self.inputMessage?.patch != nil {
					
					let shareView = PatchView()
					
					shareView.borderColor = Theme.colorButtonBorder
					shareView.borderWidth = 1
					shareView.cornerRadius = 6
					shareView.shadow.hidden = true
					
					shareView.bindToEntity(self.inputMessage!.patch!, location: nil)
					
					self.shareHolderCell.contentView.addSubview(shareView)
					self.shareHolderCell.contentView.frame.size.height = 128
					self.shareHolderCell.contentView.frame.size.width = self.tableView.frame.size.width
					shareView.fillSuperviewWithLeftPadding(12, rightPadding: 12, topPadding: 0, bottomPadding: 0)
					
					let tap = UITapGestureRecognizer(target: self, action: "shareBrowseAction:");
					shareView.addGestureRecognizer(tap)
				}
				else {
					/*
					 * The target of the share message has been deleted'
					 */
					let shareView = AirLabel()
					shareView.text = "Deleted"
					shareView.textAlignment = .Center
					shareView.textColor = Colors.white
					
					holderView.borderColor = Theme.colorBackgroundWindow
					holderView.backgroundColor = Theme.colorBackgroundWindow
					holderView.addSubview(shareView)
					self.shareHolderCell.contentView.addSubview(holderView)
					
					self.shareHolderCell.contentView.frame.size.height = 144
					self.shareHolderCell.contentView.frame.size.width = self.tableView.frame.size.width
					
					holderView.fillSuperviewWithLeftPadding(12, rightPadding: 12, topPadding: 0, bottomPadding: 0)
					shareView.fillSuperviewWithLeftPadding(12, rightPadding: 12, topPadding: 12, bottomPadding: 12)
				}

				self.recipients.text = ""
				if self.inputMessage?.recipients != nil {
					for recipient in self.inputMessage!.recipients as! Set<Shortcut> {
						self.recipients.text!.appendContentsOf("\(recipient.name), ")
					}
					self.recipients.text = String(self.recipients.text!.characters.dropLast(2))
				}
			}
        }
        else {
            self.toolbarCell.hidden = false
            
            /* Patch */
            if self.inputMessage!.patch != nil {
                self.patchCell.hidden = false
                self.patchPhoto.setImageWithPhoto(self.inputMessage!.patch.getPhotoManaged())
                self.patchName.setTitle(self.inputMessage!.patch.name, forState: .Normal)
            }
        }

		/* Message */

		self.createdDate.text = Utils.messageDateFormatter.stringFromDate(self.inputMessage!.createdDate)
		if self.inputMessage!.description_ != nil {
			self.description_.text = self.inputMessage!.description_
			self.description_.sizeToFit()
			self.description_.hidden = false
		}
        
        /* Photo */

		if inputMessage!.photo != nil {
			self.messagePhoto.hidden = false
            if !self.messagePhoto.linkedToPhoto(self.inputMessage!.photo) {
                self.messagePhoto.setImageWithPhoto(self.inputMessage!.photo)
            }
		}
		else {
			self.messagePhoto.hidden = true
			self.messagePhoto.frame.size.height = 0
			self.messagePhoto.sizeToFit()
		}

		/* Like button */
        
        likeButton.bindEntity(self.inputMessage)

		/* Likes button */

		if inputMessage?.countLikesValue == 0 {
			if likesButton.alpha != 0 {
				likesButton.fadeOut()
			}
		}
		else {
			let likesTitle = self.inputMessage!.countLikesValue == 1
					? "\(self.inputMessage!.countLikes) like"
					: "\(self.inputMessage!.countLikes ?? 0) likes"
			self.likesButton.setTitle(likesTitle, forState: UIControlState.Normal)
			if likesButton.alpha == 0 {
				likesButton.fadeIn()
			}
		}

		/* User */

		if let creator = self.inputMessage!.creator {
			self.userName.setTitle(creator.name, forState: .Normal)
			self.userPhoto.setImageWithPhoto(creator.getPhotoManaged())
		}
		else {
			self.userName.setTitle("Deleted", forState: .Normal)
            self.userPhoto.setImageWithPhoto(Entity.getDefaultPhoto("user", id: nil))
		}

		self.tableView.reloadData()
	}

	func drawNavButtons(animated: Bool = false) {
		
		let shareButton  = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: Selector("shareAction"))
		let editButton   = UIBarButtonItem(image: Utils.imageEdit, style: UIBarButtonItemStyle.Plain, target: self, action: Selector("editAction"))
		let deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: Selector("deleteAction"))
		let removeButton   = UIBarButtonItem(image: Utils.imageRemove, style: UIBarButtonItemStyle.Plain, target: self, action: Selector("removeAction"))
		
		if self.isShare && self.isOwner {
			self.navigationItem.setRightBarButtonItems([deleteButton], animated: animated)
		}
		else if isOwner {
			self.navigationItem.setRightBarButtonItems([shareButton, Utils.spacer, deleteButton, Utils.spacer, editButton], animated: animated)
		}
		else if isPatchOwner { // Current user is the owner of the patch this message is linked to or sharing
			self.navigationItem.setRightBarButtonItems([shareButton, Utils.spacer, removeButton], animated: animated)
		}
		else {
			self.navigationItem.setRightBarButtonItems([shareButton], animated: animated)
		}
	}
	
    func delete() {
        
        let entityPath = "data/messages/\((self.inputMessage?.id_)!)"
        DataController.proxibase.deleteObject(entityPath) {
            response, error in
			
			NSOperationQueue.mainQueue().addOperationWithBlock {
				if let error = ServerError(error) {
					self.handleError(error)
				}
				else {
					DataController.instance.mainContext.deleteObject(self.inputMessage!)
					DataController.instance.saveContext(false)
					self.navigationController?.popViewControllerAnimated(true)
				}
			}
        }
    }
    
    func remove() {
                
        if let fromId = self.inputMessage!.id_, toId = self.inputMessage!.patchId {
            DataController.proxibase.deleteLink(fromId, toId: toId, linkType: LinkType.Content) {
                response, error in
                
				NSOperationQueue.mainQueue().addOperationWithBlock {
					if let error = ServerError(error) {
						UIViewController.topMostViewController()!.handleError(error)
					}
					else {
						DataController.instance.mainContext.deleteObject(self.inputMessage!)
						DataController.instance.saveContext(false)
						self.navigationController?.popViewControllerAnimated(true)
					}
				}
            }
        }
    }

    func shareUsing(patchr: Bool = true) {
        
        if patchr {
			let controller = MessageEditViewController()
			let navController = UINavigationController()
			controller.inputShareEntity = self.inputMessage
			controller.inputShareSchema = Schema.ENTITY_MESSAGE
			controller.inputShareId = self.inputMessageId!
			controller.inputMessageType = .Share
			controller.inputState = .Sharing
			navController.viewControllers = [controller]
			self.presentViewController(navController, animated: true, completion: nil)
        }
        else {
            Branch.getInstance().getShortURLWithParams(["entityId":self.inputMessageId!, "entitySchema":"message"], andChannel: "patchr-ios", andFeature: BRANCH_FEATURE_TAG_SHARE, andCallback: {
                (url: String?, error: NSError?) -> Void in
                
                if let error = ServerError(error) {
                    UIViewController.topMostViewController()!.handleError(error)
                }
                else {
                    Log.d("Branch link created: \(url!)")
                    let message: MessageItem = MessageItem(entity: self.inputMessage!, shareUrl: url!)
					
					let activityViewController = UIActivityViewController(
						activityItems: [message],
						applicationActivities: nil)
					
					if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
						self.presentViewController(activityViewController, animated: true, completion: nil)
					}
					else {
						let popup: UIPopoverController = UIPopoverController(contentViewController: activityViewController)
						popup.presentPopoverFromRect(CGRectMake(self.view.frame.size.width/2, self.view.frame.size.height/4, 0, 0), inView: self.view, permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)
					}
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
        
        if let message = self.inputMessage {
            if indexPath.row == 2 {
                return (message.description_ == nil)
                    ? CGFloat(0)
                    : CGFloat(self.description_.frame.origin.y * 2 + self.description_.frame.size.height)
            }
            else if indexPath.row == 4 {
                
                /* Size so photo aspect ratio is 4:3 */
                var height: CGFloat = 0
				let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.bounds.size.width)
                if message.photo != nil {
                    height = (viewWidth - 24) * 0.75
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
				else if indexPath.row == 7 {	// Recipients
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
