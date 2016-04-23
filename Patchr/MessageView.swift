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
	
	var cellType		: CellType = .TextAndPhoto
	var showPatchName	= true
	
	var description_	: UILabel?
	var photo			: UIButton?
	
	var patchName		= AirLabelDisplay()
	var userName		= AirLabelDisplay()
	var userPhoto		= UserPhotoView()
	var createdDate		= AirLabelDisplay()
	var recipientsLabel = AirLabelDisplay()
	var recipients		= AirLabelDisplay()
	
	var toolbar			= UIView()
	var likeButton		: AirLikeButton?
	var likes			= AirLabelDisplay()
	
	init(cellType: CellType?) {
		super.init(frame: CGRectZero)
		if cellType != nil {
			self.cellType = cellType!
		}
		initialize()
	}
	
	init(cellType: CellType?, entity: Entity? = nil) {
		super.init(frame: CGRectZero)
		if cellType != nil {
			self.cellType = cellType!
		}
		initialize()
		if entity != nil {
			bindToEntity(entity!)
		}		
	}
	
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
		NSNotificationCenter.defaultCenter().removeObserver(self)
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
			self.patchName.hidden = false
			self.patchName.sizeToFit()
			self.patchName.anchorTopLeftWithLeftPadding(columnLeft, topPadding: 0, width: columnWidth, height: self.patchName.height())
			self.userPhoto.anchorTopLeftWithLeftPadding(0, topPadding: self.patchName.height() + 8, width: 48, height: 48)
		}
		else {
			self.patchName.hidden = true
			self.userPhoto.anchorTopLeftWithLeftPadding(0, topPadding: 0, width: 48, height: 48)
		}
		
		/* Header */
		
		self.createdDate.sizeToFit()
		self.userName.sizeToFit()
		self.userName.alignToTheRightOf(self.userPhoto, matchingTopWithLeftPadding: 8, width: columnWidth - (self.createdDate.width() + 8), height: self.userName.height())
		self.createdDate.alignToTheRightOf(self.userName, matchingCenterAndFillingWidthWithLeftAndRightPadding: 0, height: self.createdDate.height())
		
		/* Body */
		
		var bottomView: UIView? = self.photo
		if self.cellType == .Share || self.cellType == .Text {
			bottomView = self.description_
			self.description_?.bounds.size.width = columnWidth
			self.description_?.sizeToFit()
			self.description_?.alignUnder(self.userName, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 8, height: self.description_!.height())
		}
		if self.cellType == .TextAndPhoto {
			self.description_?.bounds.size.width = columnWidth
			self.description_?.sizeToFit()
			self.description_?.alignUnder(self.userName, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 8, height: self.description_!.height())
			self.photo?.alignUnder(self.description_!, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 8, height: photoHeight)
		}
		else if self.cellType == .Photo {
			self.photo?.alignUnder(self.userName, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 8, height: photoHeight)
		}
		
		/* Footer */
		
		if self.cellType == .Share {
			self.recipientsLabel.sizeToFit()
			self.recipients.bounds.size.width = columnWidth - (self.recipientsLabel.width() + 12)
			self.recipients.sizeToFit()
			self.recipientsLabel.alignUnder(bottomView!, matchingLeftWithTopPadding: 8, width: self.recipientsLabel.width(), height: self.recipientsLabel.height())
			self.recipients.alignToTheRightOf(self.recipientsLabel, matchingTopWithLeftPadding: 12, width: self.recipients.width(), height: self.recipients.height())
		}
		else {
			self.toolbar.alignUnder(bottomView!, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 0, height: 48)
			if likeButton != nil {
				self.likeButton!.anchorCenterLeftWithLeftPadding(0, width: self.likeButton!.width(), height: self.likeButton!.height())
				self.likeButton!.frame.origin.x -= 12
			}
			self.likes.sizeToFit()
			self.likes.anchorCenterRightWithRightPadding(0, width: 72, height: self.likes.height())
		}
	}

	func likeDidChange(notification: NSNotification) {
		
		if let userInfo = notification.userInfo,
			let entityId = userInfo["entityId"] as? String {
				if let message = self.entity as? Message where message.id_ != nil && entityId == message.id_ {
					
					/* Likes button */
					self.likeButton?.bindEntity(message)

					self.likes.text = nil
					if message.countLikes != nil {
						if message.countLikes?.integerValue != 0 {
							let likesTitle = message.countLikes?.integerValue == 1
								? "\(message.countLikes) like"
								: "\(message.countLikes ?? 0) likes"
							self.likes.text = likesTitle
							self.likes.sizeToFit()
							self.likes.anchorCenterRightWithRightPadding(0, width: 72, height: self.likes.height())
						}
					}
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
		if self.cellType != .Photo {
			self.description_ = TTTAttributedLabel(frame: CGRectZero)
			//			self.description_ = UILabel(frame: CGRectZero)
			self.description_!.numberOfLines = 5
			self.description_!.font = Theme.fontTextList
			self.addSubview(self.description_!)
		}
		
		/* Photo */
		if self.cellType != .Text {
			self.photo = UIButton(frame: CGRectZero)
			self.photo!.imageView!.contentMode = UIViewContentMode.ScaleAspectFill
			self.photo!.contentMode = .ScaleAspectFill
			self.photo!.contentHorizontalAlignment = .Fill
			self.photo!.contentVerticalAlignment = .Fill
			self.photo!.backgroundColor = Theme.colorBackgroundImage
			self.addSubview(self.photo!)
		}
		
		/* Patch name */
		self.patchName.font = Theme.fontComment
		self.patchName.textColor = Theme.colorTextSecondary
		self.addSubview(self.patchName)
		
		/* User photo */
		self.addSubview(self.userPhoto)
		
		/* Header */
		self.userName.lineBreakMode = .ByTruncatingMiddle
		self.userName.font = Theme.fontTextBold
		
		self.createdDate.font = Theme.fontComment
		self.createdDate.textColor = Theme.colorTextSecondary
		self.createdDate.textAlignment = .Right
		
		self.addSubview(self.userName)
		self.addSubview(self.createdDate)
		
		/* Footer */
		
		if self.cellType == .Share {
			self.recipientsLabel.text = "To:"
			self.recipientsLabel.font = Theme.fontTextList
			self.recipientsLabel.textColor = Theme.colorTextSecondary
			self.recipients.font = Theme.fontTextList
			self.recipients.textColor = Theme.colorTextTitle
			self.recipients.numberOfLines = 0
			self.addSubview(self.recipientsLabel)
			self.addSubview(self.recipients)
		}
		else {
			self.likeButton = AirLikeButton(frame: CGRectZero)
			if (self.likeButton != nil) {
				self.likeButton!.imageView!.tintColor = Theme.colorTint
				self.likeButton!.bounds.size = CGSizeMake(48, 48)
				self.likeButton!.imageEdgeInsets = UIEdgeInsetsMake(14, 12, 14, 12)
				self.toolbar.addSubview(self.likeButton!)
			}

			self.likes.font = Theme.fontComment
			self.likes.textColor = Theme.colorTextTitle
			self.likes.textAlignment = .Right
			
			self.toolbar.addSubview(self.likes)
			self.addSubview(self.toolbar)
		}
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MessageView.likeDidChange(_:)), name: Events.LikeDidChange, object: nil)
	}
	
	func bindToEntity(entity: AnyObject) {
		
		let entity = entity as! Entity
		
		self.entity = entity
		
		let linkColor = Theme.colorTint
		let linkActiveColor = Theme.colorTint
		
		if self.description_ != nil && self.description_!.isKindOfClass(TTTAttributedLabel) {
			let label = self.description_ as! TTTAttributedLabel
			label.linkAttributes = [kCTForegroundColorAttributeName : linkColor]
			label.activeLinkAttributes = [kCTForegroundColorAttributeName : linkActiveColor]
			label.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue|NSTextCheckingType.Address.rawValue
		}
		
		if let description = entity.description_ {
			self.description_?.text = description
		}
		
		let options: SDWebImageOptions = [.RetryFailed, .LowPriority,  .ProgressiveDownload]
		
		if let photo = entity.photo {
			let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!, category: SizeCategory.standard)
			self.photo?.sd_setImageWithURL(photoUrl, forState: UIControlState.Normal, placeholderImage: nil, options: options)
		}
		
		self.userName.text = entity.creator?.name ?? "Deleted"
		
		self.userPhoto.bindToEntity(entity.creator)
		
		if let message = entity as? Message {
			
			/* Patch */
			if message.patch != nil {
				self.patchName.text = message.patch.name
			}
			else if message.type != nil && message.type == "share" {
				self.patchName.text = "Shared by"
			}
			
			if self.cellType == .Share {
				self.recipients.text = ""
				if message.recipients != nil {
					for recipient in message.recipients as! Set<Shortcut> {
						self.recipients.text!.appendContentsOf("\(recipient.name), ")
					}
					self.recipients.text = String(self.recipients.text!.characters.dropLast(2))
				}
			}
			else {
				/* Likes button */
				self.likeButton?.bindEntity(message)
				
				self.likes.text = nil
				if message.countLikes != nil {
					if message.countLikes?.integerValue != 0 {
						let likesTitle = message.countLikes?.integerValue == 1
							? "\(message.countLikes) like"
							: "\(message.countLikes ?? 0) likes"
						self.likes.text = likesTitle
					}
				}
			}
		}
		
		self.createdDate.text = UIShared.timeAgoShort(entity.createdDate)
		
		self.setNeedsLayout()	// Needed because binding can change the layout
	}
	
	override func sizeThatFits(size: CGSize) -> CGSize {
		
		if let entity = self.entity {
			
			var heightAccum = CGFloat(0)
			
			let columnLeft = CGFloat(48 + 8)
			let columnWidth = size.width - columnLeft
			let photoHeight = columnWidth * 0.5625
			
			if self.showPatchName {
				self.patchName.sizeToFit()
				heightAccum += self.patchName.height()
				self.userName.sizeToFit()
				heightAccum += (8 + self.userName.height())
			}
			else {
				self.userName.sizeToFit()
				heightAccum += self.userName.height()
			}
			
			if entity.description_ != nil && !entity.description_.isEmpty {
				self.description_!.bounds.size.width = columnWidth
				self.description_!.sizeToFit()
				heightAccum += (8 + self.description_!.height())
			}
			
			if entity.photo != nil {
				heightAccum += (8 + photoHeight)
			}
			
			if self.cellType == .Share {
				self.recipientsLabel.sizeToFit()
				self.recipients.bounds.size.width = columnWidth - (self.recipientsLabel.width() + 12)
				self.recipients.sizeToFit()
				heightAccum += 8 + self.recipients.height()
			}
			else {
				self.likes.sizeToFit()
				if self.likeButton != nil {
					heightAccum += (max(self.likeButton!.height() - 14, self.likes.height())) // Like button
				}
				else {
					heightAccum += self.likes.height()
				}
			}
			
			let height = max(self.userPhoto.height(), heightAccum)

			return CGSizeMake(size.width, height)
		}
		
		return CGSizeZero
	}
	
}
