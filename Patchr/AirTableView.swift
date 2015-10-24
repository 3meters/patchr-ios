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
	
	func initialize() {	/* Stub */ }
	
	override func scrollRectToVisible(rect: CGRect, animated: Bool) {
		// UIScrollView responds strangely when a textfield becomes first responder
		// http://stackoverflow.com/a/12640831/2247399
		return
	}
	
	override func scrollToNearestSelectedRowAtScrollPosition(scrollPosition: UITableViewScrollPosition, animated: Bool) {
		return
	}
	
	override func scrollToRowAtIndexPath(indexPath: NSIndexPath, atScrollPosition scrollPosition: UITableViewScrollPosition, animated: Bool) {
		return
	}

}
