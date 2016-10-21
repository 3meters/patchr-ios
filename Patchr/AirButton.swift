//
//  AirButton.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class AirButton: UIButton {

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
		self.setTitleColor(Theme.colorButtonTitle, for: .normal)
		self.setTitleColor(Theme.colorButtonTitleHighlighted, for: .highlighted)
		self.backgroundColor = Theme.colorButtonFill
		self.borderColor = Theme.colorButtonBorder
		self.borderWidth = Theme.dimenButtonBorderWidth
		self.cornerRadius = Int(Theme.dimenButtonCornerRadius)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
	}
}
