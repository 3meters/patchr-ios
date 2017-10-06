//
//  AirTextView.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class AirTextView: UITextView {
	
	var rule = UIView()
    var placeholderLabel: UILabel?
    var ruleEnabled = true
    override var text: String? {
        didSet{
            self.placeholderLabel!.isHidden = (self.text != nil && self.text!.utf16.count > 0)
        }
    }
    var placeholder: String? {
        get {
            // Get the placeholder text from the label
            var placeholderText: String?
            if let placeHolderLabel = self.viewWithTag(100) as? UILabel {
                placeholderText = placeHolderLabel.text
            }
            return placeholderText
        }
        set {
            // Store the placeholder text in the label
            if let placeHolderLabel = self.viewWithTag(100) as? UILabel {
                placeHolderLabel.text = newValue
            }
            else  {
                self.addPlaceholderLabel(placeholderText: newValue!)
            }
        }
    }
    
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
    
    func addPlaceholderLabel(placeholderText: String) {
        
        // Create the label and set its properties
        self.placeholderLabel = UILabel()
        self.placeholderLabel!.text = placeholderText
        self.placeholderLabel!.font = Theme.fontTextDisplay
        self.placeholderLabel!.textColor = Theme.colorTextPlaceholder
        self.placeholderLabel!.tag = 100
        
        // Hide the label if there is text in the text view
        self.placeholderLabel!.isHidden = (self.text!.utf16.count > 0)
        self.addSubview(self.placeholderLabel!)
    }
		
	override func layoutSubviews() {
		super.layoutSubviews()
        self.placeholderLabel?.anchorTopCenterFillingWidth(withLeftAndRightPadding: self.textContainerInset.left, topPadding: self.textContainerInset.top, height: 24)
		self.rule.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: Theme.dimenRuleThickness)
	}
    
	@objc func editingBegin(notification: NSNotification) {
        if self.ruleEnabled {
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
}
