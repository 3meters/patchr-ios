//
//  AirTableView.swift
//  Patchr
//
//  Created by Jay Massena on 10/20/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

/*
 * Check this to investigate touch highlighting for buttons in scroll views.
 * From: http://stackoverflow.com/questions/19256996/uibutton-not-showing-highlight-on-tap-in-ios7/26049216#26049216
 */

class AirTableView: UITableView {
	
	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)!
		initialize()
	}
	
	override init(frame: CGRect, style: UITableViewStyle) {
		super.init(frame: frame, style: style)
		initialize()
	}
	
	func initialize() {
		self.delaysContentTouches = false
	}
	
	override func scrollToNearestSelectedRowAtScrollPosition(scrollPosition: UITableViewScrollPosition, animated: Bool) {
		return
	}
	
	override func scrollToRowAtIndexPath(indexPath: NSIndexPath, atScrollPosition scrollPosition: UITableViewScrollPosition, animated: Bool) {
		return
	}
	
	override func touchesShouldCancelInContentView(view: UIView) -> Bool {
		return true
	}
}
