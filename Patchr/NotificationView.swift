//
//  NotificationCellTableViewCell.swift
//  Patchr
//
//  Created by Jay Massena on 10/14/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class NotificationView: BaseView {
	
	var cellType: CellType = .TextAndPhoto
	
	var description_:	TTTAttributedLabel?
	var photo:			UIButton?
	
	var userPhoto		= UIImageView(frame: CGRectZero)
	var iconImageView	= UIImageView(frame: CGRectZero)
	var ageDot			= UIView()
	var createdDate		= UILabel()
	
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
		
		self.clipsToBounds = true
		
		/* Description */
		if self.cellType != .Photo {
			self.description_ = TTTAttributedLabel(frame: CGRectZero)
			self.description_!.numberOfLines = 5
			self.description_!.lineBreakMode = .ByTruncatingTail
			self.description_!.font = UIFont(name: "HelveticaNeue-Light", size: 17)
			self.addSubview(self.description_!)
		}
		
		/* Photo */
		if self.cellType != .Text {
			self.photo = AirImageButton(frame: CGRectZero)
			self.photo!.imageView!.contentMode = UIViewContentMode.ScaleAspectFill
			self.photo!.backgroundColor = Colors.windowColor
			self.photo!.clipsToBounds = true
			self.photo!.userInteractionEnabled = true
			self.addSubview(self.photo!)
		}
		
		/* User photo */
		self.userPhoto.contentMode = UIViewContentMode.ScaleAspectFill
		self.userPhoto.clipsToBounds = true
		self.userPhoto.layer.cornerRadius = 24
		self.addSubview(self.userPhoto)
		
		/* Footer */
		self.createdDate.font = UIFont(name: "HelveticaNeue-Light", size: 15)
		self.createdDate.textColor = Colors.secondaryText
		self.ageDot.layer.cornerRadius = 6
		
		self.addSubview(self.iconImageView)
		self.addSubview(self.createdDate)
		self.addSubview(self.ageDot)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		let columnLeft = CELL_USER_PHOTO_SIZE + CELL_VIEW_SPACING + (CELL_PADDING_HORIZONTAL * 2)
		let columnWidth = self.width() - columnLeft
		let photoHeight = columnWidth * CELL_PHOTO_RATIO
		
		self.userPhoto.anchorTopLeftWithLeftPadding(CELL_PADDING_HORIZONTAL, topPadding: CELL_PADDING_VERTICAL, width: CELL_USER_PHOTO_SIZE, height: CELL_USER_PHOTO_SIZE)
		
		var bottomView: UIView? = self.photo
		
		if self.cellType == .TextAndPhoto {
			let descSize = self.description_?.sizeThatFits(CGSizeMake(columnWidth, CGFloat.max))
			self.description_?.alignToTheRightOf(self.userPhoto, fillingWidthWithLeftAndRightPadding: CELL_PADDING_HORIZONTAL, topPadding: CELL_PADDING_VERTICAL, height: (descSize?.height)!)
			self.photo?.alignUnder(self.description_!, matchingLeftAndFillingWidthWithRightPadding: CELL_PADDING_HORIZONTAL, topPadding: CELL_VIEW_SPACING, height: photoHeight)
		}
		else if self.cellType == .Photo {
			self.photo?.alignToTheRightOf(self.userPhoto, fillingWidthWithLeftAndRightPadding: CELL_PADDING_HORIZONTAL, topPadding: CELL_PADDING_VERTICAL, height: photoHeight)
		}
		else if self.cellType == .Text {
			bottomView = self.description_
			let descSize = self.description_?.sizeThatFits(CGSizeMake(columnWidth, CGFloat.max))
			self.description_?.alignToTheRightOf(self.userPhoto, fillingWidthWithLeftAndRightPadding: CELL_PADDING_HORIZONTAL, topPadding: CELL_PADDING_VERTICAL, height: (descSize?.height)!)
		}
		
		self.iconImageView.alignUnder(bottomView!, matchingLeftWithTopPadding: CELL_VIEW_SPACING, width: CELL_FOOTER_HEIGHT, height: CELL_FOOTER_HEIGHT)
		self.createdDate.alignToTheRightOf(self.iconImageView, matchingCenterAndFillingWidthWithLeftAndRightPadding: CELL_PADDING_HORIZONTAL, height: CELL_FOOTER_HEIGHT)
	}
	
	override func prepareForRecycle() {	}	
}

enum CellType: String {
	case Text = "text"
	case Photo = "photo"
	case TextAndPhoto = "text_and_photo"
}
