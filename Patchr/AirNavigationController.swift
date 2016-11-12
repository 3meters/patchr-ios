//
//  AirNavigationController.swift
//  Patchr
//
//  Created by Jay Massena on 5/20/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import UIKit

class AirNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

class AirNavigationBar: UINavigationBar {
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let newSize :CGSize = CGSize(width: self.frame.size.width, height: 54)
        return newSize
    }
}
