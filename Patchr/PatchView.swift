//
//  PatchCell.swift
//  Patchr
//
//  Created by Jay Massena on 10/17/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import SDWebImage

class PatchView: BaseView {

	var name			= UILabel()
	var photo			= AirImageView(frame: CGRect.zero)
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
		
		self.layer.backgroundColor = Theme.colorBackgroundTile.cgColor
		
		/* Patch photo */
		self.photo.contentMode = UIViewContentMode.scaleAspectFill
		self.photo.clipsToBounds = true
		self.photo.isUserInteractionEnabled = true
		self.photo.backgroundColor = Colors.gray80pcntColor
		self.photo.sizeCategory = SizeCategory.thumbnail
		self.addSubview(self.photo)
		
		/* Patch name */
		self.name.font = Theme.fontTitle
		self.name.numberOfLines = 2
		self.addSubview(self.name)
		
		/* Patch type */
		self.type.font = Theme.fontCommentSmall
		self.type.textColor = Theme.colorTextSecondary
		self.addSubview(self.type)
		
		/* Patch visibility */
		self.visibility.image = UIImage(named: "imgLockLight")
		self.visibility.contentMode = UIViewContentMode.scaleToFill
		self.visibility.clipsToBounds = true
		self.visibility.tintColor = Colors.accentColorFill
		self.visibility.isHidden = true
		self.addSubview(self.visibility)
		
		/* Patch status */
		self.status.text = "REQUESTED"
		self.status.isHidden = true
		self.status.font = Theme.fontCommentSmall
		self.status.textColor = Theme.colorTint
		self.addSubview(self.status)
		
		/* Message count */
		self.messageCount.textAlignment = .center
		self.messageCount.lineBreakMode = .byTruncatingMiddle
		self.messageCount.font = Theme.fontNumberFeatured
		self.messageCount.textColor = Theme.colorNumberFeatured
		self.messagesGroup.addSubview(self.messageCount)
		
		/* Message label */
		self.messageLabel.text = "MESSAGES"
		self.messageLabel.textAlignment = .center
		self.messageLabel.font = Theme.fontCommentExtraSmall
		self.messageLabel.textColor = Theme.colorTextSecondary
		self.messagesGroup.addSubview(self.messageLabel)
		self.addSubview(self.messagesGroup)
		
		/* Watching count */
		self.watchingCount.textAlignment = .center
		self.watchingCount.font = Theme.fontNumberFeatured
		self.watchingCount.textColor = Theme.colorNumberFeatured
		self.watchingGroup.addSubview(self.watchingCount)
		
		/* Watching label */
		self.watchingLabel.text = "MEMBERS"
		self.watchingLabel.textAlignment = .center
		self.watchingLabel.font = Theme.fontCommentExtraSmall
		self.watchingLabel.textColor = Theme.colorTextSecondary
		self.watchingGroup.addSubview(self.watchingLabel)
		self.addSubview(self.watchingGroup)
		
		/* Distance */
		self.distance.font = Theme.fontCommentSmall
		self.distance.textColor = Colors.white
		self.addSubview(self.distance)
		
		/* Rule */
		self.rule.layer.backgroundColor = Theme.colorRule.cgColor
		self.addSubview(self.rule)
		
