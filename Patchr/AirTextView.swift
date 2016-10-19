//
//  AirTextField.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class AirTextView: UITextView {
	
	var placeholderLabel = AirLabelDisplay()
	var rule			 = UIView()
	
	func initialize() {
		
		NotificationCenter.default.addObserver(self, selector: #selector(AirTextView.editingBegin(notification:)), name: NSNotification.Name.UITextFieldTextDidBeginEditing, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(AirTextView.editingBegin(notification:)), name: NSNotification.Name.UITextViewTextDidBeginEditing, object: nil)
		
		self.textColor = Theme.colorText
		self.font = Theme.fontText
		
		self.placeholderLabel.textColor = Theme.colorTextPlaceholder
		self.placeholderLabel.font = Theme.fontText
		self.placeholderLabel.isHidden = !self.text.isEmpty
		self.addSubview(self.placeholderLabel)
		
		self.isScrollEnabled = false
		self.textContainer.lineFragmentPadding = 0
		self.textContainerInset = UIEdgeInsetsMake(12, 0, 12, 0)
		self.autocapitalizationType = .sentences
		self.autocorrectionType = .yes
		self.keyboardType = UIKeyboardType.default
		self.returnKeyType = UIReturnKeyType.default
		
		self.rule.backgroundColor = Theme.colorRule
		self.addSubview(self.rule)
	}
		
	override func layoutSubviews() {
		super.layoutSubviews()
		self.placeholderLabel.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 48)
		self.rule.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: Theme.dimenRuleThickness)
	}
	
	func editingBegin(notification: NSNotification) {
		if let textField = notification.object as? UITextView {
			if textField == self {
				self.rule.backgroundColor = Theme.colorRuleActive
				return
			}
		}
		self.rule.backgroundColor = Theme.colorRule
	}
}
