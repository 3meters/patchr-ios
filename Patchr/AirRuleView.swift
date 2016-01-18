//
//  AirTextField.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import Facade

class AirRuleView: UIView {
	
	var ruleBottom = UIView()
	var ruleTop = UIView()
	var ruleLeft = UIView()
	var ruleRight = UIView()
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
		self.ruleBottom.hidden = false
		self.ruleTop.hidden = true
		self.ruleLeft.hidden = true
		self.ruleRight.hidden = true
		
		self.ruleBottom.backgroundColor = Theme.colorRule
		self.ruleTop.backgroundColor = Theme.colorRule
		self.ruleLeft.backgroundColor = Theme.colorRule
		self.ruleRight.backgroundColor = Theme.colorRule
		
		self.addSubview(self.ruleBottom)
		self.addSubview(self.ruleTop)
		self.addSubview(self.ruleLeft)
		self.addSubview(self.ruleRight)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		self.ruleBottom.anchorBottomCenterFillingWidthWithLeftAndRightPadding(0, bottomPadding: 0, height: self.thickness)
		self.ruleTop.anchorTopCenterFillingWidthWithLeftAndRightPadding(0, topPadding: 0, height: self.thickness)
		self.ruleLeft.anchorCenterLeftFillingHeightWithTopPadding(0, bottomPadding: 0, leftPadding: 0, width: self.thickness)
		self.ruleRight.anchorCenterRightFillingHeightWithTopPadding(0, bottomPadding: 0, rightPadding: 0, width: self.thickness)
	}
}