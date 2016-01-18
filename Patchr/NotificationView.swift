//
//  NotificationCellTableViewCell.swift
//  Patchr
//
//  Created by Jay Massena on 10/14/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import SDWebImage

class NotificationView: BaseView {
	
	var cellType: CellType = .TextAndPhoto
	
	var description_:	TTTAttributedLabel?
	var photo:			UIButton?
	
	var userPhoto		= UserPhotoView()
	var iconImageView	= UIImageView(frame: CGRectZero)
	var ageDot			= UIView()
	var createdDate		= AirLabelDisplay()
	
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
			self.description_!.font = Theme.fontTextList
			self.addSubview(self.description_!)
		}
		
		/* Photo */
		if self.cellType != .Text {
			self.photo = AirImageButton(frame: CGRectZero)
			self.photo!.imageView!.contentMode = UIViewContentMode.ScaleAspectFill
			self.photo!.contentMode = .ScaleAspectFill
			self.photo!.contentHorizontalAlignment = .Fill
			self.photo!.contentVerticalAlignment = .Fill
			self.photo!.backgroundColor = Theme.colorBackgroundImage
			self.addSubview(self.photo!)
		}
		
		/* User photo */
		self.addSubview(self.userPhoto)
		
		/* Footer */
		self.createdDate.font = Theme.fontComment
		self.createdDate.textColor = Theme.colorTextSecondary
		self.iconImageView.bounds.size = CGSizeMake(20, 20)
		self.iconImageView.tintColor = Colors.accentColorFill
		
		self.ageDot.layer.cornerRadius = 6
		
		self.addSubview(self.iconImageView)
		self.addSubview(self.createdDate)
		self.addSubview(self.ageDot)
	}
	
	func bindToEntity(entity: AnyObject) {
		
		let notification = entity as! Notification
		
		self.entity = notification
		
		let linkColor = Theme.colorTint
		let linkActiveColor = Theme.colorTint
		
		self.description_?.linkAttributes = [kCTForegroundColorAttributeName : linkColor]
		self.description_?.activeLinkAttributes = [kCTForegroundColorAttributeName : linkActiveColor]
		self.description_?.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue|NSTextCheckingType.Address.rawValue
		
		if let description = notification.summary {
			self.description_?.text = description
		}
		
		let options: SDWebImageOptions = [.RetryFailed, .LowPriority,  .ProgressiveDownload]
		
		if let photo = notification.photoBig {
			let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!, category: SizeCategory.standard)
			self.photo?.sd_setImageWithURL(photoUrl, forState: UIControlState.Normal, placeholderImage: nil, options: options)
		}
		
		/* User photo */
		
		self.userPhoto.bindToEntity(notification)
		
		self.createdDate.text = UIShared.timeAgoMedium(notification.sortDate)
		
		/* Age indicator */
		self.ageDot.layer.backgroundColor = Theme.colorBackgroundAgeDot.CGColor
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
		
		self.setNeedsLayout()	// Needed because binding can change the layout
	}
	
	override func sizeThatFits(size: CGSize) -> CGSize {
		
		if let entity = self.entity as? Notification {
			
			var heightAccum = CGFloat(0)
			
			let columnLeft = CGFloat(48 + 8)
			let columnWidth = size.width - columnLeft
			let photoHeight = columnWidth * 0.5625
			
			if entity.summary != nil && !entity.summary.isEmpty {
				self.description_!.bounds.size.width = columnWidth
				self.description_!.sizeToFit()
				heightAccum += self.description_!.height()
			}
			
			if entity.photoBig != nil {
				heightAccum += (8 + photoHeight)
			}
			
			self.createdDate.sizeToFit()
			heightAccum += (8 + max(self.iconImageView.height(), self.createdDate.height())) // Like button
			
			let height = max(self.userPhoto.height(), heightAccum)
			
			return CGSizeMake(size.width, height)
		}
		
		return CGSizeZero
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		let columnLeft = CGFloat(48 + 8)
		let columnWidth = self.bounds.size.width - columnLeft
		let photoHeight = columnWidth * 0.5625		// 16:9 aspect ratio
		
		self.userPhoto.anchorTopLeftWithLeftPadding(0, topPadding: 0, width: 48, height: 48)
		
		var bottomView: UIView? = self.photo
		if self.cellType == .Text {
			bottomView = self.description_
			self.description_?.bounds.size.width = columnWidth
			self.description_?.sizeToFit()
			self.description_?.alignToTheRightOf(self.userPhoto, matchingTopWithLeftPadding: 8, width: columnWidth, height: self.description_!.height())
		}
		else if self.cellType == .TextAndPhoto {
			self.description_?.bounds.size.width = columnWidth
			self.description_?.sizeToFit()
			self.description_?.alignToTheRightOf(self.userPhoto, matchingTopWithLeftPadding: 8, width: columnWidth, height: self.description_!.height())
			self.photo?.alignUnder(self.description_!, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 8, height: photoHeight)
		}
		else if self.cellType == .Photo {
			self.photo?.alignToTheRightOf(self.userPhoto, matchingTopWithLeftPadding: 8, width: columnWidth, height: photoHeight)
		}
		
		self.createdDate.sizeToFit()
		self.iconImageView.alignUnder(bottomView!, matchingLeftWithTopPadding: 8, width: self.iconImageView.width(), height: self.iconImageView.height())
		self.createdDate.alignToTheRightOf(self.iconImageView, matchingCenterWithLeftPadding: 8, width: self.createdDate.width(), height: self.createdDate.height())
	}
	
	override func prepareForRecycle() {	}	
}