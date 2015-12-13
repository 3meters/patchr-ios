//
//  UserDetailView.swift
//  Patchr
//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class UserDetailView: BaseDetailView {

	var name			= AirLabelTitle()
	var photo			= AirImageView(frame: CGRectZero)
	var email			= UILabel()
	var rule			= UIView()
	var userGroup		= UIView()
	var favoritesGroup	= UIView()
	var watchingGroup	= UIView()
	var ownsGroup		= UIView()
	var favoritesIcon	= UIImageView()
	var watchingIcon	= UIImageView()
	var ownsIcon		= UIImageView()
	var favoritesInfo	= UIButton()
	var watchingInfo	= UIButton()
	var ownsInfo		= UIButton()
	var favoritesRule	= UIView()
	var watchingRule	= UIView()
	var ownsRule		= UIView()
	
	init() {
		super.init(frame: CGRectZero)
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
		self.backgroundColor = Theme.colorBackgroundScreen
		
		/* User photo */
		self.photo.contentMode = UIViewContentMode.ScaleAspectFill
		self.photo.clipsToBounds = true
		self.photo.layer.cornerRadius = 48
		self.photo.layer.backgroundColor = Theme.colorBackgroundImage.CGColor
		self.photo.sizeCategory = SizeCategory.profile
		
		/* User name */
		self.name.lineBreakMode = .ByTruncatingMiddle
		self.name.font = Theme.fontTitle
		
		/* User email */
		self.email.font = Theme.fontTextDisplay
		self.email.textColor = Theme.colorTextSecondary
	
		/* Rule */
		self.rule.backgroundColor = Theme.colorSeparator
		
		self.userGroup.addSubview(self.photo)
		self.userGroup.addSubview(self.name)
		self.userGroup.addSubview(self.email)
		self.userGroup.addSubview(self.rule)
		self.addSubview(self.userGroup)
		
		/* Watching */
		self.watchingIcon.image = UIImage(named: "imgWatchLight")
		self.watchingIcon.alpha = 0.5
		self.watchingIcon.tintColor = Colors.black
		self.watchingInfo.setTitleColor(Theme.colorTint, forState: .Normal)
		self.watchingInfo.titleLabel!.font = Theme.fontHeading3
		self.watchingInfo.contentHorizontalAlignment = .Left
		self.watchingRule.backgroundColor = Theme.colorSeparator
		
		self.watchingGroup.addSubview(self.watchingIcon)
		self.watchingGroup.addSubview(self.watchingInfo)
		self.watchingGroup.addSubview(self.watchingRule)
		
		/* Owns */
		self.ownsIcon.image = UIImage(named: "imgEditLight")
		self.ownsIcon.alpha = 0.5
		self.ownsIcon.tintColor = Colors.black
		self.ownsInfo.setTitleColor(Theme.colorTint, forState: .Normal)
		self.ownsInfo.titleLabel!.font = Theme.fontHeading3
		self.ownsInfo.contentHorizontalAlignment = .Left
		self.ownsRule.backgroundColor = Theme.colorSeparator
		
		self.ownsGroup.addSubview(self.ownsIcon)
		self.ownsGroup.addSubview(self.ownsInfo)
		self.ownsGroup.addSubview(self.ownsRule)
		
		//self.addSubview(self.favoritesGroup)
		self.addSubview(self.watchingGroup)
		self.addSubview(self.ownsGroup)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		self.userGroup.anchorTopCenterFillingWidthWithLeftAndRightPadding(0, topPadding: 0, height: 112)
		self.photo.anchorTopLeftWithLeftPadding(8, topPadding: 8, width: 96, height: 96)
		self.name.alignToTheRightOf(self.photo, fillingWidthWithLeftAndRightPadding: 12, topPadding: 12, height: 36)
		self.email.alignUnder(self.name, matchingLeftAndFillingWidthWithRightPadding: 12, topPadding: 0, height: 24)
		self.rule.anchorBottomCenterFillingWidthWithLeftAndRightPadding(0, bottomPadding: 0, height: 1)
		
		self.watchingGroup.alignUnder(self.userGroup, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 0, height: 48)
		self.watchingIcon.anchorCenterLeftWithLeftPadding(24, width: 24, height: 24)
		self.watchingInfo.alignToTheRightOf(self.watchingIcon, matchingCenterAndFillingWidthWithLeftAndRightPadding: 20, height: 24)
		self.watchingRule.anchorBottomCenterFillingWidthWithLeftAndRightPadding(0, bottomPadding: 0, height: 1)
		
		self.ownsGroup.alignUnder(self.watchingGroup, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 0, height: 48)
		self.ownsIcon.anchorCenterLeftWithLeftPadding(24, width: 24, height: 24)
		self.ownsInfo.alignToTheRightOf(self.ownsIcon, matchingCenterAndFillingWidthWithLeftAndRightPadding: 20, height: 24)
		self.ownsRule.anchorBottomCenterFillingWidthWithLeftAndRightPadding(0, bottomPadding: 0, height: 1)		
	}
	
	func bindToEntity(user: User?, isGuest: Bool) {
		
		self.name.text?.removeAll(keepCapacity: false)
		self.email.text?.removeAll(keepCapacity: false)
		
		if isGuest {
			self.name.text = "Guest"
			self.email.text = "discover@3meters.com"
			self.photo.image = UIImage(named: "imgDefaultUser")
			self.watchingInfo.setTitle("Watching: --", forState: .Normal)
			self.ownsInfo.setTitle("Owner: --", forState: .Normal)
			self.favoritesInfo.setTitle("Favorites: --", forState: .Normal)
		}
		else {
			if let entity = user {
				self.name.text = entity.name
				self.email.text = entity.email
				self.photo.setImageWithPhoto(entity.getPhotoManaged(), animate: false)
				
				if entity.patchesWatching != nil {
					let count = entity.patchesWatchingValue == 0 ? "--" : String(entity.patchesWatchingValue)
					self.watchingInfo.setTitle("Watching: \(count)", forState: .Normal)
				}
				if entity.patchesOwned != nil {
					let count = entity.patchesOwnedValue == 0 ? "--" : String(entity.patchesOwnedValue)
					self.ownsInfo.setTitle("Owner: \(count)", forState: .Normal)
				}
			}
		}
		self.setNeedsLayout()
		self.layoutIfNeeded()
		self.sizeToFit()
	}
}
