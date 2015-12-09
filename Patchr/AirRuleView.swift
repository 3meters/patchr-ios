//
//  AirTextField.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class AirRuleView: UIView {
	
	var rule = UIView()
	var thickness = Theme.dimenRuleThickness

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
		self.rule.backgroundColor = Theme.colorRule
		self.addSubview(self.rule)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		self.rule.anchorBottomCenterFillingWidthWithLeftAndRightPadding(0, bottomPadding: 0, height: self.thickness)
	}
}