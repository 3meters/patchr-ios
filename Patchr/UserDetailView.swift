//
//  UserDetailView.swift
//  Patchr
//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class UserDetailView: BaseDetailView {

	var name           = AirLabelTitle()
	var photo          = UserPhotoView()
	var email          = UILabel()
	var rule           = UIView()
	var userGroup      = UIView()
	var ownsGroup      = AirRuleView()
	var ownsIcon       = UIImageView()
	var ownsButton     = AirLinkButton()
	var watchingGroup  = AirRuleView()
	var watchingIcon   = UIImageView()
	var watchingButton = AirLinkButton()
	
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
		fatalError("This view should never be loaded from storyboard")
	}
	
	func initialize() {
		
		self.clipsToBounds = true
		self.backgroundColor = Theme.colorBackgroundForm
		
		/* User name */
		self.name.lineBreakMode = .ByTruncatingMiddle
		self.name.font = Theme.fontTitleLarge
		
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
		self.watchingButton.setTitleColor(Theme.colorTint, forState: .Normal)
		self.watchingButton.titleLabel!.font = Theme.fontHeading
		self.watchingButton.contentHorizontalAlignment = .Left
		
		self.watchingGroup.addSubview(self.watchingIcon)
		self.watchingGroup.addSubview(self.watchingButton)
		self.watchingGroup.ruleBottom.backgroundColor = Theme.colorSeparator

		/* Owns */
		self.ownsIcon.image = UIImage(named: "imgEditLight")
		self.ownsIcon.alpha = 0.5
		self.ownsIcon.tintColor = Colors.black
		self.ownsButton.setTitleColor(Theme.colorTint, forState: .Normal)
		self.ownsButton.titleLabel!.font = Theme.fontHeading
		self.ownsButton.contentHorizontalAlignment = .Left
		
		self.ownsGroup.addSubview(self.ownsIcon)
		self.ownsGroup.addSubview(self.ownsButton)
		self.ownsGroup.ruleBottom.backgroundColor = Theme.colorSeparator

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
		self.watchingButton.alignToTheRightOf(self.watchingIcon, matchingCenterAndFillingWidthWithLeftAndRightPadding: 20, height: 24)

		self.ownsGroup.alignUnder(self.watchingGroup, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 0, height: 48)
		self.ownsIcon.anchorCenterLeftWithLeftPadding(24, width: 24, height: 24)
		self.ownsButton.alignToTheRightOf(self.ownsIcon, matchingCenterAndFillingWidthWithLeftAndRightPadding: 20, height: 24)
	}
	
	func bindToEntity(entity: Entity!) {
		
		self.name.text?.removeAll(keepCapacity: false)
		self.email.text?.removeAll(keepCapacity: false)
		
		if let user = entity as? User {
			self.name.text = user.name
			self.email.text = user.email
			self.photo.bindToEntity(user)

			if user.patchesWatching != nil {
				let count = user.patchesWatchingValue == 0 ? "--" : String(user.patchesWatchingValue)
				self.watchingButton.setTitle("Watching: \(count)", forState: .Normal)
			}
			if user.patchesOwned != nil {
				let count = user.patchesOwnedValue == 0 ? "--" : String(user.patchesOwnedValue)
				self.ownsButton.setTitle("Owner: \(count)", forState: .Normal)
			}
		}
	}
}
