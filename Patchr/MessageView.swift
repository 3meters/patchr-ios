//
//  MessageCell.swift
//  Patchr
//
//  Created by Jay Massena on 10/15/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class MessageView: BaseView {

	var cellType: CellType = .TextAndPhoto
	var showPatchName = true
	
	var description_:	TTTAttributedLabel?
	var photo:			UIButton?
	
	var userName		= UILabel()
	var userPhoto		= UIImageView(frame: CGRectZero)
	var createdDate		= UILabel()
	var recipientsLabel = AirLabelDisplay()
	var recipients		= AirLabelDisplay()
	var likes			= UILabel()
	var likeButton		= AirLikeButton(frame: CGRectZero)
	var patchName		= UILabel()
	
	init(cellType: CellType?) {
		super.init(frame: CGRectZero)
		if cellType != nil {
			self.cellType = cellType!
		}
		initialize()
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
		
		self.clipsToBounds = false
		
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
			self.photo!.clipsToBounds = false
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
		self.userPhoto.layer.backgroundColor = Theme.colorBackgroundImage.CGColor
		self.addSubview(self.userPhoto)
		
		/* Header */
		self.userName.lineBreakMode = .ByTruncatingMiddle
		self.userName.font = Theme.fontHeading4
		
		self.createdDate.font = Theme.fontComment
		self.createdDate.textColor = Theme.colorTextSecondary
		self.createdDate.textAlignment = NSTextAlignment.Right
		
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
			self.likeButton.imageView!.tintColor(Theme.colorTint)
			self.likes.font = Theme.fontComment
			self.likes.textColor = Theme.colorButtonTitle
			
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
		
		self.createdDate.text = Utils.messageDateFormatter.stringFromDate(entity.createdDate)
		
		self.setNeedsLayout()
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
		let columnLeft = CELL_USER_PHOTO_SIZE + CELL_VIEW_SPACING
		let columnWidth = self.bounds.size.width - columnLeft
		let photoHeight = columnWidth * CELL_PHOTO_RATIO
		
		if self.showPatchName && self.patchName.text != nil {
			self.patchName.hidden = false
			self.patchName.anchorTopLeftWithLeftPadding(columnLeft, topPadding: 0, width: columnWidth, height: CELL_CONTEXT_HEIGHT)
			self.userPhoto.anchorTopLeftWithLeftPadding(0,
				topPadding: CELL_CONTEXT_HEIGHT + CELL_VIEW_SPACING,
				width: CELL_USER_PHOTO_SIZE, height: CELL_USER_PHOTO_SIZE)
		}
		else {
			self.patchName.hidden = true
			self.userPhoto.anchorTopLeftWithLeftPadding(0, topPadding: 0, width: CELL_USER_PHOTO_SIZE, height: CELL_USER_PHOTO_SIZE)
		}
		
		/* Header */
		
		self.createdDate.sizeToFit()
		let dateSize = self.createdDate.sizeThatFits(CGSizeMake(columnWidth, CGFloat.max))
		self.userName.alignToTheRightOf(self.userPhoto, matchingTopWithLeftPadding: CELL_VIEW_SPACING, width: columnWidth - (dateSize.width + 8), height: CELL_HEADER_HEIGHT)
		self.createdDate.alignToTheRightOf(self.userName, matchingCenterAndFillingWidthWithLeftAndRightPadding: 0, height: CELL_HEADER_HEIGHT)
		
		/* Body */
		
		var bottomView: UIView? = self.photo
		if self.cellType == .Share {
			bottomView = self.description_
			let descSize = self.description_?.sizeThatFits(CGSizeMake(columnWidth, CGFloat.max))
			self.description_?.alignUnder(self.userName, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: CELL_VIEW_SPACING, height: (descSize?.height)!)
		}
		if self.cellType == .TextAndPhoto {
			let descSize = self.description_?.sizeThatFits(CGSizeMake(columnWidth, CGFloat.max))
			self.description_?.alignUnder(self.userName, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: CELL_VIEW_SPACING, height: (descSize?.height)!)
			self.photo?.alignUnder(self.description_!, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: CELL_VIEW_SPACING, height: photoHeight)
		}
		else if self.cellType == .Photo {
			self.photo?.alignUnder(self.userName, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: CELL_VIEW_SPACING, height: photoHeight)
		}
		else if self.cellType == .Text {
			bottomView = self.description_
			let descSize = self.description_?.sizeThatFits(CGSizeMake(columnWidth, CGFloat.max))
			self.description_?.alignUnder(self.userName, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: CELL_VIEW_SPACING, height: (descSize?.height)!)
		}
		
		/* Footer */
		
		if self.cellType == .Share {
			let recipientsSize = self.recipients.sizeThatFits(CGSizeMake(columnWidth - 28, CGFloat.max))
			self.recipientsLabel.alignUnder(bottomView!, matchingLeftWithTopPadding: CELL_VIEW_SPACING, width: 28, height: CELL_FOOTER_HEIGHT)
			self.recipients.alignToTheRightOf(self.recipientsLabel, matchingTopWithLeftPadding: 0, width: columnWidth - 28, height: recipientsSize.height)
		}
		else {
			self.likeButton.alignUnder(bottomView!, matchingLeftWithTopPadding: CELL_VIEW_SPACING, width: 24, height: CELL_FOOTER_HEIGHT)
			self.likes.alignToTheRightOf(self.likeButton, matchingCenterAndFillingWidthWithLeftAndRightPadding: 12, height: CELL_FOOTER_HEIGHT)
		}
	}
	
	static func quickHeight(width: CGFloat, showPatchName: Bool, entity: Entity) -> CGFloat {
		
		let minHeight: CGFloat = CELL_USER_PHOTO_SIZE + (CELL_PADDING_VERTICAL * 2)
		let columnLeft = CELL_USER_PHOTO_SIZE + CELL_VIEW_SPACING + (CELL_PADDING_HORIZONTAL * 2)
		let columnWidth = width - columnLeft
		let photoHeight = columnWidth * CELL_PHOTO_RATIO
		
		var height = CELL_HEADER_HEIGHT + CELL_FOOTER_HEIGHT + CELL_VIEW_SPACING + (CELL_PADDING_VERTICAL * 2)
		if let message = entity as? Message {
			if (showPatchName && message.patch?.name != nil) || (message.type != nil && message.type == "share") {
				height = CELL_CONTEXT_HEIGHT + CELL_HEADER_HEIGHT + CELL_FOOTER_HEIGHT + (CELL_VIEW_SPACING * 2) + (CELL_PADDING_VERTICAL * 2)
			}
		}
		
		if entity.description_ != nil {
			
			let description = entity.description_ as NSString
			let attributes = [NSFontAttributeName: Theme.fontTextList]
			let options: NSStringDrawingOptions = [NSStringDrawingOptions.UsesLineFragmentOrigin, NSStringDrawingOptions.UsesFontLeading]
			
			/* Most time is spent here */
			let rect: CGRect = description.boundingRectWithSize(CGSizeMake(columnWidth, CGFloat.max),
				options: options,
				attributes: attributes,
				context: nil)
			
			let descHeight = min(rect.height, 102.272)	// Cap at ~5 lines based on HNeueLight 17pts
			height += (descHeight + CELL_VIEW_SPACING + 0.5) // Add a bit because of rounding scruff
		}
		
		if entity.photo != nil {
			/* This relies on sizing and spacing of the message view */
			height += photoHeight + CELL_VIEW_SPACING  // 16:9 aspect ratio
		}
		
		height = max(minHeight, height)
		
		return CGFloat(height)	// Add one for row separator
	}
}
