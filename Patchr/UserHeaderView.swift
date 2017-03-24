//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class UserHeaderView: BaseDetailView {

	var photoControl = PhotoControl()
    var fullName = AirLabelTitle()
    var username = UILabel()
	var rule = UIView()
	
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
		self.fullName.lineBreakMode = .byTruncatingMiddle
		self.fullName.font = Theme.fontTitleLarge
        self.fullName.textAlignment = NSTextAlignment.center
		
        /* Username */
        self.username.lineBreakMode = .byTruncatingMiddle
        self.username.font = Theme.fontTextDisplay
        self.username.textColor = Theme.colorTextSecondary
        self.username.textAlignment = NSTextAlignment.center
        
		/* Rule */
		self.rule.backgroundColor = Theme.colorSeparator
		
		self.addSubview(self.photoControl)
		self.addSubview(self.fullName)
        self.addSubview(self.username)
		self.addSubview(self.rule)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
        
        let contentWidth = self.bounds.size.width - 32

        self.username.bounds.size.width = contentWidth
        self.username.sizeToFit()
        
        self.photoControl.anchorTopCenter(withTopPadding: 16, width: 96, height: 96)
        
        if !self.fullName.isHidden {
            self.fullName.bounds.size.width = contentWidth
            self.fullName.sizeToFit()
            self.fullName.alignUnder(self.photoControl, matchingCenterWithTopPadding: 8, width: contentWidth, height: 36)
            self.username.alignUnder(self.fullName, matchingCenterWithTopPadding: 0, width: contentWidth, height: 24)
            self.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: (16 + 96 + 40 + 24 + 16))
        }
        else {
            self.fullName.alignUnder(self.photoControl, matchingCenterWithTopPadding: 0, width: contentWidth, height: 0)
            self.username.alignUnder(self.fullName, matchingCenterWithTopPadding: 8, width: contentWidth, height: 24)
            self.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: (16 + 96 + 32 + 16))
        }
        
        self.rule.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 1)
	}
	
	func bind(user: FireUser?) {
        
        self.fullName.text?.removeAll(keepingCapacity: false)
        self.username.text?.removeAll(keepingCapacity: false)
        self.fullName.isHidden = true
        
        if user != nil {
            
            if user!.username != nil {
                self.username.text = "@\(user!.username!)"
            }
            
            self.fullName.text = user!.fullName!
            let fullName = self.fullName.text!
            
            if let photo = user!.profile?.photo {
                let url = Cloudinary.url(prefix: photo.filename!, category: SizeCategory.profile)
                self.photoControl.bind(url: url, name: fullName, colorSeed: user!.id)
            }
            else {
                self.photoControl.bind(url: nil, name: fullName, colorSeed: user!.id)
            }
        }
        else {
            self.photoControl.bind(url: nil, name: nil, colorSeed: nil, color: Theme.colorBackgroundImage)
        }
        
        self.setNeedsLayout()
	}
}
