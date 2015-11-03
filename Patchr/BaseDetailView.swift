//
//  BaseDetailView.swift
//  Patchr
//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class BaseDetailView: UIView {

	var entity: Entity?
	
	override func sizeThatFits(size: CGSize) -> CGSize {
		
		var w = CGFloat(0)
		var h = CGFloat(0)
		
		for subview in self.subviews {
			let fw = subview.frame.origin.x + subview.frame.size.width
			let fh = subview.frame.origin.y + subview.frame.size.height
			w = max(fw, w)
			h = max(fh, h)
		}
		
		return CGSizeMake(w, h)
	}
}