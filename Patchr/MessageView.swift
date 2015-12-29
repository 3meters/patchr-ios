//
//  MessageCell.swift
//  Patchr
//
//  Created by Jay Massena on 10/15/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class MessageView: BaseView {

	var cellType		: CellType = .TextAndPhoto
	var showPatchName	= true
	
	var description_	: TTTAttributedLabel?
	var photo			: UIButton?
	
	var userName		= AirLabelDisplay()
	var userPhoto		= UIImageView(frame: CGRectZero)
	var createdDate		= AirLabelDisplay()
	var recipientsLabel = AirLabelDisplay()
	var recipients		= AirLabelDisplay()
	var likes			= AirLabelDisplay()
	var likeButton		= AirLikeButton(frame: CGRectZero)
	var patchName		= AirLabelDisplay()
	
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
	
	func initialize() {
		
		self.clipsToBounds = true
		
		/* Description */
		if self.cellType != .Photo {
			self.description_ = TTTAttributedLabel(frame: CGRectZero)
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
		self.userPhoto.contentMode = UIViewContentMode.ScaleAspectFill
		self.userPhoto.clipsToBounds = true
		self.userPhoto.layer.cornerRadius = 24
		self.userPhoto.bounds.size = CGSizeMake(48, 48)
		self.userPhoto.layer.backgroundColor = Theme.colorBackgroundImage.CGColor
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
			self.addSubview(self.recipientsLabel)
			self.addSubview(self.recipients)
		}
		else {
			self.likeButton.imageView!.tintColor = Theme.colorTint
			self.likeButton.bounds.size = CGSizeMake(24, 20)

			self.likes.font = Theme.fontComment
			self.likes.textColor = Theme.colorTextTitle
			self.likes.textAlignment = .Right
			
			self.addSubview(self.likeButton)
			self.addSubview(self.likes)
		}
	}
	
	func bindToEntity(entity: AnyObject) {
		
		let entity = entity as! Entity
		
		self.entity = entity
		
		let linkColor = Theme.colorTint
		let linkActiveColor = Theme.colorTint
		
		self.description_?.linkAttributes = [kCTForegroundColorAttributeName : linkColor]
		self.description_?.activeLinkAttributes = [kCTForegroundColorAttributeName : linkActiveColor]
		self.description_?.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue|NSTextCheckingType.Address.rawValue
		
		if let description = entity.description_ {
			self.description_?.text = description
		}
		
		let options: SDWebImageOptions = [.RetryFailed, .LowPriority,  .ProgressiveDownload]
		
		if let photo = entity.photo {
			let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!, category: SizeCategory.standard)
			self.photo?.sd_setImageWithURL(photoUrl, forState: UIControlState.Normal, placeholderImage: nil, options: options)
		}
		
		self.userName.text = entity.creator?.name ?? "Deleted"
		
		if let photo = entity.creator?.getPhotoManaged() {
			let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!, category: SizeCategory.profile)
			self.userPhoto.sd_setImageWithURL(photoUrl, placeholderImage: nil, options: options)
		}
		else {
			let photo = Entity.getDefaultPhoto("user", id: nil)
			let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!, category: SizeCategory.profile)
			self.userPhoto.sd_setImageWithURL(photoUrl, placeholderImage: nil, options: options)
		}
		
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
				self.likeButton.bindEntity(message)
				
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
		
		self.createdDate.text = Shared.timeAgoShort(entity.createdDate)
		
		self.setNeedsLayout()
	}
	
	override func sizeThatFits(size: CGSize) -> CGSize {
		
		if let entity = self.entity {
			
			var heightAccum = CGFloat(0)
			
			let columnLeft = CGFloat(self.userPhoto.width() + 8)
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
				heightAccum += (8 + max(self.likeButton.height(), self.likes.height())) // Like button
			}
			
			let height = max(self.userPhoto.height(), heightAccum)

			return CGSizeMake(size.width, height)
		}
		
		return CGSizeZero
	}
	
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
		let columnLeft = CGFloat(self.userPhoto.width() + 8)
		let columnWidth = self.bounds.size.width - columnLeft
		let photoHeight = columnWidth * 0.5625		// 16:9 aspect ratio
		
		if self.showPatchName && self.patchName.text != nil {
			self.patchName.hidden = false
			self.patchName.sizeToFit()
			self.patchName.anchorTopLeftWithLeftPadding(columnLeft, topPadding: 0, width: self.patchName.width(), height: self.patchName.height())
			self.userPhoto.anchorTopLeftWithLeftPadding(0, topPadding: self.patchName.height() + 8, width: self.userPhoto.width(), height: self.userPhoto.height())
		}
		else {
			self.patchName.hidden = true
			self.userPhoto.anchorTopLeftWithLeftPadding(0, topPadding: 0, width: self.userPhoto.width(), height: self.userPhoto.height())
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
			self.likes.sizeToFit()
			self.likeButton.alignUnder(bottomView!, matchingLeftWithTopPadding: 8, width: self.likeButton.width(), height: self.likeButton.height())
			self.likes.alignUnder(bottomView!, matchingRightWithTopPadding: 8, width: self.likes.width(), height: self.likes.height())
		}
	}
}
