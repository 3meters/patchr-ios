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
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AirTextView.editingBegin(_:)), name: UITextFieldTextDidBeginEditingNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AirTextView.editingBegin(_:)), name: UITextViewTextDidBeginEditingNotification, object: nil)
		
		self.textColor = Theme.colorText
		self.font = Theme.fontText
		
		self.placeholderLabel.textColor = Theme.colorTextPlaceholder
		self.placeholderLabel.font = Theme.fontText
		self.placeholderLabel.hidden = !self.text.isEmpty
		self.addSubview(self.placeholderLabel)
		
		self.scrollEnabled = false
		self.textContainer.lineFragmentPadding = 0
		self.textContainerInset = UIEdgeInsetsMake(12, 0, 12, 0)
		self.autocapitalizationType = .Sentences
		self.autocorrectionType = .Yes
		self.keyboardType = UIKeyboardType.Default
		self.returnKeyType = UIReturnKeyType.Default
		
		self.rule.backgroundColor = Theme.colorRule
		self.addSubview(self.rule)
	}
		
	override func layoutSubviews() {
		super.layoutSubviews()
		self.placeholderLabel.anchorTopCenterFillingWidthWithLeftAndRightPadding(0, topPadding: 0, height: 48)
		self.rule.anchorBottomCenterFillingWidthWithLeftAndRightPadding(0, bottomPadding: 0, height: Theme.dimenRuleThickness)
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
