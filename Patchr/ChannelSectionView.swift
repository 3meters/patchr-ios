//
//  PatchCell.swift
//  Patchr
//
//  Created by Jay Massena on 10/17/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import SDWebImage

class ChannelSectionView: BaseView {

	var name			= UILabel()
    var addButton		= UIButton()
	
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
		
		/* Section name */
		self.name.font = Theme.fontText
        self.name.textColor = Theme.colorTextSecondary
		self.name.numberOfLines = 1
		self.addSubview(self.name)
        
        self.addButton.setImage(UIImage(named: "imgAddLight"), for: .normal)
        self.addButton.backgroundColor = Theme.colorScrimLighten
        self.addButton.cornerRadius = 18
        self.addSubview(self.addButton)
	}
		
	override func layoutSubviews() {
		super.layoutSubviews()
				
		let columnWidth = NAVIGATION_DRAWER_WIDTH - (24 + 8 + 36 + 24)
        self.name.anchorCenterLeft(withLeftPadding: 24, width: columnWidth, height: 20)
        self.addButton.anchorCenterRight(withRightPadding: 8, width: 36, height: 36)
	}
}
