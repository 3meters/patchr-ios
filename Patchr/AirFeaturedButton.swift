//
//  AirButton.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class AirFeaturedButton: AirButtonBase {

	required init(coder aDecoder: NSCoder) {
		/* Called when instantiated from XIB or Storyboard */
		super.init(coder: aDecoder)
		initialize()
	}
	
	override init(frame: CGRect) {
		/* Called when instantiated from code */
		super.init(frame: frame)
		initialize()
	}
	
	func initialize() {
		self.titleLabel!.font = Theme.fontButtonTitle
		self.setTitleColor(Theme.colorButtonTitleFeatured, for: .normal)
		self.setTitleColor(Theme.colorButtonTitleFeaturedHighlighted, for: .highlighted)
		self.backgroundColor = Theme.colorButtonFillFeatured
		self.borderColor = Theme.colorButtonBorderFeatured
		self.borderWidth = Theme.dimenButtonBorderWidth
		self.cornerRadius = Theme.dimenButtonCornerRadius
		
		self.layer.masksToBounds = false
		self.layer.shadowColor = Colors.black.cgColor
        self.layer.shadowOffset = CGSize(width:0, height:1)
		self.layer.shadowOpacity = 0.4
		self.layer.shadowRadius = 1
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
	}
}
