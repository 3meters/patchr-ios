//
//  MessageCell.swift
//  Patchr
//
//  Created by Jay Massena on 10/15/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import SDWebImage

class MessageView: BaseView {
	
	var showPatchName	= true
	
	var description_	: UILabel?
	var photo			: AirImageView?
	var isShare			= false
	
	var patchName		= AirLabelDisplay()
	var userName		= AirLabelDisplay()
	var userPhoto		= PhotoView()
	var createdDate		= AirLabelDisplay()

	var recipientsGroup = UIView()
	var recipientsLabel = AirLabelDisplay()
	var recipients		= AirLabelDisplay()
	
	var toolbar			= UIView()
	var likeButton		= AirLikeButton(frame: CGRect.zero)
	var likes			= AirLabelDisplay()
	
	override init(frame: CGRect) {
		/* Called when instantiated from code */
		super.init(frame: frame)
		initialize()
	}
	
	required init?(coder aDecoder: NSCoder) {
		/* Called when instantiated from storyboard or nib */
		super.init(coder: aDecoder)
		initialize()
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	/*--------------------------------------------------------------------------------------------
	* Events
	*--------------------------------------------------------------------------------------------*/
	
	override func layoutSubviews() {
		super.layoutSubviews()
		/*
		* Triggers:
		* - foo.addSubview(bar) triggers layoutSubviews on foo, bar and all subviews of foo
		* - Bounds (not frame) change for foo or foo.subviews (frame.size is propogated to bounds.size)
		* - foo.addSubview does not trigger layoutSubviews if foo.autoresize mask == false
		* - foo.setNeedsLayout is called
		*
		* Note: above triggers set dirty flag using setNeedsLayout which gets
		* checked for all views in the view hierarchy for every run loop iteration.
		* If dirty, layoutSubviews is called in hierarchy order and flag is reset.
		*/
		let columnLeft = CGFloat(48 + 8)
		let columnWidth = self.bounds.size.width - columnLeft
		let photoHeight = columnWidth * 0.5625		// 16:9 aspect ratio
		
		if self.showPatchName && self.patchName.text != nil {
			self.patchName.sizeToFit()
			self.patchName.anchorTopLeft(withLeftPadding: columnLeft, topPadding: 0, width: columnWidth, height: self.patchName.height())
			self.userPhoto.anchorTopLeft(withLeftPadding: 0, topPadding: self.patchName.height() + 8, width: 48, height: 48)
		}
		else {
			self.userPhoto.anchorTopLeft(withLeftPadding: 0, topPadding: 0, width: 48, height: 48)
		}
		
		/* Header */
		
		self.createdDate.sizeToFit()
		self.userName.sizeToFit()
		self.userName.align(toTheRightOf: self.userPhoto, matchingTopWithLeftPadding: 8, width: columnWidth - (self.createdDate.width() + 8), height: self.userName.height())
		self.createdDate.align(toTheRightOf: self.userName, matchingCenterAndFillingWidthWithLeftAndRightPadding: 0, height: self.createdDate.height())
		
		/* Body */
		
		var bottomView: UIView? = self.photo
		if self.isShare || self.entity?.photo == nil {
			bottomView = self.description_
			self.description_?.bounds.size.width = columnWidth
			self.description_?.sizeToFit()
			self.description_?.alignUnder(self.userName, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 0, height: self.description_!.height())
		}
		
		if self.entity?.description_ != nil && self.entity?.photo != nil {
			self.description_?.bounds.size.width = columnWidth
			self.description_?.sizeToFit()
			self.description_?.alignUnder(self.userName, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 0, height: self.description_!.height())
			self.photo?.alignUnder(self.description_!, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 8, height: photoHeight)
		}
		else if self.entity?.photo != nil {
			self.photo?.alignUnder(self.userName, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 8, height: photoHeight)
		}
		
		/* Footer */
		
		if self.isShare {
			self.recipientsLabel.sizeToFit()
			self.recipients.bounds.size.width = columnWidth - (self.recipientsLabel.width() + 12)
			self.recipients.sizeToFit()
			self.recipientsLabel.anchorTopLeft(withLeftPadding: 0, topPadding: 0, width: self.recipientsLabel.width(), height: self.recipientsLabel.height())
			self.recipients.align(toTheRightOf: self.recipientsLabel, matchingTopWithLeftPadding: 12, width: self.recipients.width(), height: self.recipients.height())
			self.recipientsGroup.alignUnder(bottomView!, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 8, height: self.recipients.height() + 12)
		}
		else {
			self.toolbar.alignUnder(bottomView!, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 0, height: 48)
			self.likeButton.anchorCenterLeft(withLeftPadding: 0, width: self.likeButton.width(), height: self.likeButton.height())
			self.likeButton.frame.origin.x -= 12
			self.likes.sizeToFit()
			self.likes.align(toTheRightOf: self.likeButton, matchingCenterWithLeftPadding: 0, width: self.likes.width(), height: self.likes.height())
			self.likes.frame.origin.x -= 4
		}
	}

	func likeDidChange(notification: NSNotification) {
		
		if let userInfo = notification.userInfo,
			let entityId = userInfo["entityId"] as? String {
				if let message = self.entity as? Message, message.id_ != nil && entityId == message.id_ {
					
					/* Likes button */
					self.likeButton.bindEntity(entity: message)

					self.likes.text = nil
					
					if message.countLikes != nil {
						if message.countLikes?.intValue != 0 {
							self.likes.text = String(message.countLikes.intValue)
							self.likes.sizeToFit()
							self.likes.align(toTheRightOf: self.likeButton, matchingCenterWithLeftPadding: 0, width: self.likes.width(), height: self.likes.height())
							self.likes.frame.origin.x -= 4
						}
					}
					self.likes.textColor = message.userLikesValue ? Colors.brandColor : Theme.colorText
				}
		}
	}

	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		/*
		 * The calls to addSubview will trigger a call to layoutSubviews for
		 * the current update cycle.
		 */
		
		/* Description */
		self.description_ = TTTAttributedLabel(frame: CGRect.zero)
		self.description_!.numberOfLines = 5
		self.description_!.font = Theme.fontTextList
		
		if self.description_ != nil && !(self.description_ is TTTAttributedLabel) {
			let linkColor = Theme.colorTint
			let linkActiveColor = Theme.colorTint
			let label = self.description_ as! TTTAttributedLabel
			label.linkAttributes = [kCTForegroundColorAttributeName as AnyHashable : linkColor]
			label.activeLinkAttributes = [kCTForegroundColorAttributeName as AnyHashable : linkActiveColor]
			label.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue|NSTextCheckingResult.CheckingType.address.rawValue
		}

		self.addSubview(self.description_!)
		
		/* Photo: give initial size in case the image displays before call to layoutSubviews		 */
		let columnLeft = CGFloat(48 + 8)
		let columnWidth = min(CONTENT_WIDTH_MAX, UIScreen.main.bounds.size.width) - columnLeft
		let photoHeight = columnWidth * 0.5625		// 16:9 aspect ratio
		
        self.photo = AirImageView(frame: CGRect(x:0, y:0, width:columnWidth, height:photoHeight))
		self.photo!.clipsToBounds = true
		self.photo!.contentMode = .scaleAspectFill
		self.photo!.backgroundColor = Theme.colorBackgroundImage
		
		self.addSubview(self.photo!)
		
		/* Patch name */
		self.patchName.font = Theme.fontComment
		self.patchName.textColor = Theme.colorTextSecondary
		self.patchName.numberOfLines = 1
		self.patchName.lineBreakMode = .byTruncatingMiddle
		self.addSubview(self.patchName)
		
		/* User photo */
		self.addSubview(self.userPhoto)
		
		/* Header */
		self.userName.font = Theme.fontTextBold
		self.userName.numberOfLines = 1
		self.userName.lineBreakMode = .byTruncatingMiddle
		
		self.createdDate.font = Theme.fontComment
		self.createdDate.numberOfLines = 1
		self.createdDate.textColor = Theme.colorTextSecondary
		self.createdDate.textAlignment = .right
		
		self.addSubview(self.userName)
		self.addSubview(self.createdDate)
		
		/* Footer */
		
		self.recipientsLabel.text = "To:"
		self.recipientsLabel.font = Theme.fontTextList
		self.recipientsLabel.textColor = Theme.colorTextSecondary
		self.recipientsLabel.numberOfLines = 1
		self.recipients.font = Theme.fontTextList
		self.recipients.textColor = Theme.colorTextTitle
		self.recipients.numberOfLines = 0

		self.recipientsGroup.addSubview(self.recipientsLabel)
		self.recipientsGroup.addSubview(self.recipients)
		self.addSubview(self.recipientsGroup)
		
		self.likeButton.imageView!.tintColor = Theme.colorTint
        self.likeButton.bounds.size = CGSize(width:48, height:48)
		self.likeButton.imageEdgeInsets = UIEdgeInsetsMake(14, 12, 14, 12)

		self.likes.font = Theme.fontText
		self.likes.numberOfLines = 1
		self.likes.textColor = Theme.colorText
		self.likes.textAlignment = .right
		
		self.toolbar.addSubview(self.likeButton)
		self.toolbar.addSubview(self.likes)
		self.addSubview(self.toolbar)
		
		NotificationCenter.default.addObserver(self, selector: #selector(MessageView.likeDidChange(notification:)), name: NSNotification.Name(rawValue: Events.LikeDidChange), object: nil)
	}
	
	override func bindToEntity(entity: AnyObject, location: CLLocation?) {
		
		let entity = entity as! Entity
		
		self.entity = entity
		self.isShare = (self.entity?.type != nil && self.entity?.type == "share")
		
		self.description_?.isHidden = true
		self.photo?.isHidden = true
		self.patchName.isHidden = true
		self.toolbar.isHidden = true
		self.recipientsGroup.isHidden = true
		
		if let description = entity.description_ {
			self.description_?.isHidden = false
			self.description_?.text = description
		}
		
		if let photo = entity.photo {
			self.photo?.isHidden = false
			let photoUrl = PhotoUtils.url(prefix: photo.prefix!, source: photo.source!, category: SizeCategory.standard)
			bindPhoto(photoUrl: photoUrl)
		}
		
		self.userName.text = entity.creator?.name ?? "Deleted"
		self.userPhoto.bindToEntity(entity: entity.creator)
		self.createdDate.text = UIShared.timeAgoShort(date: entity.createdDate as NSDate)
		
		if let message = entity as? Message {
			
			/* Patch */
			if self.showPatchName {
				self.patchName.isHidden = false
				if message.patch != nil {
					self.patchName.text = message.patch.name
				}
				else if message.type != nil && message.type == "share" {
					self.patchName.text = "Shared by"
				}
			}
			
			if self.isShare {
				self.recipientsGroup.isHidden = false
				self.recipients.text = ""
				if message.recipients != nil {
					for recipient in message.recipients as! Set<Shortcut> {
						self.recipients.text!.append("\(recipient.name), ")
					}
					self.recipients.text = String(self.recipients.text!.characters.dropLast(2))
				}
			}
			else {
				self.toolbar.isHidden = false
				self.likeButton.bindEntity(entity: message)
				self.likes.text = nil
				if message.countLikes != nil {
					if message.countLikes?.intValue != 0 {
						self.likes.text = String(message.countLikes.intValue)
					}
				}
				self.likes.textColor = message.userLikesValue ? Colors.brandColor : Theme.colorText
			}
		}
		
		self.setNeedsLayout()	// Needed because binding can change the layout
	}
	
	private func bindPhoto(photoUrl: URL) {
		
		if self.photo?.image != nil
			&& self.photo!.linkedPhotoUrl != nil
			&& self.photo!.linkedPhotoUrl?.absoluteString == photoUrl.absoluteString {
			return
		}
		
		self.photo?.image = nil
		self.photo!.setImageWithUrl(url: photoUrl, animate: true)
	}
}
