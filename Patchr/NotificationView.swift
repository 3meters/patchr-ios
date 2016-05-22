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
	
	var description_	: TTTAttributedLabel?
	var photo			: AirImageView?
	var hasPhoto		= false
	
	var userPhoto		= UserPhotoView()
	var iconImageView	= UIImageView(frame: CGRectZero)
	var ageDot			= UIView()
	var createdDate		= AirLabelDisplay()
	
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
	
	/*--------------------------------------------------------------------------------------------
	* Events
	*--------------------------------------------------------------------------------------------*/
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		let columnLeft = CGFloat(48 + 8)
		let columnWidth = self.bounds.size.width - columnLeft
		let photoHeight = columnWidth * 0.5625		// 16:9 aspect ratio
		
		self.userPhoto.anchorTopLeftWithLeftPadding(0, topPadding: 0, width: 48, height: 48)
		
		var bottomView: UIView? = self.photo
		if !self.hasPhoto {	// Text only
			bottomView = self.description_
			self.description_?.bounds.size.width = columnWidth
			self.description_?.sizeToFit()
			self.description_?.alignToTheRightOf(self.userPhoto, matchingTopWithLeftPadding: 8, width: columnWidth, height: self.description_!.height())
		}
		else if self.entity?.description_ == nil { // Photo only
			self.photo?.alignToTheRightOf(self.userPhoto, matchingTopWithLeftPadding: 8, width: columnWidth, height: photoHeight)
		}
		else { // Text and photo
			self.description_?.bounds.size.width = columnWidth
			self.description_?.sizeToFit()
			self.description_?.alignToTheRightOf(self.userPhoto, matchingTopWithLeftPadding: 8, width: columnWidth, height: self.description_!.height())
			self.photo?.alignUnder(self.description_!, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 12, height: photoHeight)
		}
		
		self.createdDate.sizeToFit()
		self.iconImageView.alignUnder(bottomView!, matchingLeftWithTopPadding: 8, width: self.iconImageView.width(), height: self.iconImageView.height())
		self.createdDate.alignToTheRightOf(self.iconImageView, matchingCenterWithLeftPadding: 8, width: self.createdDate.width(), height: self.createdDate.height())
		self.ageDot.alignUnder(bottomView!, matchingRightWithTopPadding: 8, width: 12, height: 12)
	}
	
	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		
		self.clipsToBounds = false
		
		/* Description */
		self.description_ = TTTAttributedLabel(frame: CGRectZero)
		self.description_!.numberOfLines = 5
		self.description_!.font = Theme.fontTextList
		self.addSubview(self.description_!)
		
		/* Photo: give initial size in case the image displays before call to layoutSubviews		 */
		let columnLeft = CGFloat(48 + 8)
		let columnWidth = self.bounds.size.width - columnLeft
		let photoHeight = columnWidth * 0.5625		// 16:9 aspect ratio
		
		self.photo = AirImageView(frame: CGRectMake(0, 0, columnWidth, photoHeight))
		self.photo!.clipsToBounds = true
		self.photo!.contentMode = .ScaleAspectFill
		self.photo!.backgroundColor = Theme.colorBackgroundImage
		
		self.addSubview(self.photo!)
		
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
	
	override func bindToEntity(entity: AnyObject, location: CLLocation?) {
		
		let notification = entity as! Notification
		
		self.entity = notification
		self.hasPhoto = (notification.photoBig != nil)
		
		let linkColor = Theme.colorTint
		let linkActiveColor = Theme.colorTint
		
		self.description_?.linkAttributes = [kCTForegroundColorAttributeName : linkColor]
		self.description_?.activeLinkAttributes = [kCTForegroundColorAttributeName : linkActiveColor]
		self.description_?.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue|NSTextCheckingType.Address.rawValue
		
		if let description = notification.summary {
			let attributed = Utils.convertText(description, font: UIFont(name: "HelveticaNeue-Light", size: 16)!)
			self.description_?.attributedText = attributed
		}
		
		if let photo = notification.photoBig {
			self.photo?.hidden = false
			let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!, category: SizeCategory.standard)
			bindPhoto(photoUrl)
		}
		else {
			self.photo?.hidden = true
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
	
	private func bindPhoto(photoUrl: NSURL) {
		
		if self.photo?.image != nil
			&& self.photo!.linkedPhotoUrl != nil
			&& self.photo!.linkedPhotoUrl?.absoluteString == photoUrl.absoluteString {
			return
		}
		
		self.photo?.image = nil
		self.photo!.setImageWithUrl(photoUrl, animate: false)
	}	
}