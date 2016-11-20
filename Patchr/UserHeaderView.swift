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
	var photo          = PhotoView()
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
        self.name.textAlignment = NSTextAlignment.center

		
        /* Username */
        self.username.lineBreakMode = .byTruncatingMiddle
        self.username.font = Theme.fontTextDisplay
        self.username.textColor = Theme.colorTextSecondary
        self.username.textAlignment = NSTextAlignment.center
        
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

		self.userGroup.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 192)
		self.photo.anchorTopCenter(withTopPadding: 16, width: 96, height: 96)
        self.name.alignUnder(self.photo, matchingCenterWithTopPadding: 8, width: contentWidth, height: self.name.isHidden ? 0 : 36)
        self.username.alignUnder(self.name, matchingCenterWithTopPadding: 0, width: contentWidth, height: 24)
		self.rule.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 1)
	}
	
	func bind(user: FireUser?) {
        self.name.text?.removeAll(keepingCapacity: false)
        self.username.text?.removeAll(keepingCapacity: false)
        
        if user != nil {
            if user!.username != nil {
                self.username.text = "@\(user!.username!)"
            }
            
            if let profile = user!.profile {
                let photo = profile.photo
                let fullName = profile.fullName
                
                self.name.isHidden = true
                if fullName != nil {
                    self.name.text = fullName
                    self.name.isHidden = false
                }
                
                var photoUrl: URL? = nil
                if photo != nil {
                    photoUrl = PhotoUtils.url(prefix: photo!.filename!, source: photo!.source!, category: SizeCategory.profile)
                }
                
                if photoUrl != nil || fullName != nil {
                    self.photo.bind(photoUrl: photoUrl, name: profile.fullName, colorSeed: user!.id)
                }
                else {
                    self.photo.bind(photoUrl: photoUrl, name: profile.fullName, colorSeed: user!.id, color: Colors.accentColorFill)
                }
            }
        }
        else {
            self.photo.bind(photoUrl: nil, name: nil, colorSeed: nil, color: Theme.colorBackgroundImage)
        }
        
        self.setNeedsLayout()
        self.layoutIfNeeded()
        self.sizeToFit()
	}
}
