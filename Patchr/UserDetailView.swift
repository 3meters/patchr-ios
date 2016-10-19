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
    var username       = UILabel()
	var rule           = UIView()
	var userGroup      = UIView()
	
	init() {
		super.init(frame: CGRect.zero)
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
		
		/* User friendly name */
		self.name.lineBreakMode = .byTruncatingMiddle
		self.name.font = Theme.fontTitleLarge
		
        /* Username */
        self.username.lineBreakMode = .byTruncatingMiddle
        self.username.font = Theme.fontTextDisplay
        self.username.textColor = Theme.colorTextSecondary
        
		/* Rule */
		self.rule.backgroundColor = Theme.colorSeparator
		
		self.userGroup.addSubview(self.photo)
		self.userGroup.addSubview(self.name)
        self.userGroup.addSubview(self.username)
		self.userGroup.addSubview(self.rule)
		self.addSubview(self.userGroup)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		self.userGroup.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 112)
		self.photo.anchorTopLeft(withLeftPadding: 8, topPadding: 8, width: 96, height: 96)
		self.name.align(toTheRightOf: self.photo, fillingWidthWithLeftAndRightPadding: 12, topPadding: 12, height: 36)
		self.username.alignUnder(self.name, matchingLeftAndFillingWidthWithRightPadding: 12, topPadding: 0, height: 24)
		self.rule.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 1)
	}
	
	func bindToEntity(entity: Entity!) {
		
		self.name.text?.removeAll(keepingCapacity: false)
		self.username.text?.removeAll(keepingCapacity: false)
		
		if let user = entity as? User {
			self.name.text = user.name
			self.username.text = user.email
			self.photo.bindToEntity(entity: user)
		}
	}
}
