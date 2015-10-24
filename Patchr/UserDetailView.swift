//
//  UserDetailView.swift
//  Patchr
//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class UserDetailView: BaseDetailView {

	var name			= UILabel()
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
		self.backgroundColor = UIColor.whiteColor()
		
		/* User photo */
		self.photo.contentMode = UIViewContentMode.ScaleAspectFill
		self.photo.clipsToBounds = true
		self.photo.layer.cornerRadius = 48
		self.photo.sizeCategory = SizeCategory.profile
		
		/* User name */
		self.name.lineBreakMode = .ByTruncatingMiddle
		self.name.font = UIFont(name: "HelveticaNeue-Light", size: 20)
		
		/* User email */
		self.email.font = UIFont(name: "HelveticaNeue-Light", size: 16)
		self.email.textColor = Colors.secondaryText
	
		/* Rule */
		self.rule.backgroundColor = Colors.separatorColor
		
		self.userGroup.addSubview(self.photo)
		self.userGroup.addSubview(self.name)
		self.userGroup.addSubview(self.email)
		self.userGroup.addSubview(self.rule)
		self.addSubview(self.userGroup)
		
		/* Favorites */
		self.favoritesIcon.image = UIImage(named: "imgStarFilledLight")
		self.favoritesIcon.alpha = 0.5
		self.favoritesIcon.tintColor = UIColor.blackColor()
		self.favoritesInfo.titleLabel!.font = UIFont(name: "HelveticaNeue-Light", size: 20)
		self.favoritesInfo.setTitleColor(Colors.brandColor, forState: .Normal)
		self.favoritesInfo.contentHorizontalAlignment = .Left
		self.favoritesRule.backgroundColor = Colors.separatorColor
		
		self.favoritesGroup.addSubview(self.favoritesIcon)
		self.favoritesGroup.addSubview(self.favoritesInfo)
		self.favoritesGroup.addSubview(self.favoritesRule)
		
		/* Watching */
		self.watchingIcon.image = UIImage(named: "imgWatchLight")
		self.watchingIcon.alpha = 0.5
		self.watchingIcon.tintColor = UIColor.blackColor()
		self.watchingInfo.setTitleColor(Colors.brandColor, forState: .Normal)
		self.watchingInfo.titleLabel!.font = UIFont(name: "HelveticaNeue-Light", size: 20)
		self.watchingInfo.contentHorizontalAlignment = .Left
		self.watchingRule.backgroundColor = Colors.separatorColor
		
		self.watchingGroup.addSubview(self.watchingIcon)
		self.watchingGroup.addSubview(self.watchingInfo)
		self.watchingGroup.addSubview(self.watchingRule)
		
		/* Owns */
		self.ownsIcon.image = UIImage(named: "imgEditLight")
		self.ownsIcon.alpha = 0.5
		self.ownsInfo.setTitleColor(Colors.brandColor, forState: .Normal)
		self.ownsInfo.titleLabel!.font = UIFont(name: "HelveticaNeue-Light", size: 20)
		self.ownsInfo.contentHorizontalAlignment = .Left
		self.ownsRule.backgroundColor = Colors.separatorColor
		
		self.ownsGroup.addSubview(self.ownsIcon)
		self.ownsGroup.addSubview(self.ownsInfo)
		self.ownsGroup.addSubview(self.ownsRule)
		
		self.addSubview(self.favoritesGroup)
		self.addSubview(self.watchingGroup)
		self.addSubview(self.ownsGroup)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		self.userGroup.anchorTopCenterFillingWidthWithLeftAndRightPadding(0, topPadding: 0, height: 112)
		self.photo.anchorTopLeftWithLeftPadding(8, topPadding: 8, width: 96, height: 96)
		self.name.alignToTheRightOf(self.photo, fillingWidthWithLeftAndRightPadding: 12, topPadding: 12, height: 22)
		self.email.alignUnder(self.name, matchingLeftAndFillingWidthWithRightPadding: 12, topPadding: 2, height: 19)
		self.rule.anchorBottomCenterFillingWidthWithLeftAndRightPadding(0, bottomPadding: 0, height: 1)
		
		self.favoritesGroup.alignUnder(self.userGroup, withLeftPadding: 0, topPadding: 0, width: self.bounds.size.width, height: 48)
		self.favoritesIcon.anchorCenterLeftWithLeftPadding(24, width: 24, height: 24)
		self.favoritesInfo.alignToTheRightOf(self.favoritesIcon, matchingCenterAndFillingWidthWithLeftAndRightPadding: 20, height: 24)
		self.favoritesRule.anchorBottomCenterFillingWidthWithLeftAndRightPadding(0, bottomPadding: 0, height: 1)
		
		self.watchingGroup.alignUnder(self.favoritesGroup, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 0, height: 48)
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
				if entity.patchesLikes != nil {
					let count = entity.patchesLikesValue == 0 ? "--" : String(entity.patchesLikesValue)
					self.favoritesInfo.setTitle("Favorites: \(count)", forState: .Normal)
				}
			}
		}
		self.setNeedsLayout()
		self.layoutIfNeeded()
		self.sizeToFit()
	}
}
