//
//  AirScrollView.swift
//  Patchr
//
//  Created by Jay Massena on 11/26/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class AirScrollView: UIScrollView {

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
