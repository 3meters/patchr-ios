//
//  PatchCell.swift
//  Patchr
//
//  Created by Jay Massena on 10/17/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import SDWebImage
import FontAwesome_swift

class ChannelView: BaseView {

    var visibility		= UILabel()
	var name			= UILabel()
	
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
		
		/* Patch name */
		self.name.font = Theme.fontText
        self.name.textColor = Theme.colorTextSecondary
		self.name.numberOfLines = 1
		self.addSubview(self.name)
		
		/* Patch visibility */
        self.visibility.font = UIFont.fontAwesomeOfSize(16)
        self.visibility.textColor = Theme.colorTextSecondary
		self.addSubview(self.visibility)
	}
	
	override func bindToEntity(entity: AnyObject, location: CLLocation?) {
		
		if let patch = entity as? Patch {
            self.entity = patch
            self.name.text = patch.name.lowercaseString.stringByReplacingOccurrencesOfString(" ", withString: "-")
            self.visibility.text = (patch.visibility != nil && patch.visibility == "public") ? String.fontAwesomeIconWithName(.Hashtag) : String.fontAwesomeIconWithName(.Lock)
		}

		self.setNeedsLayout()
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
				
		let columnWidth = NAVIGATION_DRAWER_WIDTH - (24 + 20 + 8 + 24)
        self.visibility.anchorCenterLeftWithLeftPadding(24, width: 20, height: 20)
        self.name.alignToTheRightOf(self.visibility, withLeftPadding: 0, topPadding: 6, width: columnWidth, height: 24)
	}
}