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
			self.description_!.font = UIFont(name: "HelveticaNeue-Light", size: 17)
			self.addSubview(self.description_!)
		}
		
		/* Photo */
		if self.cellType != .Text {
			self.photo = UIButton(frame: CGRectZero)
			self.photo!.imageView!.contentMode = UIViewContentMode.ScaleAspectFill
			self.photo!.contentMode = .ScaleAspectFill
			self.photo!.contentHorizontalAlignment = .Fill
			self.photo!.contentVerticalAlignment = .Fill
			self.photo!.backgroundColor = Colors.windowColor
			self.photo!.clipsToBounds = false
			self.addSubview(self.photo!)
		}
		
		/* Patch name */
		self.patchName.font = UIFont(name: "HelveticaNeue-Light", size: 15)
		self.patchName.textColor = Colors.secondaryText
		self.addSubview(self.patchName)
		
		/* User photo */
		self.userPhoto.contentMode = UIViewContentMode.ScaleAspectFill
		self.userPhoto.clipsToBounds = true
		self.userPhoto.layer.cornerRadius = 24
		self.addSubview(self.userPhoto)
		
		/* Header */
		self.userName.lineBreakMode = .ByTruncatingMiddle
		self.userName.font = UIFont(name: "HelveticaNeue-Bold", size: 17)
		
		self.createdDate.font = UIFont(name: "HelveticaNeue-Light", size: 15)
		self.createdDate.textColor = Colors.secondaryText
		self.createdDate.textAlignment = NSTextAlignment.Right
		
		self.addSubview(self.userName)
		self.addSubview(self.createdDate)
		
		/* Footer */
		self.likeButton.imageView!.tintColor(Colors.brandColor)
		self.likes.font = UIFont(name: "HelveticaNeue-Light", size: 15)
		self.likes.textColor = Colors.brandColor
		
		self.addSubview(self.likeButton)
		self.addSubview(self.likes)
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
		
		let entity = self.entity as? Message
		
		if self.showPatchName && entity?.patch?.name != nil {
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
		
		self.likeButton.alignUnder(bottomView!, matchingLeftWithTopPadding: CELL_VIEW_SPACING, width: 24, height: CELL_FOOTER_HEIGHT)
		self.likes.alignToTheRightOf(self.likeButton, matchingCenterAndFillingWidthWithLeftAndRightPadding: 12, height: CELL_FOOTER_HEIGHT)
	}
	
	static func quickHeight(width: CGFloat, showPatchName: Bool, entity: Entity) -> CGFloat {
		
		let minHeight: CGFloat = CELL_USER_PHOTO_SIZE + (CELL_PADDING_VERTICAL * 2)
		let columnLeft = CELL_USER_PHOTO_SIZE + CELL_VIEW_SPACING + (CELL_PADDING_HORIZONTAL * 2)
		let columnWidth = width - columnLeft
		let photoHeight = columnWidth * CELL_PHOTO_RATIO
		
		var height = CELL_HEADER_HEIGHT + CELL_FOOTER_HEIGHT + CELL_VIEW_SPACING + (CELL_PADDING_VERTICAL * 2)
		if let message = entity as? Message {
			if showPatchName && message.patch?.name != nil {
				height = CELL_CONTEXT_HEIGHT + CELL_HEADER_HEIGHT + CELL_FOOTER_HEIGHT + (CELL_VIEW_SPACING * 2) + (CELL_PADDING_VERTICAL * 2)
			}
		}
		
		if entity.description_ != nil {
			
			let description = entity.description_ as NSString
			let attributes = [NSFontAttributeName: UIFont(name:"HelveticaNeue-Light", size: 17)!]
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
