//
//  AirAlertController.swift
//  Patchr
//
//  Created by Jay Massena on 10/8/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

@available(iOS 8.0, *)
class AirAlertController: UIAlertController {
	/*
	 * http://http://stackoverflow.com/questions/31406820
	 * Fix for iOS 9 bug that produces infinite recursion loop looking for
	 * supportInterfaceOrientations.
	 */
	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
		return UIInterfaceOrientationMask.Portrait
	}
	
	override func shouldAutorotate() -> Bool {
		return false
	}
}
