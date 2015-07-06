//
//  DebugViewController.swift
//  Patchr
//
//  Created by Brent on 2015-03-02.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import UIKit

class DevelopmentViewController: UIViewController {
    
    var uriAtStart: String = ""
    var observerObject: TextFieldChangeObserver?
    let userDefaults = { NSUserDefaults.standardUserDefaults() }()
    
	@IBOutlet weak var serverUriField: UITextField!
	@IBOutlet weak var serverTargetOption: UISegmentedControl!
    @IBOutlet weak var devModeSwitch: UISwitch!

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
        
        devModeSwitch.on = userDefaults.boolForKey(Utils.PatchrUserDefaultKey("devModeEnabled"))
		serverUriField.text = userDefaults.stringForKey(Utils.PatchrUserDefaultKey("serverURI"))
        
		observerObject = TextFieldChangeObserver(serverUriField) {
			[unowned self] in
			self.updateSegmentControl()
		}
		uriAtStart = serverUriField.text
	}

	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)

		userDefaults.setObject(serverUriField.text, forKey: Utils.PatchrUserDefaultKey("serverURI"))

		observerObject?.stopObserving()

		// If the URI changed and we were signed in then sign out
		if uriAtStart != serverUriField.text {
			if UserController.instance.authenticated {
				DataController.proxibase.signOut() {
					response, error in
                    
                    if let error = ServerError(error) {
                        self.handleError(error)
                    }
                }
			}
		}
	}
    
    @IBAction func devModeAction(sender: AnyObject) {
        userDefaults.setBool(devModeSwitch.on, forKey: Utils.PatchrUserDefaultKey("devModeEnabled"))
        if devModeSwitch.on {
            AudioController.instance.play(Sound.pop.rawValue)
        }
    }

	@IBAction func serverControlAction(sender: AnyObject) {
		if serverTargetOption.selectedSegmentIndex == 0 {
			serverUriField.text = DataController.proxibase.ProductionURI
		}
		else if serverTargetOption.selectedSegmentIndex == 1 {
			serverUriField.text = DataController.proxibase.StagingURI
		}
	}
    
    @IBAction func clearImageCacheAction(sender: AnyObject) {
        let imageCache = SDImageCache.sharedImageCache()
        imageCache.clearDisk()
        imageCache.clearMemory()
        Shared.Toast("Image cache cleared")
        AudioController.instance.play(Sound.pop.rawValue)        
    }
    
    private func updateSegmentControl() {
        if serverUriField.text == DataController.proxibase.ProductionURI {
            serverTargetOption.selectedSegmentIndex = 0
        }
        else if serverUriField.text == DataController.proxibase.StagingURI {
            serverTargetOption.selectedSegmentIndex = 1
        }
        else {
            serverTargetOption.selectedSegmentIndex = -1 /*none*/
        }
    }
}
