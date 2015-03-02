//
//  DebugViewController.swift
//  Patchr
//
//  Created by Brent on 2015-03-02.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import UIKit

class DebugViewController: UIViewController
{
    @IBOutlet weak var serverURIField: UITextField!

    let userDefaults = { NSUserDefaults.standardUserDefaults() }()
    
    override func viewWillAppear(animated: Bool) {
    
        super.viewWillAppear(animated)
        serverURIField.text = userDefaults.stringForKey("com.3meters.patchr.ios.serverURI")
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        userDefaults.setObject(serverURIField.text, forKey:"com.3meters.patchr.ios.serverURI")
    }

}