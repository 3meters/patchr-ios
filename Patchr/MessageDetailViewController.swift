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

	var inputMessage			: Message?
	var inputMessageId			: String?			// Used by notifications
	var inputReferrerName		: String?
	var inputReferrerPhotoUrl	: String?
	var shareActive				= false
    var deleted					= false

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
	var activity		= UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)

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
		
		self.activity.anchorInCenter(withWidth: 24, height: 24)
		
		if let message = self.inputMessage {
			
			self.contentHolder.isHidden = false
			self.patchGroup.isHidden = true
			self.description_?.isHidden = true
			self.photo.isHidden = true
			self.toolbarGroup.isHidden = true
			self.shareGroup.isHidden = true
			
			let viewWidth = min(CONTENT_WIDTH_MAX, self.view.bounds.size.width)
			let contentWidth = CGFloat(viewWidth - 32)
			
			self.view.bounds.size.width = viewWidth
			self.contentHolder.bounds.size.width = viewWidth
			self.scrollView.anchorTopCenter(withTopPadding: 0, width: viewWidth, height: self.view.bounds.height)
			
			if self.isShare {
				
				self.shareGroup.isHidden = false
				
				/*---dup ---*/
				self.userGroup.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 64)
				self.userPhoto.anchorCenterLeft(withLeftPadding: 16, width: 48, height: 48)
				let nameWidth = self.userGroup.width() - (32 + 48 + 8)
				self.userName.align(toTheRightOf: self.userPhoto, matchingCenterWithLeftPadding: 8, width: nameWidth, height: self.userName.height())
				
				self.messageGroup.alignUnder(self.userGroup, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: 0)
				
				if message.description_ != nil && !message.description_.isEmpty {
					self.description_.isHidden = false
					self.description_.bounds.size.width = contentWidth
					self.description_.sizeToFit()
					self.description_.anchorTopLeft(withLeftPadding: 16, topPadding: 0, width: self.description_.width(), height: self.description_.height())
					self.createdDate.sizeToFit()
					self.createdDate.alignUnder(self.description_, centeredFillingWidthWithLeftAndRightPadding: 16, topPadding: 16, height: self.createdDate.height())
				}
				else {
					self.createdDate.sizeToFit()
					self.createdDate.anchorTopCenterFillingWidth(withLeftAndRightPadding: 16, topPadding: 0, height: self.createdDate.height())
				}
				
				self.messageGroup.resizeToFitSubviews()
				
				/*---dup ---*/
				
				self.shareGroup.alignUnder(self.messageGroup, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: 100)
				
				if message.patch != nil {
					self.shareFrame.anchorTopCenterFillingWidth(withLeftAndRightPadding: 16, topPadding: 12, height: 128)
					self.patchView!.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 128)
				}
				else if message.message != nil {
					self.shareFrame.anchorTopCenterFillingWidth(withLeftAndRightPadding: 16, topPadding: 12, height: self.messageView!.height() + 8)
					self.messageView!.anchorTopCenterFillingWidth(withLeftAndRightPadding: 12, topPadding: 8, height: self.messageView!.height())
				}
				else {
					self.shareFrame.anchorTopCenterFillingWidth(withLeftAndRightPadding: 16, topPadding: 12, height:128)
					self.emptyView!.fillSuperview()
				}
				
				self.recipientsLabel.sizeToFit()
				self.recipients.bounds.size.width = contentWidth - self.recipientsLabel.width() + 4
				self.recipients.sizeToFit()
				self.recipientsLabel.alignUnder(self.shareFrame, matchingLeftWithTopPadding: 12, width: self.recipientsLabel.width() + 4, height: self.recipientsLabel.height())
				self.recipients.align(toTheRightOf: self.recipientsLabel, matchingTopWithLeftPadding: 8, width: self.recipients.width(), height: self.recipients.height())
				
				self.shareGroup.resizeToFitSubviews()
			}
			else {
				
				self.toolbarGroup.isHidden = false
				
				if message.patch != nil {
					self.patchGroup.isHidden = false
					self.patchGroup.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 48)
					let photoWidth = self.patchGroup.height() * 1.7777
					self.patchPhoto.anchorCenterRight(withRightPadding: 0, width: photoWidth, height: self.patchGroup.height())
					let patchNameWidth = viewWidth - photoWidth - 24
					self.patchName.sizeToFit()
					self.patchName.anchorCenterLeft(withLeftPadding: 16, width: patchNameWidth, height: self.patchName.height())
					self.userGroup.alignUnder(self.patchGroup, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: 64)
				}
				else {
					self.userGroup.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 64)
				}
				
				self.userPhoto.anchorCenterLeft(withLeftPadding: 16, width: 48, height: 48)
				let userNameWidth = self.userGroup.width() - (32 + 48 + 8)
				self.userName.sizeToFit()
				self.userName.align(toTheRightOf: self.userPhoto, matchingCenterWithLeftPadding: 8, width: userNameWidth, height: self.userName.height())
				
				self.messageGroup.alignUnder(self.userGroup, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: 600)
				
				if message.description_ != nil && !message.description_.isEmpty {
					self.description_.isHidden = false
					self.description_.bounds.size.width = contentWidth
					self.description_.sizeToFit()
					self.description_.anchorTopLeft(withLeftPadding: 16, topPadding: 0, width: self.description_.width(), height: self.description_.height())
					self.createdDate.sizeToFit()
					self.createdDate.alignUnder(self.description_, centeredFillingWidthWithLeftAndRightPadding: 16, topPadding: 8, height: self.createdDate.height())
				}
				else {
					self.createdDate.sizeToFit()
					self.createdDate.anchorTopCenterFillingWidth(withLeftAndRightPadding: 16, topPadding: 0, height: self.createdDate.height())
				}
				
				if message.photo != nil {
					self.photo.isHidden = false
					let photoHeight = contentWidth * 0.75
					self.photo.alignUnder(self.createdDate, matchingLeftAndFillingWidthWithRightPadding: 16, topPadding: 8, height: photoHeight)
				}
				
				self.messageGroup.resizeToFitSubviews()
				
				self.toolbarGroup.alignUnder(self.messageGroup, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 0, height: 48)
				self.likeButton.anchorCenterLeft(withLeftPadding: 4, width: self.likeButton.width(), height: self.likeButton.height())
				self.reportButton.sizeToFit()
				self.reportButton.anchorCenterRight(withRightPadding: 16, width: self.reportButton.width(), height: self.reportButton.height())
				self.likesButton.sizeToFit()
				self.likesButton.anchorInCenter(withWidth: 72, height: self.likesButton.height())
			}
			
			self.contentHolder.resizeToFitSubviews()
			
			let tabBarHeight = self.tabBarController?.tabBar.height() ?? 0
			let contentHeight = max((self.scrollView.height() + self.scrollView.contentOffset.y) - tabBarHeight, self.contentHolder.height())
            self.scrollView.contentSize = CGSize(width:self.contentHolder.frame.size.width, height:contentHeight)
			self.contentHolder.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: contentHeight)
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		/*
		 * Does not fire after showing photo browser.
		 */
		super.viewWillAppear(animated)
		
		guard (self.inputMessage != nil || self.inputMessageId != nil) else {
			fatalError("Message or message id required")
		}
		
		/* Use cached entity if available in the data model */
		if self.inputMessage == nil {
			if let message: Message? = Message.fetchOne(byId: self.inputMessageId!, in: DataController.instance.mainContext) {
				self.inputMessage = message
			}
		}
		else {
			/* Entity could have been delete while we were away to check it. */
			let item = ServiceBase.fetchOne(byId: self.inputMessage!.id_, in: DataController.instance.mainContext)
			if item == nil {
				let _ = self.navigationController?.popViewController(animated: false)
				return
			}
		}
		
		if self.inputMessage != nil {
			bind()
			self.view.setNeedsLayout()
		}
		else {
			self.scrollView.isHidden = true
		}
		
		NotificationCenter.default.addObserver(self, selector: #selector(MessageDetailViewController.likeDidChange(notification:)), name: NSNotification.Name(rawValue: Events.LikeDidChange), object: nil)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		fetch()
	}
	
    override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		self.activity.stopAnimating()
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Events.LikeDidChange), object: nil)
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
        UIShared.showPhoto(image: self.photo.image(for: .normal), animateFromView: sender as! UIView, viewController: self, entity: self.inputMessage)
	}

	func reportAction(sender: AnyObject) {
		
		let email = "report@patchr.com"
		let subject = "Report on Patchr content"
		let body = "Report on message id: \(self.inputMessage!.id_)\n\nPlease add some detail on why you are reporting this message.\n"
		
		if MFMailComposeViewController.canSendMail() {
			MailComposer!.mailComposeDelegate = self
			MailComposer!.setToRecipients([email])
			MailComposer!.setSubject(subject)
			MailComposer!.setMessageBody(body, isHTML: false)
			
			self.present(MailComposer!, animated: true, completion: nil)
		}
		else {
			let queryURL = "subject=\(subject)&body=\(body)"
			let emailURL = "mailto:\(email)?\(queryURL.addingPercentEncoding(withAllowedCharacters: NSMutableCharacterSet.urlQueryAllowed) ?? queryURL)"
			if let url = NSURL(string: emailURL) {
				UIApplication.shared.openURL(url as URL)
			}
		}
	}
	
	func likesAction(sender: AnyObject?) {
		let controller = UserTableViewController()
		controller.message = self.inputMessage
		controller.filter = .MessageLikers
		self.navigationController?.pushViewController(controller, animated: true)
	}
	
	func likeAction(sender: AnyObject) {
		likeButton.onClick(sender: self)
	}
	
    func shareBrowseAction(sender: AnyObject){
		if let button = sender as? AirButton {
			button.borderColor = Colors.brandColor
			self.patchView?.name.textColor = Colors.brandColor
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
    
	func shareAction(sender: AnyObject?) {
		
        if self.inputMessage != nil {
			
			let sheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
			
			let patchr = UIAlertAction(title: "Share using Patchr", style: .default) { action in
				self.shareUsing(route: .Patchr)
			}
			let android = UIAlertAction(title: "More...", style: .default) { action in
				self.shareUsing(route: .Actions)
			}
			let cancel = UIAlertAction(title: "Cancel", style: .cancel) { action in
				sheet.dismiss(animated: true, completion: nil)
			}
			
			sheet.addAction(patchr)
			sheet.addAction(android)
			sheet.addAction(cancel)
			
			if let presenter = sheet.popoverPresentationController {
				if let button = sender as? UIBarButtonItem {
					presenter.barButtonItem = button
				}
				else if let button = sender as? UIView {
					presenter.sourceView = button;
					presenter.sourceRect = button.bounds;
				}
			}
			
			present(sheet, animated: true, completion: nil)
        }
	}
    
	func editAction() {
        /* Has its own nav because we segue modally and it needs its own stack */
		let controller = MessageEditViewController()
		let navController = AirNavigationController()
		controller.inputEntity = self.inputMessage
		controller.inputState = .Editing
		navController.viewControllers = [controller]
		self.navigationController?.present(navController, animated: true, completion: nil)
	}
    
    func deleteAction() {
        self.DeleteConfirmationAlert(
            title: "Confirm Delete",
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
            title: "Confirm Remove",
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
			button.borderColor = Theme.colorButtonBorder
			self.patchView?.name.textColor = Theme.colorButtonBorder
		}
	}
    
    func dismissAction(sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }

	/*--------------------------------------------------------------------------------------------
	* Notifications
	*--------------------------------------------------------------------------------------------*/

    func likeDidChange(notification: NSNotification) {
		if let userInfo = notification.userInfo,
			let entityId = userInfo["entityId"] as? String {
				if let message = self.inputMessage , message.id_ != nil && entityId == message.id_ {
					self.bind()
				}
		}
    }
	
	func applicationDidEnterBackground(sender: NSNotification) {
		if self.inputReferrerName != nil {
			self.dismiss(animated: true, completion: nil)
		}
	}

	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
		Reporting.screen("MessageDetail")
		
		/* Ui tweaks */
		self.activity.tintColor = Theme.colorActivityIndicator
		
		self.patchGroup.ruleBottom.backgroundColor = Colors.gray90pcntColor
		self.patchPhoto.imageView?.contentMode = UIViewContentMode.scaleAspectFill
		
		self.userName.titleLabel!.font = Theme.fontHeading
		self.userName.contentHorizontalAlignment = .left
		
		self.patchName.titleLabel?.font = Theme.fontTextDisplay
		self.patchName.contentHorizontalAlignment = .left
		self.patchName.contentVerticalAlignment = .center
		
		self.createdDate.textColor = Theme.colorTextSecondary
		self.shareFrame.clipsToBounds = true
		self.shareFrame.borderColor = Colors.brandColor
		
		self.photo.imageView?.contentMode = UIViewContentMode.scaleAspectFill
		self.photo.contentMode = .scaleAspectFill
		self.photo.contentVerticalAlignment = .fill
		self.photo.contentHorizontalAlignment = .fill
		self.photo.sizeCategory = SizeCategory.standard
		
		self.toolbarGroup.ruleBottom.backgroundColor = Colors.gray90pcntColor
		
		self.likesButton.imageView?.tintColor = Theme.colorTint
        self.likeButton.bounds.size = CGSize(width:48, height:48)
		self.likeButton.imageEdgeInsets = UIEdgeInsetsMake(14, 12, 14, 12)
		
		self.reportButton.setTitle("Report", for: .normal)
		self.reportButton.addTarget(self, action: #selector(MessageDetailViewController.reportAction(sender:)), for: UIControlEvents.touchUpInside)
		self.likesButton.addTarget(self, action: #selector(MessageDetailViewController.likesAction(sender:)), for: UIControlEvents.touchUpInside)
		self.userName.addTarget(self, action: #selector(MessageDetailViewController.userAction(sender:)), for: UIControlEvents.touchUpInside)
		self.patchName.addTarget(self, action: #selector(MessageDetailViewController.patchAction(sender:)), for: UIControlEvents.touchUpInside)
		self.patchPhoto.addTarget(self, action: #selector(MessageDetailViewController.patchAction(sender:)), for: UIControlEvents.touchUpInside)
		self.photo.addTarget(self, action: #selector(MessageDetailViewController.photoAction(sender:)), for: UIControlEvents.touchUpInside)
		
		self.recipientsLabel.text = "To:"
		self.recipientsLabel.textColor = Theme.colorTextSecondary
		self.recipients.textColor = Theme.colorTextTitle
		self.recipients.numberOfLines = 0
		
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
		
		NotificationCenter.default.addObserver(self, selector: #selector(MessageDetailViewController.applicationDidEnterBackground(sender:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
	}
	
	func bind() {
		
		self.scrollView.isHidden = false
		
        if self.isShare {
			
			if self.inputMessage!.message != nil {
				
				self.messageView = MessageView()
				self.messageView?.bindToEntity(entity: self.inputMessage!.message!, location: nil)
				
				/* Resize once here because sizing in viewWillLayoutSubviews causes recursion */
				let viewWidth = min(CONTENT_WIDTH_MAX, self.view.bounds.size.width)
				let contentWidth = CGFloat(viewWidth - 32)
				self.messageView!.bounds.size.width = contentWidth - 24
				self.messageView!.sizeToFit()
				self.messageView?.clipsToBounds = false
				self.shareFrame.addSubview(self.messageView!)
				self.shareFrame.addTarget(self, action: #selector(MessageDetailViewController.shareBrowseAction(sender:)), for: UIControlEvents.touchUpInside)
				self.shareFrame.addTarget(self, action: #selector(MessageDetailViewController.buttonTouchDownAction(sender:)), for: UIControlEvents.touchDown)
				UIView.disableAllSubviewsOf(view: self.shareFrame)
			}
			else if self.inputMessage!.patch != nil {
				
                self.patchView = PatchView(frame: CGRect(x:0, y:0, width:self.view.width(), height:136))
				self.patchView!.bindToEntity(entity: self.inputMessage!.patch!, location: nil)
				self.patchView!.shadow.isHidden = true
				self.patchView?.name.textColor = Colors.brandColor
				self.shareFrame.addSubview(self.patchView!)
				self.shareFrame.addTarget(self, action: #selector(MessageDetailViewController.shareBrowseAction(sender:)), for: UIControlEvents.touchUpInside)
				self.shareFrame.addTarget(self, action: #selector(MessageDetailViewController.buttonTouchDownAction(sender:)), for: UIControlEvents.touchDown)
				UIView.disableAllSubviewsOf(view: self.shareFrame)
			}
			else {
				/*
				 * The target of the share message has been deleted'
				 */
				self.emptyView = AirLabelDisplay()
				self.emptyView!.text = "Deleted"
				self.emptyView!.textAlignment = .center
				self.emptyView!.textColor = Colors.white
				self.shareFrame.borderColor = Theme.colorBackgroundWindow
				self.shareFrame.backgroundColor = Theme.colorBackgroundWindow
				self.shareFrame.addSubview(self.emptyView!)
			}

			self.recipients.text = ""
			if self.inputMessage?.recipients != nil {
				for recipient in self.inputMessage!.recipients as! Set<Shortcut> {
					self.recipients.text!.append("\(recipient.name), ")
				}
				self.recipients.text = String(self.recipients.text!.characters.dropLast(2))
			}
        }
        else {
			
            /* Patch */
            if self.inputMessage!.patch != nil {
				if let photo = self.inputMessage!.patch.photo {
					self.patchPhoto.setImageWithPhoto(photo: photo)
				}
				else if let name = self.inputMessage!.patch.name {
					let seed = Utils.numberFromName(fullname: name)
					self.photo.backgroundColor = Utils.randomColor(seed: seed)
				}
                self.patchName.setTitle(self.inputMessage!.patch.name, for: .normal)
            }
        }

		/* Message */

		self.createdDate.text = Utils.messageDateFormatter.string(from: self.inputMessage!.createdDate)
		
		if self.inputMessage!.description_ != nil {
			if self.description_ == nil {
				self.description_ = TTTAttributedLabel(frame: CGRect.zero)
				self.description_.numberOfLines = 0
				self.description_.font = Theme.fontTextDisplay
				self.description_.linkAttributes = [kCTForegroundColorAttributeName as AnyHashable : Theme.colorTint]
				self.description_.activeLinkAttributes = [kCTForegroundColorAttributeName as AnyHashable : Theme.colorTint]
				self.description_.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue
				self.description_.delegate = self
				self.messageGroup.addSubview(self.description_)
			}
			self.description_.text = self.inputMessage!.description_
			self.description_.sizeToFit()
		}
        
        /* Photo */

		if inputMessage!.photo != nil {
            if !self.photo.linkedToPhoto(photo: self.inputMessage!.photo) {
                self.photo.setImageWithPhoto(photo: self.inputMessage!.photo)
            }
		}

		/* Like button */
        
        likeButton.bindEntity(entity: self.inputMessage)

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
			self.likesButton.setTitle(likesTitle, for: UIControlState.normal)
			if likesButton.alpha == 0 {
				likesButton.fadeIn()
			}
		}
		
		/* User */

		self.userPhoto.bindToEntity(entity: self.inputMessage!.creator)
		self.userName.setTitle(self.inputMessage?.creator.name ?? "Deleted", for: .normal)
	}

	func drawNavButtons(animated: Bool = false) {
		
		let shareButton  = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(MessageDetailViewController.shareAction(sender:)))
		let editButton   = UIBarButtonItem(image: Utils.imageEdit, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MessageDetailViewController.editAction))
		let deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.trash, target: self, action: #selector(MessageDetailViewController.deleteAction))
		let removeButton   = UIBarButtonItem(image: Utils.imageRemove, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MessageDetailViewController.removeAction))
		
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
		
		/* Message could have been deleted downstream */		
		if self.inputMessage?.id_ == nil && self.inputMessageId == nil {
			let _ = self.navigationController?.popViewController(animated: true)
			return
		}
		
		DataController.instance.backgroundOperationQueue.addOperation {
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
			
			DataController.instance.withEntityId(entityId: messageId, strategy: fetchStrategy) {
				[weak self] objectId, error in
				
				if self != nil {
					OperationQueue.main.addOperation {
						self?.activity.stopAnimating()
						if error == nil {
							if objectId == nil {
								self?.emptyLabel.text = "Message is private or has been deleted"
								self?.emptyLabel.fadeIn()
							}
							else {
								self?.inputMessage = DataController.instance.mainContext.object(with: objectId!) as? Message
								self?.drawNavButtons(animated: false)
								self?.bind()
								self?.view.setNeedsLayout() /* Need this because if a message has be be fetched, we haven't done layout yet. */
							}
						}
					}
				}
			}
		}
	}
	
    func delete() {
        
        let entityPath = "data/messages/\((self.inputMessage?.id_)!)"
        DataController.proxibase.deleteObject(path: entityPath) {
            response, error in
			
			OperationQueue.main.addOperation {
				if let error = ServerError(error) {
					self.handleError(error)
				}
				else {
					DataController.instance.mainContext.delete(self.inputMessage!)
					DataController.instance.saveContext(wait: BLOCKING)
					Reporting.track("Deleted Message")
					let _ = self.navigationController?.popViewController(animated: true)
				}
			}
        }
    }
    
    func remove() {
                
        if let fromId = self.inputMessage!.id_, let toId = self.inputMessage!.patchId {
            DataController.proxibase.deleteLink(fromId: fromId, toId: toId, linkType: LinkType.Content) {
                response, error in
                
				OperationQueue.main.addOperation {
					if let error = ServerError(error) {
						UIViewController.topMostViewController()!.handleError(error)
					}
					else {
						DataController.instance.mainContext.delete(self.inputMessage!)
						DataController.instance.saveContext(wait: BLOCKING)
						let _ = self.navigationController?.popViewController(animated: true)
					}
				}
            }
        }
    }

    func shareUsing(route: ShareRoute) {
        
        if route == .Patchr {
			
			let controller = MessageEditViewController()
			let navController = AirNavigationController()
			controller.inputShareEntity = self.inputMessage
			controller.inputShareSchema = Schema.ENTITY_MESSAGE
			controller.inputShareId = self.inputMessage?.id_ ?? self.inputMessageId!
			controller.inputMessageType = .Share
			controller.inputState = .Sharing
			navController.viewControllers = [controller]
			self.present(navController, animated: true, completion: nil)
        }
        else if route == .Actions {			
			
			BranchProvider.share(entity: self.inputMessage!, referrer: UserController.instance.currentUser) {
				response, error in
				
				if let error = ServerError(error) {
					UIViewController.topMostViewController()!.handleError(error)
				}
				else {
					let message = response as! MessageItem
					let activityViewController = UIActivityViewController(
						activityItems: [message],
						applicationActivities: nil)
					
					if UIDevice.current.userInterfaceIdiom == .phone {
						self.present(activityViewController, animated: true, completion: nil)
					}
					else {
						let popup: UIPopoverController = UIPopoverController(contentViewController: activityViewController)
                        popup.present(from: CGRect(x:self.view.frame.size.width/2, y:self.view.frame.size.height/4, width:0, height:0), in: self.view, permittedArrowDirections: UIPopoverArrowDirection.any, animated: true)
					}
				}
			}
        }
    }
}

extension MessageDetailViewController: TTTAttributedLabelDelegate {
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        UIApplication.shared.openURL(url)
    }
}

extension MessageDetailViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
		switch result {
			case MFMailComposeResult.cancelled:	// 0
				UIShared.Toast(message: "Report cancelled", controller: self, addToWindow: false)
			case MFMailComposeResult.saved:		// 1
				UIShared.Toast(message: "Report saved", controller: self, addToWindow: false)
			case MFMailComposeResult.sent:		// 2
				Reporting.track("Sent Report", properties: ["target":"Message" as AnyObject])
				UIShared.Toast(message: "Report sent", controller: self, addToWindow: false)
			case MFMailComposeResult.failed:	// 3
				UIShared.Toast(message: "Report send failure: \(error!.localizedDescription)", controller: self, addToWindow: false)
				break
		}
		
		self.dismiss(animated: true) {
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
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any? {
        let text = "Check out \(self.entity.creator.name)'s message posted to the \(self.entity.patch.name) patch! \(self.shareUrl) \n"
        return text
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String {
		if activityType == UIActivityType.mail {
            return "Patch message posted by \(self.entity.creator.name)"
        }
        return ""
    }
}

private enum ShareButtonFunction {
    case Share
    case ShareVia
}