		/* Shadow */
		self.shadow.layer.backgroundColor = Theme.colorShadow.cgColor
		self.addSubview(self.shadow)
	}
	
	override func bindToEntity(entity: AnyObject, location: CLLocation?) {
		
		let entity = entity as! Entity
		
		self.entity = entity
		
		self.name.text = entity.name
		if entity.type != nil {
			self.type.text = entity.type.uppercased() + " PATCH"
		}
		
		if let patch = entity as? Patch {
			
			self.messagesGroup.isHidden = false
			self.watchingGroup.isHidden = false
			self.rule.isHidden = false
			
			self.visibility.isHidden = (patch.visibility != nil && patch.visibility == "public")
			self.status.isHidden = true
			if (patch.userWatchStatusValue == .pending && !SCREEN_NARROW) {
				self.status.isHidden = false
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
			self.messagesGroup.isHidden = true
			self.watchingGroup.isHidden = true
			self.rule.isHidden = true
		}
		
		/* Distance */
		if location == nil {
			self.distance.isHidden = true
		}
		else {
			self.distance.isHidden = false
			self.distance.text = "--"
			if let loc = entity.location {
				let patchLocation = CLLocation(latitude: loc.latValue, longitude: loc.lngValue)
				let dist = Float(location!.distance(from: patchLocation))  // in meters
				self.distance.text = LocationController.instance.distancePretty(meters: dist)
			}
		}
		
		self.photo.backgroundColor = Colors.gray80pcntColor

		if entity.photo != nil {
			let photoUrl = PhotoUtils.url(prefix: entity.photo!.prefix!, source: entity.photo!.source!, category: SizeCategory.profile)
			bindPhoto(photoUrl: photoUrl, name: entity.name)
		}
		else {
			bindPhoto(photoUrl: nil, name: entity.name)
		}

		self.setNeedsLayout()
	}
	
	private func bindPhoto(photoUrl: URL?, name: String?) {
		
		if self.photo.image != nil
			&& self.photo.linkedPhotoUrl != nil
			&& photoUrl != nil
			&& self.photo.linkedPhotoUrl?.absoluteString == photoUrl?.absoluteString {
			return
		}

		self.photo.image = nil
		
		if photoUrl != nil {
			self.photo.setImageWithUrl(url: photoUrl!, animate: false)
			self.photo.showGradient = true
		}
		else if name != nil {
			let seed = Utils.numberFromName(fullname: name!)
			self.photo.backgroundColor = Utils.randomColor(seed: seed)
			self.photo.showGradient = true
		}
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		
		self.shadow.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 1)
		
		let columnLeft = CGFloat(128 + 8)
		let columnWidth = self.width() - columnLeft
        let nameSize = self.name.sizeThatFits(CGSize(width: columnWidth, height: CGFloat.greatestFiniteMagnitude))
		
		self.photo.anchorTopLeft(withLeftPadding: 0, topPadding: 0, width: 128, height: 128)
		self.name.anchorTopLeft(withLeftPadding: columnLeft, topPadding: 6, width: columnWidth, height: nameSize.height)
		
		self.type.sizeToFit()
		self.type.alignUnder(self.name, matchingLeftWithTopPadding: 0, width: self.type.width(), height: 16)
		if !self.visibility.isHidden {
			self.visibility.align(toTheRightOf: self.type, matchingCenterWithLeftPadding: 8, width: 16, height: 16)
			if !self.status.isHidden {
				self.status.sizeToFit()
				self.status.align(toTheRightOf: self.visibility, matchingCenterWithLeftPadding: 8, width: columnWidth - (self.status.width() + self.visibility.width() + 16), height: self.status.height())
			}
		}
		else if !self.status.isHidden {
			self.status.sizeToFit()
			self.status.align(toTheRightOf: self.type, matchingCenterWithLeftPadding: 8, width: columnWidth - (self.status.width() + 8), height: self.status.height())
		}
		
		self.messagesGroup.anchorBottomLeft(withLeftPadding: columnLeft, bottomPadding: 8, width: 72, height: 48)
		self.rule.align(toTheRightOf: self.messagesGroup, matchingBottomWithLeftPadding: 8, width: 1, height: 40)
		self.watchingGroup.align(toTheRightOf: self.rule, matchingBottomWithLeftPadding: 8, width: 72, height: 48)
		
		self.messageLabel.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 4, bottomPadding: 0, height: 15)
		self.messageCount.align(above: self.messageLabel, fillingWidthWithLeftAndRightPadding: 0, bottomPadding: 0, height: 32)
		self.watchingLabel.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 4, bottomPadding: 0, height: 15)
		self.watchingCount.align(above: self.watchingLabel, fillingWidthWithLeftAndRightPadding: 0, bottomPadding: 0, height: 32)
		
		if self.distance.text != nil {
			self.distance.anchorBottomLeft(withLeftPadding: 8, bottomPadding: 8, width: 112, height: 16)
		}
	}
}
