//
//  AirTextView.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import JVFloatLabeledTextField

class AirTextView: JVFloatLabeledTextView {
	
	var rule = UIView()
    
    required init(coder aDecoder: NSCoder) {
        /* Called when instantiated from XIB or Storyboard */
        super.init(coder: aDecoder)!
        initialize()
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        /* Called when instantiated from code */
        super.init(frame: frame, textContainer: textContainer)
        initialize()
    }

	func initialize() {
		
        NotificationCenter.default.addObserver(self, selector: #selector(editingBegin(notification:)), name: NSNotification.Name.UITextFieldTextDidBeginEditing, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(editingBegin(notification:)), name: NSNotification.Name.UITextViewTextDidBeginEditing, object: nil)
		
        self.font = Theme.fontText
		self.textColor = Theme.colorText
        self.floatingLabelActiveTextColor = Colors.accentColorTextLight
        self.floatingLabelFont = Theme.fontComment
        self.floatingLabelTextColor = Theme.colorTextPlaceholder
		
		self.isScrollEnabled = false
		self.textContainer.lineFragmentPadding = 0
		self.textContainerInset = UIEdgeInsetsMake(12, 0, 12, 0)
		self.autocapitalizationType = .sentences
		self.autocorrectionType = .yes
		self.keyboardType = .default
		self.returnKeyType = .default
		
		self.rule.backgroundColor = Theme.colorRule
		self.addSubview(self.rule)
	}
		
	override func layoutSubviews() {
		super.layoutSubviews()
		self.rule.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: Theme.dimenRuleThickness)
	}
	
	func editingBegin(notification: NSNotification) {
		if let textView = notification.object as? UITextView {
			if textView == self {
				self.rule.backgroundColor = Theme.colorRuleActive
			}
            else {
                self.rule.backgroundColor = Theme.colorRule
            }
		}
        else if let _ = notification.object as? UITextField {
            self.rule.backgroundColor = Theme.colorRule
        }
	}
}
