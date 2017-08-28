//
//  AirButton.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import BEMCheckBox

class AirCheckBox: BEMCheckBox {

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
        self.onAnimationType = .bounce
        self.offAnimationType = .bounce
        self.onTintColor = Colors.accentColor
        self.onCheckColor = Colors.white
        self.onFillColor = Colors.accentColor
        self.tintColor = Colors.accentColor
        self.animationDuration = 0.3
        self.lineWidth = 1.0
        self.isUserInteractionEnabled = false
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
	}
}
