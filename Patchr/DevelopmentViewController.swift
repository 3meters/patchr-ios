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
	@IBOutlet weak var statusBarHiddenSwitch: UISwitch!

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
        
        self.devModeSwitch.on = userDefaults.boolForKey(PatchrUserDefaultKey("devModeEnabled"))
		self.statusBarHiddenSwitch.on = userDefaults.boolForKey(PatchrUserDefaultKey("statusBarHidden"))
		self.serverUriField.text = userDefaults.stringForKey(PatchrUserDefaultKey("serverURI"))
		
		self.devModeSwitch.addTarget(self, action: Selector("devModeAction:"), forControlEvents: .TouchUpInside)
		self.statusBarHiddenSwitch.addTarget(self, action: Selector("statusBarAction:"), forControlEvents: .TouchUpInside)
		
		observerObject = TextFieldChangeObserver(serverUriField) {
			[unowned self] in
			self.updateSegmentControl()
		}
		uriAtStart = serverUriField.text!
        setScreenName("DevelopmentSettings")
	}

	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)

		userDefaults.setObject(serverUriField.text, forKey: PatchrUserDefaultKey("serverURI"))

		observerObject?.stopObserving()

		// If the URI changed and we were signed in then sign out
		if uriAtStart != serverUriField.text {
			if UserController.instance.authenticated {
				UserController.instance.signout()
			}
		}
	}
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    func devModeAction(sender: AnyObject) {
        userDefaults.setBool(devModeSwitch.on, forKey: PatchrUserDefaultKey("devModeEnabled"))
        if devModeSwitch.on {
            AudioController.instance.play(Sound.pop.rawValue)
        }
    }

	func statusBarAction(sender: AnyObject) {
		userDefaults.setBool(statusBarHiddenSwitch.on, forKey: PatchrUserDefaultKey("statusBarHidden"))
		UIApplication.sharedApplication().setStatusBarHidden(statusBarHiddenSwitch.on, withAnimation: UIStatusBarAnimation.Slide)
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
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
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
