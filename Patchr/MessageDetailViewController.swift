//
//  MessageDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MessageUI
import Branch

class MessageDetailViewController: BaseViewController {

	var inputMessage	: Message?
	var inputMessageId	: String?			// Used by notifications
	
    var deleted			= false

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
	var activity		= UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)

	var patchGroup		= AirRuleView()
	var patchName		= AirLinkButton()
	var patchPhoto		= AirImageButton()
	
	var userGroup		= UIView()
	var userPhoto		= UserPhotoView()
	var userName		= AirLinkButton()
	
	var messageGroup	= UIView()
	var createdDate		= UILabel()
	var description_	: TTTAttributedLabel!
	var photo			= AirImageButton()
	
	var toolbarGroup	= AirRuleView()
	var likeButton		= AirLikeButton()
	var likesButton		= AirLinkButton()
	var reportButton	= AirLinkButton()
	
	var shareGroup		= UIView()
	var shareFrame		= AirButton()
	var recipientsLabel = AirLabelDisplay()
	var recipients		= AirLabelDisplay()
	var messageView		: MessageView?
	var patchView		: PatchView?
	var emptyView		: AirLabelDisplay?

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
		
		self.activity.anchorInCenterWithWidth(24, height: 24)
		
		if let message = self.inputMessage {
			
			self.contentHolder.hidden = false
			self.patchGroup.hidden = true
			self.description_?.hidden = true
			self.photo.hidden = true
			self.toolbarGroup.hidden = true
			self.shareGroup.hidden = true
			
			let viewWidth = min(CONTENT_WIDTH_MAX, self.view.bounds.size.width)
			let contentWidth = CGFloat(viewWidth - 32)
			self.view.bounds.size.width = viewWidth
			self.contentHolder.bounds.size.width = viewWidth
			
			if self.isShare {
				
				self.shareGroup.hidden = false
				
				/*---dup ---*/
				self.userGroup.anchorTopCenterFillingWidthWithLeftAndRightPadding(0, topPadding: 0, height: 64)
				self.userPhoto.anchorCenterLeftWithLeftPadding(16, width: 48, height: 48)
				let nameWidth = self.userGroup.width() - (32 + 48 + 8)
				self.userName.alignToTheRightOf(self.userPhoto, matchingCenterWithLeftPadding: 8, width: nameWidth, height: self.userName.height())
				
				self.messageGroup.alignUnder(self.userGroup, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: 0)
				
				if message.description_ != nil && !message.description_.isEmpty {
					self.description_.hidden = false
					self.description_.bounds.size.width = contentWidth
					self.description_.sizeToFit()
					self.description_.anchorTopLeftWithLeftPadding(16, topPadding: 0, width: self.description_.width(), height: self.description_.height())
					self.createdDate.sizeToFit()
					self.createdDate.alignUnder(self.description_, centeredFillingWidthWithLeftAndRightPadding: 16, topPadding: 16, height: self.createdDate.height())
				}
				else {
					self.createdDate.sizeToFit()
					self.createdDate.anchorTopCenterFillingWidthWithLeftAndRightPadding(16, topPadding: 0, height: self.createdDate.height())
				}
				
				self.messageGroup.resizeToFitSubviews()
				
				/*---dup ---*/
				
				self.shareGroup.alignUnder(self.messageGroup, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: 100)
				
				if message.patch != nil {
					self.shareFrame.anchorTopCenterFillingWidthWithLeftAndRightPadding(16, topPadding: 12, height: 128)
					self.patchView!.anchorTopCenterFillingWidthWithLeftAndRightPadding(0, topPadding: 0, height: 128)
				}
				else if message.message != nil {
					self.shareFrame.anchorTopCenterFillingWidthWithLeftAndRightPadding(16, topPadding: 12, height: self.messageView!.height() + 8)
					self.messageView!.anchorTopCenterFillingWidthWithLeftAndRightPadding(12, topPadding: 8, height: self.messageView!.height())
				}
				else {
					self.shareFrame.anchorTopCenterFillingWidthWithLeftAndRightPadding(16, topPadding: 12, height:128)
					self.emptyView!.fillSuperview()
				}
				
				self.recipientsLabel.sizeToFit()
				self.recipients.bounds.size.width = contentWidth - self.recipientsLabel.width() + 4
				self.recipients.sizeToFit()
				self.recipientsLabel.alignUnder(self.shareFrame, matchingLeftWithTopPadding: 12, width: self.recipientsLabel.width() + 4, height: self.recipientsLabel.height())
				self.recipients.alignToTheRightOf(self.recipientsLabel, matchingTopWithLeftPadding: 8, width: self.recipients.width(), height: self.recipients.height())
				
				self.shareGroup.resizeToFitSubviews()
			}
			else {
				
				self.toolbarGroup.hidden = false
				
				if message.patch != nil {
					self.patchGroup.hidden = false
					self.patchGroup.anchorTopCenterFillingWidthWithLeftAndRightPadding(0, topPadding: 0, height: 48)
					let photoWidth = self.patchGroup.height() * 1.7777
					self.patchPhoto.anchorCenterRightWithRightPadding(0, width: photoWidth, height: self.patchGroup.height())
					let patchNameWidth = viewWidth - photoWidth - 24
					self.patchName.sizeToFit()
					self.patchName.anchorCenterLeftWithLeftPadding(16, width: patchNameWidth, height: self.patchName.height())
					self.userGroup.alignUnder(self.patchGroup, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: 64)
				}
				else {
					self.userGroup.anchorTopCenterFillingWidthWithLeftAndRightPadding(0, topPadding: 0, height: 64)
				}
				
				self.userPhoto.anchorCenterLeftWithLeftPadding(16, width: 48, height: 48)
				let userNameWidth = self.userGroup.width() - (32 + 48 + 8)
				self.userName.sizeToFit()
				self.userName.alignToTheRightOf(self.userPhoto, matchingCenterWithLeftPadding: 8, width: userNameWidth, height: self.userName.height())
				
				self.messageGroup.alignUnder(self.userGroup, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: 600)
				
				if message.description_ != nil && !message.description_.isEmpty {
					self.description_.hidden = false
					self.description_.bounds.size.width = contentWidth
					self.description_.sizeToFit()
					self.description_.anchorTopLeftWithLeftPadding(16, topPadding: 0, width: self.description_.width(), height: self.description_.height())
					self.createdDate.sizeToFit()
					self.createdDate.alignUnder(self.description_, centeredFillingWidthWithLeftAndRightPadding: 16, topPadding: 8, height: self.createdDate.height())
				}
				else {
					self.createdDate.sizeToFit()
					self.createdDate.anchorTopCenterFillingWidthWithLeftAndRightPadding(16, topPadding: 0, height: self.createdDate.height())
				}
				
				if message.photo != nil {
					self.photo.hidden = false
					let photoHeight = contentWidth * 0.75
					self.photo.alignUnder(self.createdDate, matchingLeftAndFillingWidthWithRightPadding: 16, topPadding: 8, height: photoHeight)
				}
				
				self.messageGroup.resizeToFitSubviews()
				
				self.toolbarGroup.alignUnder(self.messageGroup, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 0, height: 48)
				self.likeButton.anchorCenterLeftWithLeftPadding(4, width: self.likeButton.width(), height: self.likeButton.height())
				self.reportButton.sizeToFit()
				self.reportButton.anchorCenterRightWithRightPadding(16, width: self.reportButton.width(), height: self.reportButton.height())
				self.likesButton.sizeToFit()
				self.likesButton.anchorInCenterWithWidth(72, height: self.likesButton.height())
			}
			
			self.contentHolder.resizeToFitSubviews()
			
			let tabBarHeight = self.tabBarController?.tabBar.height() ?? 0
			let contentHeight = max((self.scrollView.height() + self.scrollView.contentOffset.y) - tabBarHeight, self.contentHolder.height())
			self.scrollView.contentSize = CGSizeMake(self.contentHolder.frame.size.width, contentHeight)
			self.contentHolder.anchorTopCenterFillingWidthWithLeftAndRightPadding(0, topPadding: 0, height: contentHeight)
		}
	}
	
	override func viewWillAppear(animated: Bool) {
		/*
		 * Does not fire after showing photo browser.
		 */
		super.viewWillAppear(animated)
		
		guard (self.inputMessage != nil || self.inputMessageId != nil) else {
			fatalError("Message or message id required")
		}
		
		/* Use cached entity if available in the data model */
		if self.inputMessage == nil {
			if let message: Message? = Message.fetchOneById(self.inputMessageId!, inManagedObjectContext: DataController.instance.mainContext) {
				self.inputMessage = message
			}
		}
		else {
			/* Entity could have been delete while we were away to check it. */
			let item = ServiceBase.fetchOneById(self.inputMessage!.id_, inManagedObjectContext: DataController.instance.mainContext)
			if item == nil {
				self.navigationController?.popViewControllerAnimated(false)
				return
			}
		}
		
		if self.inputMessage != nil {
			bind()
			self.view.setNeedsLayout()
		}
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "likeDidChange:", name: Events.LikeDidChange, object: nil)
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		fetch()
	}
	
    override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)
		self.activity.stopAnimating()
		NSNotificationCenter.defaultCenter().removeObserver(self, name: Events.LikeDidChange, object: nil)
    }
	
	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/
	
	func patchAction(sender: AnyObject) {
		let controller = PatchDetailViewController()
		controller.entityId = self.inputMessage!.patch.entityId
		self.navigationController?.pushViewController(controller, animated: true)
	}

	func userAction(sender: AnyObject) {
		let controller = UserDetailViewController()
		if let creator = inputMessage!.creator {
			controller.entityId = creator.entityId
			controller.profileMode = false
			self.navigationController?.pushViewController(controller, animated: true)
		}
	}

	func photoAction(sender: AnyObject) {
        let browser = UIShared.showPhotoBrowser(self.photo.imageForState(.Normal), animateFromView: sender as! UIView, viewController: self, entity: self.inputMessage)
        browser.target = self
	}

	func reportAction(sender: AnyObject) {
		
		let email = "report@3meters.com"
		let subject = "Report on Patchr content"
		let body = "Report on message id: \(self.inputMessage!.id_)\n\nPlease add some detail on why you are reporting this message.\n"
		
		if MFMailComposeViewController.canSendMail() {
			MailComposer!.view.accessibilityIdentifier = View.Report
			MailComposer!.mailComposeDelegate = self
			MailComposer!.setToRecipients([email])
			MailComposer!.setSubject(subject)
			MailComposer!.setMessageBody(body, isHTML: false)
			
			self.presentViewController(MailComposer!, animated: true, completion: nil)
		}
		else {
			let queryURL = "subject=\(subject)&body=\(body)"
			let emailURL = "mailto:\(email)?\(queryURL.stringByAddingPercentEncodingWithAllowedCharacters(NSMutableCharacterSet.URLQueryAllowedCharacterSet()) ?? queryURL)"
			if let url = NSURL(string: emailURL) {
				UIApplication.sharedApplication().openURL(url)
			}
		}
	}
	
	func likesAction(sender: AnyObject) {
		let controller = UserTableViewController()
		controller.message = self.inputMessage
		controller.filter = .MessageLikers
		self.navigationController?.pushViewController(controller, animated: true)
	}

    func shareBrowseAction(sender: AnyObject){
		if let button = sender as? AirButton {
			button.borderColor = Theme.colorButtonBorder
		}
        if self.inputMessage?.message != nil {
			let controller = MessageDetailViewController()
			controller.inputMessageId = self.inputMessage!.message!.entityId
			self.navigationController?.pushViewController(controller, animated: true)
        }
        else if self.inputMessage?.patch != nil {
			let controller = PatchDetailViewController()
            controller.entityId = self.inputMessage!.patch!.entityId
            self.navigationController?.pushViewController(controller, animated: true)
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
        self.DeleteConfirmationAlert(
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
        self.DeleteConfirmationAlert(
            "Confirm Remove",
            message: "Are you sure you want to remove this message from the patch?",
            actionTitle: "Remove", cancelTitle: "Cancel", delegate: self) {
                doIt in
                if doIt {
                    self.remove()
                }
        }
    }
	
	func buttonTouchDownAction(sender: AnyObject) {
		if let button = sender as? AirButton {
			button.borderColor = Colors.brandColor
		}
	}
    
    func dismissAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func likeDidChange(notification: NSNotification) {
		if let userInfo = notification.userInfo,
			let entityId = userInfo["entityId"] as? String {
				if let message = self.inputMessage where message.id_ != nil && entityId == message.id_ {
					self.bind()
				}
		}
    }

	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
		setScreenName("MessageDetail")
		self.view.accessibilityIdentifier = View.MessageDetail
		
		//self.contentHolder.hidden = true
		self.contentHolder.backgroundColor = Theme.colorBackgroundForm
		
		/* Ui tweaks */
		self.view.window?.backgroundColor = Theme.colorBackgroundWindow
		self.activity.tintColor = Theme.colorActivityIndicator
		self.activity.accessibilityIdentifier = "activity_view"
		
		self.patchGroup.ruleBottom.backgroundColor = Colors.gray90pcntColor
		self.patchPhoto.imageView?.contentMode = UIViewContentMode.ScaleAspectFill
		
		self.userName.titleLabel!.font = Theme.fontHeading
		self.userName.contentHorizontalAlignment = .Left
		
		self.patchName.titleLabel?.font = Theme.fontTextDisplay
		self.patchName.contentHorizontalAlignment = .Left
		self.patchName.contentVerticalAlignment = .Center
		
		self.createdDate.textColor = Theme.colorTextSecondary
		self.shareFrame.clipsToBounds = true
		
		self.photo.imageView?.contentMode = UIViewContentMode.ScaleAspectFill
		self.photo.contentMode = .ScaleAspectFill
		self.photo.contentVerticalAlignment = .Fill
		self.photo.contentHorizontalAlignment = .Fill
		self.photo.sizeCategory = SizeCategory.standard
		
		self.toolbarGroup.ruleBottom.backgroundColor = Colors.gray90pcntColor
		
		self.likesButton.imageView?.tintColor = Theme.colorTint
		self.likeButton.bounds.size = CGSizeMake(48, 48)
		self.likeButton.imageEdgeInsets = UIEdgeInsetsMake(14, 12, 14, 12)
		
		self.reportButton.setTitle("Report", forState: .Normal)
		self.reportButton.addTarget(self, action: Selector("reportAction:"), forControlEvents: UIControlEvents.TouchUpInside)
		self.likesButton.addTarget(self, action: Selector("likesAction:"), forControlEvents: UIControlEvents.TouchUpInside)
		self.userName.addTarget(self, action: Selector("userAction:"), forControlEvents: UIControlEvents.TouchUpInside)
		self.patchName.addTarget(self, action: Selector("patchAction:"), forControlEvents: UIControlEvents.TouchUpInside)
		self.patchPhoto.addTarget(self, action: Selector("patchAction:"), forControlEvents: UIControlEvents.TouchUpInside)
		self.photo.addTarget(self, action: Selector("photoAction:"), forControlEvents: UIControlEvents.TouchUpInside)
		
		self.recipients.textColor = Theme.colorTextTitle
		self.recipientsLabel.text = "To:"
		self.recipientsLabel.textColor = Theme.colorTextSecondary
		
		self.view.addSubview(self.activity)
		
		self.patchGroup.addSubview(self.patchName)
		self.patchGroup.addSubview(self.patchPhoto)
		
		self.userGroup.addSubview(self.userPhoto)
		self.userGroup.addSubview(self.userName)
		
		self.messageGroup.addSubview(self.createdDate)
		self.messageGroup.addSubview(self.photo)
		
		self.toolbarGroup.addSubview(self.likeButton)
		self.toolbarGroup.addSubview(self.likesButton)
		self.toolbarGroup.addSubview(self.reportButton)
		
		self.shareGroup.addSubview(self.shareFrame)
		self.shareGroup.addSubview(self.recipientsLabel)
		self.shareGroup.addSubview(self.recipients)
		
		self.contentHolder.addSubview(self.patchGroup)
		self.contentHolder.addSubview(self.userGroup)
		self.contentHolder.addSubview(self.messageGroup)
		self.contentHolder.addSubview(self.toolbarGroup)
		self.contentHolder.addSubview(self.shareGroup)
	}
	
	func bind() {
		
        if self.isShare {
			
			if self.inputMessage!.message != nil {
				
				var cellType: CellType = .TextAndPhoto
				if self.inputMessage!.message!.photo == nil {
					cellType = .Text
				}
				else if self.inputMessage!.message!.description_ == nil {
					cellType = .Photo
				}
				
				self.messageView = MessageView(cellType: cellType, entity: self.inputMessage!.message!)
				
				/* Resize once here because sizing in viewWillLayoutSubviews causes recursion */
				let viewWidth = min(CONTENT_WIDTH_MAX, self.view.bounds.size.width)
				let contentWidth = CGFloat(viewWidth - 32)
				self.messageView!.bounds.size.width = contentWidth - 24
				self.messageView!.sizeToFit()
				self.messageView?.clipsToBounds = false
				self.shareFrame.addSubview(self.messageView!)
				self.shareFrame.addTarget(self, action: Selector("shareBrowseAction:"), forControlEvents: UIControlEvents.TouchUpInside)
				self.shareFrame.addTarget(self, action: Selector("buttonTouchDownAction:"), forControlEvents: UIControlEvents.TouchDown)
				UIView.disableAllSubviewsOf(self.shareFrame)
			}
			else if self.inputMessage!.patch != nil {
				
				self.patchView = PatchView(frame: CGRectMake(0, 0, self.view.width(), 136))
				self.patchView!.bindToEntity(self.inputMessage!.patch!, location: nil)
				self.patchView!.shadow.hidden = true
				self.shareFrame.addSubview(self.patchView!)
				self.shareFrame.addTarget(self, action: Selector("shareBrowseAction:"), forControlEvents: UIControlEvents.TouchUpInside)
				self.shareFrame.addTarget(self, action: Selector("buttonTouchDownAction:"), forControlEvents: UIControlEvents.TouchDown)
				UIView.disableAllSubviewsOf(self.shareFrame)
			}
			else {
				/*
				 * The target of the share message has been deleted'
				 */
				self.emptyView = AirLabelDisplay()
				self.emptyView!.text = "Deleted"
				self.emptyView!.textAlignment = .Center
				self.emptyView!.textColor = Colors.white
				self.shareFrame.borderColor = Theme.colorBackgroundWindow
				self.shareFrame.backgroundColor = Theme.colorBackgroundWindow
				self.shareFrame.addSubview(self.emptyView!)
			}

			self.recipients.text = ""
			if self.inputMessage?.recipients != nil {
				for recipient in self.inputMessage!.recipients as! Set<Shortcut> {
					self.recipients.text!.appendContentsOf("\(recipient.name), ")
				}
				self.recipients.text = String(self.recipients.text!.characters.dropLast(2))
			}
        }
        else {
			
            /* Patch */
            if self.inputMessage!.patch != nil {
                self.patchPhoto.setImageWithPhoto(self.inputMessage!.patch.getPhotoManaged())
                self.patchName.setTitle(self.inputMessage!.patch.name, forState: .Normal)
            }
        }

		/* Message */

		self.createdDate.text = Utils.messageDateFormatter.stringFromDate(self.inputMessage!.createdDate)
		
		if self.inputMessage!.description_ != nil {
			if self.description_ == nil {
				self.description_ = TTTAttributedLabel(frame: CGRectZero)
				self.description_.numberOfLines = 0
				self.description_.font = Theme.fontTextDisplay
				self.description_.linkAttributes = [kCTForegroundColorAttributeName : Theme.colorTint]
				self.description_.activeLinkAttributes = [kCTForegroundColorAttributeName : Theme.colorTint]
				self.description_.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
				self.description_.delegate = self
				self.messageGroup.addSubview(self.description_)
			}
			self.description_.text = self.inputMessage!.description_
			self.description_.sizeToFit()
		}
        
        /* Photo */

		if inputMessage!.photo != nil {
            if !self.photo.linkedToPhoto(self.inputMessage!.photo) {
                self.photo.setImageWithPhoto(self.inputMessage!.photo)
            }
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

		self.userPhoto.bindToEntity(self.inputMessage!.creator)
		self.userName.setTitle(self.inputMessage?.creator.name ?? "Deleted", forState: .Normal)
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
	
	func fetch() {
		
		if (self.inputMessage == nil) {
			self.activity.startAnimating()
		}
		
		DataController.instance.backgroundOperationQueue.addOperationWithBlock {
			/*
			 * A linked message that comes with a share message is only partially
			 * complete so we need to force a full fetch of the message from the service
			 * by turning off the date checks (criteria).
			 */
			let fetchStrategy: FetchStrategy = (self.inputMessage != nil
				&& self.inputMessage!.type != nil
				&& self.inputMessage!.type == "share"
				&& (self.inputMessage!.message == nil && self.inputMessage!.patch == nil)
				&& !self.inputMessage!.decoratedValue) ? .IgnoreCache : .UseCacheAndVerify
			
			let messageId = (self.inputMessage?.id_ ?? self.inputMessageId!)!
			
			DataController.instance.withEntityId(messageId, strategy: fetchStrategy) {
				[weak self] objectId, error in
				
				if self != nil {
					NSOperationQueue.mainQueue().addOperationWithBlock {
						self?.activity.stopAnimating()
						if error == nil {
							if objectId == nil {
								UIShared.Toast("Message has been deleted")
								Utils.delay(2.0) {
									self?.navigationController?.popViewControllerAnimated(true)
								}
							}
							else {
								self?.inputMessage = DataController.instance.mainContext.objectWithID(objectId!) as? Message
								self?.drawNavButtons(false)
								self?.bind()	// TODO: Can skip if no change in activityDate and modifiedDate
								/* Need this because if a message has be be fetched, we haven't done layout yet. */
								self?.view.setNeedsLayout()
							}
						}
					}
				}
			}
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
					DataController.instance.saveContext(BLOCKING)
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
						DataController.instance.saveContext(BLOCKING)
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
			controller.inputShareId = self.inputMessage?.id_ ?? self.inputMessageId!
			controller.inputMessageType = .Share
			controller.inputState = .Sharing
			navController.viewControllers = [controller]
			self.presentViewController(navController, animated: true, completion: nil)
        }
        else {
			
			let inviterName = UserController.instance.currentUser.name!
			
			var parameters = [
				"entityId":self.inputMessage!.id_!,
				"entitySchema":"message",
				"inviterName":inviterName,
			]
			
			if self.inputMessage!.photo != nil {
				let photo = self.inputMessage!.getPhotoManaged()
				let settings = "h=250&crop&fit=crop&q=50"
				let photoUrl = "https://3meters-images.imgix.net/\(photo.prefix)?\(settings)"
				parameters["$og_image_url"] = photoUrl
			}
			else if self.inputMessage!.patch != nil {
				let photo = self.inputMessage!.patch.getPhotoManaged()
				let settings = "h=250&crop&fit=crop&q=50"
				let photoUrl = "https://3meters-images.imgix.net/\(photo.prefix)?\(settings)"
				parameters["$og_image_url"] = photoUrl
			}
			
			var description = "\(self.inputMessage!.creator.name!) posted a photo to the \(self.inputMessage!.patch!.name) patch using Patchr"
			if self.inputMessage!.description_ != nil && !self.inputMessage!.description_.isEmpty {
				description = "\(self.inputMessage!.creator.name!) posted: \"\(self.inputMessage!.description_)\""
			}
			
			parameters["$og_title"] = "Shared by \(inviterName)"
			parameters["$og_description"] = description
			
            Branch.getInstance().getShortURLWithParams(parameters,
				andChannel: "patchr-ios",
				andFeature: BRANCH_FEATURE_TAG_SHARE,
				andCallback: { url, error in
                
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

extension MessageDetailViewController: MFMailComposeViewControllerDelegate {
	
	func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
		
		switch result.rawValue {
			case MFMailComposeResultCancelled.rawValue:	// 0
				UIShared.Toast("Report cancelled", controller: self, addToWindow: false)
			case MFMailComposeResultSaved.rawValue:		// 1
				UIShared.Toast("Report saved", controller: self, addToWindow: false)
			case MFMailComposeResultSent.rawValue:		// 2
				UIShared.Toast("Report sent", controller: self, addToWindow: false)
			case MFMailComposeResultFailed.rawValue:	// 3
				UIShared.Toast("Report send failure: \(error!.localizedDescription)", controller: self, addToWindow: false)
			default:
				break
		}
		
		self.dismissViewControllerAnimated(true) {
			MailComposer = nil
			MailComposer = MFMailComposeViewController()
		}
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
        let text = "Check out \(self.entity.creator.name)'s message posted to the \(self.entity.patch.name) patch! \(self.shareUrl) \n"
        return text
    }
    
    func activityViewController(activityViewController: UIActivityViewController, subjectForActivityType activityType: String?) -> String {
		if activityType == UIActivityTypeMail
			|| activityType == UIActivityTypeOutlook
			|| activityType == UIActivityTypeGmail {
            return "Patch message posted by \(self.entity.creator.name)"
        }
        return ""
    }
}

private enum ShareButtonFunction {
    case Share
    case ShareVia
}
