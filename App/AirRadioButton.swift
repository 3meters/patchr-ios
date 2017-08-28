//
//  AirButton.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import DLRadioButton

class AirRadioButton: DLRadioButton {

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
		self.titleLabel!.font = Theme.fontButtonRadioTitle
		self.setTitleColor(Theme.colorButtonRadioTitle, for: .normal)
		self.setTitleColor(Theme.colorButtonTitleHighlighted, for: .highlighted)
		self.iconColor = Theme.colorButtonRadioIcon
		self.indicatorColor = Theme.colorButtonRadioIndicator
		self.contentHorizontalAlignment = .left
		self.isIconOnRight = false
		self.iconSize = 20
		self.iconStrokeWidth = self.iconSize / self.iconSize
		self.indicatorSize = self.iconSize * 0.6
		self.marginWidth = 8
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
	}
}
