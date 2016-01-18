//
//  AirTextField.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import THContactPicker

class AirContactPicker: THContactPickerView {
	
	var rule = UIView()
	
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
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "editingBegin:", name: UITextFieldTextDidBeginEditingNotification, object: nil)
		self.rule.backgroundColor = Theme.colorRule
		self.font = Theme.fontText
		self.setPromptLabelTextColor(Theme.colorTextPlaceholder)
		self.addSubview(self.rule)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		self.rule.anchorBottomCenterFillingWidthWithLeftAndRightPadding(0, bottomPadding: 0, height: Theme.dimenRuleThickness)
	}
	
	func editingBegin(notification: NSNotification) {
		if let textField = notification.object as? UITextField {
			if textField == self {
				self.rule.backgroundColor = Theme.colorRuleActive
			}
			else {
				self.rule.backgroundColor = Theme.colorRule
			}
		}
	}
}