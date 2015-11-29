//
//  AirScrollView.swift
//  Patchr
//
//  Created by Jay Massena on 11/26/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class AirScrollView: UIScrollView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)!
		self.delaysContentTouches = false
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.delaysContentTouches = false
	}
	
	override func touchesShouldCancelInContentView(view: UIView) -> Bool {
		return true
	}
}
