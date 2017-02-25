//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class UserMiniHeaderView: BaseDetailView {

	var photoControl = PhotoControl()
    var fullName = AirLabelTitle()
    var username = UILabel()
	
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
		self.fullName.font = Theme.fontTextDisplay
        self.fullName.textAlignment = .left
		
        /* Username */
        self.username.lineBreakMode = .byTruncatingMiddle
        self.username.font = Theme.fontComment
        self.username.textColor = Theme.colorTextSecondary
        self.username.textAlignment = .left
        
		self.addSubview(self.photoControl)
		self.addSubview(self.fullName)
        self.addSubview(self.username)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
        
        let contentWidth = self.bounds.size.width - 32
        let columnWidth = contentWidth - 56

        self.username.bounds.size.width = columnWidth
        self.username.sizeToFit()
        
        self.photoControl.anchorBottomLeft(withLeftPadding: 16, bottomPadding: 12, width: 48, height: 48)
        
        if !self.fullName.isHidden {
            self.fullName.bounds.size.width = columnWidth
            self.fullName.sizeToFit()
            self.username.align(toTheRightOf: self.photoControl, matchingBottomWithLeftPadding: 8, width: columnWidth, height: self.username.height())
            self.fullName.align(above: self.username, matchingLeftWithBottomPadding: 0, width: columnWidth, height: self.fullName.height())
        }
        else {
            self.username.align(toTheRightOf: self.photoControl, matchingBottomWithLeftPadding: 8, width: columnWidth, height: self.username.height())
            self.fullName.align(above: self.username, matchingLeftWithBottomPadding: 0, width: columnWidth, height: 0)
            self.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: (16 + 96 + 32 + 16))
        }
	}
	
	func bind(user: FireUser?) {
        
        self.fullName.text?.removeAll(keepingCapacity: false)
        self.username.text?.removeAll(keepingCapacity: false)
        self.fullName.isHidden = true
        
        if user != nil {
            
            if user!.username != nil {
                self.username.text = "@\(user!.username!)"
                self.fullName.text = user!.username!
            }
            
            if user!.profile?.fullName != nil && !user!.profile!.fullName!.isEmpty {
                self.fullName.text = user!.profile?.fullName
            }
            
            self.fullName.isHidden = (self.fullName.text == nil || self.fullName.text!.isEmpty)
            let fullName = self.fullName.text
            
            if let photo = user!.profile?.photo {
                if photo.uploading != nil {
                    self.photoControl.bind(url: URL(string: photo.cacheKey)!, fallbackUrl: nil, name: nil, colorSeed: nil, uploading: true)
                }
                else {
                    if let url = ImageUtils.url(prefix: photo.filename, source: photo.source, category: SizeCategory.profile) {
                        let fallbackUrl = ImageUtils.fallbackUrl(prefix: photo.filename!)
                        self.photoControl.bind(url: url, fallbackUrl: fallbackUrl, name: fullName, colorSeed: user!.id)
                    }
                }
            }
            else {
                self.photoControl.bind(url: nil, fallbackUrl: nil, name: fullName, colorSeed: user!.id)
            }
        }
        else {
            self.photoControl.bind(url: nil, fallbackUrl: nil, name: nil, colorSeed: nil, color: Theme.colorBackgroundImage)
        }
        
        self.setNeedsLayout()
	}
}
