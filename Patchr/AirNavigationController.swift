//
//  AirNavigationController.swift
//  Patchr
//
//  Created by Jay Massena on 5/20/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import UIKit

class AirNavigationController: UINavigationController {
    
    var statusBarView: UIView!
    var tag: String!
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Lifecycle
     *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.statusBarView = UIView(frame: UIApplication.shared.statusBarFrame)
        statusBarView.backgroundColor = Colors.accentColor
        self.view.addSubview(statusBarView)
        self.hidesBarsOnSwipe = false
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    deinit {
        Log.v("\(self.className) released")
    }
    
    func removeStatusBarView() {
        self.statusBarView.removeFromSuperview()
    }
}
