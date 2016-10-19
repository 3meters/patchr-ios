//
//  AirTextField.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class AirTextField: UITextField {
	
	var rule = UIView()
	
	override var placeholder: String? {
		didSet {
			if self.placeholder != nil {
				if !self.placeholder!.isEmpty {
					self.attributedPlaceholder = NSAttributedString(string:self.placeholder!,
						attributes:[NSForegroundColorAttributeName: Theme.colorTextPlaceholder])
				}
			}
		}
	}

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
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	func initialize() {
		NotificationCenter.default.addObserver(self, selector: #selector(AirTextField.editingBegin(notification:)), name: NSNotification.Name.UITextFieldTextDidBeginEditing, object: nil)
		self.rule.backgroundColor = Theme.colorRule
		self.font = Theme.fontText
		self.textColor = Theme.colorText
		self.clearButtonMode = UITextFieldViewMode.whileEditing
		self.addSubview(self.rule)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		self.rule.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: Theme.dimenRuleThickness)
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
