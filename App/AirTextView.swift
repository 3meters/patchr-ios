//
//  AirTextView.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import NextGrowingTextView

class AirTextView: NextGrowingTextView {
	
	var rule = UIView()
    var ruleEnabled = true
    
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
        self.textView.font = Theme.fontText
        self.textView.textColor = Theme.colorText
        self.layer.cornerRadius = 4
        self.layer.borderColor = Colors.gray75pcntColor.cgColor
        self.layer.borderWidth = 0.5
        self.backgroundColor = Colors.clear
        self.textView.textContainer.lineFragmentPadding = 0
        self.textView.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8)
        self.textView.autocapitalizationType = .sentences
        self.textView.autocorrectionType = .yes
        self.textView.keyboardType = .default
        self.textView.returnKeyType = .default
	}
}
