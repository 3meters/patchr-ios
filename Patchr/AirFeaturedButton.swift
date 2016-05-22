//
//  AirButton.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class AirFeaturedButton: UIButton {

	required init(coder aDecoder: NSCoder) {
		/* Called when instantiated from XIB or Storyboard */
		super.init(coder: aDecoder)!
		initialize()
	}
	
	override init(frame: CGRect) {
		/* Called when instantiated from code */
		super.init(frame: frame)
		initialize()
	}
	
	func initialize() {
		self.titleLabel!.font = Theme.fontButtonTitle
		self.setTitleColor(Theme.colorButtonTitleFeatured, forState: .Normal)
		self.setTitleColor(Theme.colorButtonTitleFeaturedHighlighted, forState: .Highlighted)
		self.backgroundColor = Theme.colorButtonFillFeatured
		self.borderColor = Theme.colorButtonBorderFeatured
		self.borderWidth = Theme.dimenButtonBorderWidth
		self.cornerRadius = Int(Theme.dimenButtonCornerRadius)
		
		self.layer.masksToBounds = false
		self.layer.shadowColor = Colors.black.CGColor
		self.layer.shadowOffset = CGSizeMake(0, 1)
		self.layer.shadowOpacity = 0.4
		self.layer.shadowRadius = 1
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
	}
}
