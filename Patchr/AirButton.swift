//
//  AirButton.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class AirButton: AirButtonBase {
    
    var imageRight: UIImageView? {
        didSet {
            self.addSubview(self.imageRight!)
        }
    }
    
    var imageLeft: UIImageView? {
        didSet {
            self.addSubview(self.imageLeft!)
        }
    }

	required init(coder aDecoder: NSCoder) {
		/* Called when instantiated from XIB or Storyboard */
		super.init(coder: aDecoder)
		initialize()
	}
	
	override init(frame: CGRect) {
		/* Called when instantiated from code */
		super.init(frame: frame)
		initialize()
	}
	
	func initialize() {
		self.titleLabel!.font = Theme.fontButtonTitle
		self.setTitleColor(Theme.colorButtonTitle, for: .normal)
		self.setTitleColor(Theme.colorButtonTitleHighlighted, for: .highlighted)
		self.backgroundColor = Theme.colorButtonFill
		self.borderColor = Theme.colorButtonBorder
		self.borderWidth = Theme.dimenButtonBorderWidth
		self.cornerRadius = Theme.dimenButtonCornerRadius
	}
    
    override var intrinsicContentSize: CGSize {
        get {
            let labelSize = titleLabel?.sizeThatFits(CGSize(width: self.frame.size.width, height: CGFloat.greatestFiniteMagnitude)) ?? CGSize.zero
            let desiredButtonSize = CGSize(width: labelSize.width + titleEdgeInsets.left + titleEdgeInsets.right, height: labelSize.height + titleEdgeInsets.top + titleEdgeInsets.bottom)
            return desiredButtonSize
        }
    }
	
	override func layoutSubviews() {
		super.layoutSubviews()
        if let image = self.imageRight {
            image.anchorCenterRight(withRightPadding: 24, width: image.width(), height: image.height())
        }
        if let image = self.imageLeft {
            image.anchorCenterLeft(withLeftPadding: 24, width: image.width(), height: image.height())
        }
	}
}
