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
		self.userPhoto.layer.backgroundColor = Colors.windowColor.CGColor
		self.addSubview(self.userPhoto)
		
		/* Footer */
		self.createdDate.font = UIFont(name: "HelveticaNeue-Light", size: 15)
		self.createdDate.textColor = Colors.secondaryText
		self.ageDot.layer.cornerRadius = 6
		
		self.addSubview(self.iconImageView)
		self.addSubview(self.createdDate)
		self.addSubview(self.ageDot)
	}
	
	func bindToEntity(entity: AnyObject) {
		
		let notification = entity as! Notification
		
		self.entity = notification
		
		if let description = notification.summary {
			self.description_?.text = description
		}
		
		let linkColor = Colors.brandColorDark
		let linkActiveColor = Colors.brandColorLight
		
		self.description_?.linkAttributes = [kCTForegroundColorAttributeName : linkColor]
		self.description_?.activeLinkAttributes = [kCTForegroundColorAttributeName : linkActiveColor]
		self.description_?.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue|NSTextCheckingType.Address.rawValue
		
		let options: SDWebImageOptions = [.RetryFailed, .LowPriority,  .ProgressiveDownload]
		
		if let photo = notification.photoBig {
			let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!, category: SizeCategory.standard)
			self.photo?.sd_setImageWithURL(photoUrl, forState: UIControlState.Normal, placeholderImage: nil, options: options)
		}
		
		let photo = notification.getPhotoManaged()
		let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!, category: SizeCategory.profile)
		self.userPhoto.sd_setImageWithURL(photoUrl, placeholderImage: nil, options: options)
		
		self.createdDate.text = Utils.messageDateFormatter.stringFromDate(notification.createdDate)
		
		/* Age indicator */
		self.ageDot.layer.backgroundColor = Colors.accentColor.CGColor
		let now = NSDate()
		
		/* Age of notification in hours */
		let interval = Int(now.timeIntervalSinceDate(NSDate(timeIntervalSince1970: notification.createdDate.timeIntervalSince1970)) / 3600)
		if interval > 12 {
			self.ageDot.alpha = 0.0
		}
		else if interval > 1 {
			self.ageDot.alpha = 0.25
		}
		else {
			self.ageDot.alpha = 1.0
		}
		
		/* Type indicator image */
		if notification.type == "media" {
			self.iconImageView.image = Utils.imageMedia
		}
		else if notification.type == "message" {
			self.iconImageView.image = Utils.imageMessage
		}
		else if notification.type == "watch" {
			self.iconImageView.image = Utils.imageWatch
		}
		else if notification.type == "like" {
			if notification.targetId.hasPrefix("pa.") {
				self.iconImageView.image = Utils.imageStar
			}
			else {
				self.iconImageView.image = Utils.imageLike
			}
		}
		else if notification.type == "share" {
			self.iconImageView.image = Utils.imageShare
		}
		else if notification.type == "nearby" {
			self.iconImageView.image = Utils.imageLocation
		}
		self.iconImageView.tintColor(Colors.brandColor)
		
		self.setNeedsLayout()
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
