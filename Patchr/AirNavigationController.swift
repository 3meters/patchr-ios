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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.statusBarView = UIView(frame: UIApplication.shared.statusBarFrame)
        let statusBarColor = Colors.accentColor
        statusBarView.backgroundColor = statusBarColor
        self.view.addSubview(statusBarView)
    }
    
    deinit {
        Log.v("\(self.className) released")
    }
}
