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
    
    
//      S3 Setup
//
//      {
//          key: 'AKIAIYU2FPHC2AOUG3CA',
//          secret: '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',
//          region: 'us-west-2',
//          bucket: 'aircandi-images',
//      }

    let PatchrS3Key    = "AKIAIYU2FPHC2AOUG3CA"
    let PatchrS3Secret = "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"
    


    @IBAction func testButtonAction(sender: AnyObject)
    {
        println("test")
    }
}