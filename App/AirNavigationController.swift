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
    
    var statusBarView: UIView!
    var tag: String!
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Lifecycle
     *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.statusBarView = UIView(frame: UIApplication.shared.statusBarFrame)
//        statusBarView.backgroundColor = Colors.accentColor
//        self.view.addSubview(statusBarView)
        self.hidesBarsOnSwipe = false
    }
    
    deinit {
        Log.v("\(self.className) released")
    }
    
    func removeStatusBarView() {
        self.statusBarView.removeFromSuperview()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if let top = self.topViewController {
            return top.preferredStatusBarStyle
        }
        return super.preferredStatusBarStyle
    }
}
