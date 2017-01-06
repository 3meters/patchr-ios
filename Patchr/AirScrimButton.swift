//
//  AirButton.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class AirScrimButton: AirButtonBase {
    
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
        self.setBackgroundImage(Utils.imageFromColor(color: Colors.gray75pcntColor), for: .highlighted)
        self.setBackgroundImage(Utils.imageFromColor(color: Colors.clear), for: .normal)
    }
	
	override func layoutSubviews() {
		super.layoutSubviews()
	}
}
