//
//  PatchCell.swift
//  Patchr
//
//  Created by Jay Massena on 10/17/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class PatchView: BaseView {

	var name			= UILabel()
	var photo			= AirImageView(frame: CGRectZero)
	var type			= UILabel()
	var visibility		= UIImageView()
	var status			= UILabel()
	var messageCount	= UILabel()
	var watchingCount	= UILabel()
	var messageLabel	= UILabel()
	var watchingLabel	= UILabel()
	var distance		= UILabel()
	var rule			= UIView()
	var shadow			= UIView()
	var messagesGroup	= UIView()
	var watchingGroup	= UIView()
	
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
		
		self.layer.backgroundColor = Theme.colorBackgroundTile.CGColor
		
		/* Patch photo */
		self.photo.contentMode = UIViewContentMode.ScaleAspectFill
		self.photo.clipsToBounds = true
		self.photo.userInteractionEnabled = true
		self.photo.backgroundColor = Colors.gray95pcntColor
		self.photo.sizeCategory = SizeCategory.thumbnail
		self.addSubview(self.photo)
		
		/* Patch name */
		self.name.font = UIFont(name: "HelveticaNeue-Light", size: 22)
		self.name.numberOfLines = 2
		self.addSubview(self.name)
		
		/* Patch type */
		self.type.font = UIFont(name: "HelveticaNeue-Light", size: 13)
		self.type.textColor = Colors.secondaryText
		self.addSubview(self.type)
		
		/* Patch visibility */
		self.visibility.image = UIImage(named: "imgLockLight")
		self.visibility.contentMode = UIViewContentMode.ScaleToFill
		self.visibility.clipsToBounds = true
		self.visibility.tintColor(Colors.brandColor)
		self.addSubview(self.visibility)
		
		/* Patch status */
		self.status.text = "REQUESTED"
		self.status.hidden = true
		self.status.font = UIFont(name: "HelveticaNeue-Light", size: 13)
		self.status.textColor = Colors.brandColor
		self.addSubview(self.status)
		
		/* Message count */
		self.messageCount.textAlignment = .Center
		self.messageCount.lineBreakMode = .ByTruncatingMiddle
		self.messageCount.font = UIFont(name: "HelveticaNeue-Light", size: 30)
		self.messageCount.textColor = Colors.accentColor
		self.messagesGroup.addSubview(self.messageCount)
		
		/* Message label */
		self.messageLabel.text = "MESSAGES"
		self.messageLabel.textAlignment = .Center
		self.messageLabel.font = UIFont(name: "HelveticaNeue-Light", size: 12)
		self.messageLabel.textColor = Colors.secondaryText
		self.messagesGroup.addSubview(self.messageLabel)
		self.addSubview(self.messagesGroup)
		
		/* Watching count */
		self.watchingCount.textAlignment = .Center
		self.watchingCount.font = UIFont(name: "HelveticaNeue-Light", size: 30)
		self.watchingCount.textColor = Colors.accentColor
		self.watchingGroup.addSubview(self.watchingCount)
		
		/* Watching label */
		self.watchingLabel.text = "WATCHING"
		self.watchingLabel.textAlignment = .Center
		self.watchingLabel.font = UIFont(name: "HelveticaNeue-Light", size: 12)
		self.watchingLabel.textColor = Colors.secondaryText
		self.watchingGroup.addSubview(self.watchingLabel)
		self.addSubview(self.watchingGroup)
		
		/* Distance */
		self.distance.font = Theme.fontCommentSmall
		self.distance.textColor = Colors.white
		self.addSubview(self.distance)
		
		/* Rule */
		self.rule.layer.backgroundColor = Colors.lightGray.CGColor
		self.addSubview(self.rule)
		
		/* Shadow */
		self.shadow.layer.backgroundColor = Colors.gray80pcntColor.CGColor
		self.addSubview(self.shadow)
	}
	
	func bindToEntity(entity: AnyObject, location: CLLocation?) {
		
		let entity = entity as! Entity
		
		self.entity = entity
		
		self.name.text = entity.name
		if entity.type != nil {
			self.type.text = entity.type.uppercaseString + " PATCH"
		}
		
		if let patch = entity as? Patch {
			
			self.messagesGroup.hidden = false
			self.watchingGroup.hidden = false
			self.rule.hidden = false
			
			self.visibility.hidden = (patch.visibility == "public")
			self.status.hidden = true
			if (patch.userWatchStatusValue == .Pending && !SCREEN_NARROW) {
				self.status.hidden = false
			}
			
			self.messageCount.text = "--"
			self.watchingCount.text = "--"
			
			if let numberOfMessages = patch.countMessages {
				self.messageCount.text = numberOfMessages.stringValue
			}
			
			if let numberOfWatching = patch.countWatching {
				self.watchingCount.text = numberOfWatching.stringValue
			}
		}
		else {
			/* This is a shortcut with a subset of the info */
			self.messagesGroup.hidden = true
			self.watchingGroup.hidden = true
			self.rule.hidden = true
		}
		
		/* Distance */
		if location == nil {
			self.distance.hidden = true
		}
		else {
			self.distance.hidden = false
			self.distance.text = "--"
			if let loc = entity.location {
				let patchLocation = CLLocation(latitude: loc.latValue, longitude: loc.lngValue)
				let dist = Float(location!.distanceFromLocation(patchLocation))  // in meters
				self.distance.text = LocationController.instance.distancePretty(dist)
			}
		}
		
		self.photo.showGradient = true
		self.photo.setImageWithPhoto(entity.getPhotoManaged(), animate: self.photo.image == nil)
		self.setNeedsLayout()
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		self.shadow.anchorBottomCenterFillingWidthWithLeftAndRightPadding(0, bottomPadding: 0, height: 1)
		
		let columnLeft = 128 + CELL_VIEW_SPACING
		let columnWidth = self.width() - (columnLeft + CELL_PADDING_HORIZONTAL)
		let nameSize = self.name.sizeThatFits(CGSizeMake(columnWidth, CGFloat.max))
		
		self.photo.anchorTopLeftWithLeftPadding(0, topPadding: 0, width: 128, height: 128)
		self.name.anchorTopLeftWithLeftPadding(columnLeft, topPadding: 6, width: columnWidth, height: nameSize.height)
		
		self.type.sizeToFit()
		self.type.alignUnder(self.name, matchingLeftWithTopPadding: 0, width: self.type.frame.size.width, height: 16)
		if !self.visibility.hidden {
			self.visibility.alignToTheRightOf(self.type, matchingCenterWithLeftPadding: 8, width: 16, height: 16)
			if !self.status.hidden {
				self.status.alignToTheRightOf(self.visibility, matchingCenterAndFillingWidthWithLeftAndRightPadding: 8, height: 16)
			}
		}
		else if !self.status.hidden {
			self.status.alignToTheRightOf(self.type, matchingCenterAndFillingWidthWithLeftAndRightPadding: 8, height: 16)
		}
		
		self.messagesGroup.anchorBottomLeftWithLeftPadding(columnLeft, bottomPadding: 8, width: 72, height: 48)
		self.rule.alignToTheRightOf(self.messagesGroup, matchingBottomWithLeftPadding: 8, width: 1, height: 40)
		self.watchingGroup.alignToTheRightOf(self.rule, matchingBottomWithLeftPadding: 8, width: 72, height: 48)
		
		self.messageLabel.anchorBottomCenterFillingWidthWithLeftAndRightPadding(4, bottomPadding: 0, height: 15)
		self.messageCount.alignAbove(self.messageLabel, fillingWidthWithLeftAndRightPadding: 0, bottomPadding: 0, height: 32)
		self.watchingLabel.anchorBottomCenterFillingWidthWithLeftAndRightPadding(4, bottomPadding: 0, height: 15)
		self.watchingCount.alignAbove(self.watchingLabel, fillingWidthWithLeftAndRightPadding: 0, bottomPadding: 0, height: 32)
		
		if self.distance.text != nil {
			self.distance.anchorBottomLeftWithLeftPadding(8, bottomPadding: 8, width: 112, height: 16)
		}
	}
}