//
//  AirImageView.swift
//  Patchr
//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class AirLabelBanner: UILabel {
    
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
	
    override func drawTextInRect(rect: CGRect) -> Void {
        let insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, insets))
    }
	
	func initialize() {
		self.font = Theme.fontBanner
		self.textColor = Theme.colorTextBanner
	}
}
