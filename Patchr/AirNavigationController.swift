//
//  AirNavigationController.swift
//  Patchr
//
//  Created by Jay Massena on 5/20/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import UIKit

class AirNavigationController: UINavigationController {
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    override var prefersStatusBarHidden: Bool {
        return UserDefaults.standard.bool(forKey: Prefs.statusBarHidden)
    }
    
    deinit {
        Log.v("\(self.className) released")
    }
}
