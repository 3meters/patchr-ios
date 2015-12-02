//
//  AirImageView.swift
//  Patchr
//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class AirLabelBase: UILabel {
	
	var insets = UIEdgeInsetsZero
    
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
		super.drawTextInRect(UIEdgeInsetsInsetRect(rect, self.insets))
	}
	
	func initialize() {	}
}
