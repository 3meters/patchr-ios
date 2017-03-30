//
//  SlideViewController.swift
//  Patchr
//
//  Created by Jay Massena on 3/28/17.
//  Copyright © 2017 3meters. All rights reserved.
//

import Foundation
import SlideMenuControllerSwift

class SlideViewController: SlideMenuController {
    
    deinit {
        Log.v("\(self.className) released")
    }
}
