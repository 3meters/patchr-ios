//
//  AirNavigationController.swift
//  Patchr
//
//  Created by Jay Massena on 5/20/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import UIKit
import AMScrollingNavbar

class AirNavigationController: ScrollingNavigationController {
    
    var tag: String!
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Lifecycle
     *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hidesBarsOnSwipe = false
    }
    
    deinit {
        Log.v("\(self.className) released")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if let top = self.topViewController {
            return top.preferredStatusBarStyle
        }
        return super.preferredStatusBarStyle
    }
}
