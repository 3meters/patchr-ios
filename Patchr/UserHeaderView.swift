//
//  UserDetailView.swift
//  Patchr
//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class UserHeaderView: BaseDetailView {

	var name           = AirLabelTitle()
	var photo          = UserPhotoView()
    var username       = UILabel()
	var rule           = UIView()
	var userGroup      = UIView()
	
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
		
		/* User friendly name */
		self.name.lineBreakMode = .ByTruncatingMiddle
		self.name.font = Theme.fontTitleLarge
        self.name.textAlignment = NSTextAlignment.Center

		
        /* Username */
        self.username.lineBreakMode = .ByTruncatingMiddle
        self.username.font = Theme.fontTextDisplay
        self.username.textColor = Theme.colorTextSecondary
        self.username.textAlignment = NSTextAlignment.Center
        
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
        
        let contentWidth = self.bounds.size.width - 32

        self.name.sizeToFit()
        self.username.sizeToFit()

		self.userGroup.anchorTopCenterFillingWidthWithLeftAndRightPadding(0, topPadding: 0, height: 192)
		self.photo.anchorTopCenterWithTopPadding(16, width: 96, height: 96)
		self.name.alignUnder(self.photo, matchingCenterWithTopPadding: 8, width: contentWidth, height: 36)
        self.username.alignUnder(self.name, matchingCenterWithTopPadding: 0, width: contentWidth, height: 24)
		self.rule.anchorBottomCenterFillingWidthWithLeftAndRightPadding(0, bottomPadding: 0, height: 1)
	}
	
	func bindToUser(user: FireUser!) {
        self.name.text?.removeAll(keepCapacity: false)
        self.username.text?.removeAll(keepCapacity: false)
        
        self.username.text = "@\(user.username!)"
        if let profile = user.profile {
            self.name.text = profile.fullName!
            var photoUrl: NSURL? = nil
            if let photo = profile.photo {
                photoUrl = PhotoUtils.url(photo.filename!, source: photo.source!, category: SizeCategory.profile)
            }
            self.photo.bindPhoto(photoUrl, name: profile.fullName!)
        }
	}
}
