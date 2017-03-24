//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class UserMiniHeaderView: BaseDetailView {

	var photoControl = PhotoControl()
    var title = AirLabelTitle()
    var subtitle = UILabel()
	
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
		self.title.lineBreakMode = .byTruncatingMiddle
		self.title.font = Theme.fontTextDisplay
        self.title.textAlignment = .left
		
        /* Username */
        self.subtitle.lineBreakMode = .byTruncatingMiddle
        self.subtitle.font = Theme.fontComment
        self.subtitle.textColor = Theme.colorTextSecondary
        self.subtitle.textAlignment = .left
        
		self.addSubview(self.photoControl)
		self.addSubview(self.title)
        self.addSubview(self.subtitle)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
        
        let contentWidth = self.bounds.size.width - 32
        let columnWidth = contentWidth - 56

        self.subtitle.bounds.size.width = columnWidth
        self.subtitle.sizeToFit()
        
        self.photoControl.anchorBottomLeft(withLeftPadding: 16, bottomPadding: 12, width: 48, height: 48)
        
        if !self.title.isHidden {
            self.title.bounds.size.width = columnWidth
            self.title.sizeToFit()
            self.subtitle.align(toTheRightOf: self.photoControl, matchingBottomWithLeftPadding: 8, width: columnWidth, height: self.subtitle.height())
            self.title.align(above: self.subtitle, matchingLeftWithBottomPadding: 0, width: columnWidth, height: self.title.height())
        }
        else {
            self.subtitle.align(toTheRightOf: self.photoControl, matchingBottomWithLeftPadding: 8, width: columnWidth, height: self.subtitle.height())
            self.title.align(above: self.subtitle, matchingLeftWithBottomPadding: 0, width: columnWidth, height: 0)
            self.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: (16 + 96 + 32 + 16))
        }
	}
	
	func bind(user: FireUser?) {
        
        self.title.text?.removeAll(keepingCapacity: false)
        self.subtitle.text?.removeAll(keepingCapacity: false)
        
        if user != nil {
            
            if user!.username != nil {
                self.subtitle.text = "@\(user!.username!)"
            }
            
            self.title.text = user!.fullName
            let fullName = self.title.text!
            
            if let photo = user!.profile?.photo {
                let url = Cloudinary.url(prefix: photo.filename, category: SizeCategory.profile)
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
