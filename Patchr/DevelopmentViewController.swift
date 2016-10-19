//
//  DebugViewController.swift
//  Patchr
//
//  Created by Brent on 2015-03-02.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage

class DevelopmentViewController: UIViewController {
    
    var uriAtStart: String = ""
    let userDefaults = { UserDefaults.standard }()
	
	var enableDevModeLabel		= AirLabelDisplay()
	var enableDevModeSwitch		= UISwitch()
	var serverUriField			= AirTextField()
	var serverAddressOption		: UISegmentedControl!
	var clearImageCacheButton	= AirButton()
	var statusBarHiddenLabel	= AirLabelDisplay()
	var statusBarHiddenSwitch	= UISwitch()

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		super.loadView()
		initialize()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		self.userDefaults.set(serverUriField.text, forKey: PatchrUserDefaultKey(subKey: "serverUri"))

		/* If the URI changed and we were signed in then sign out */
		if self.uriAtStart != self.serverUriField.text {
			UserController.instance.logout()
		}
	}
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		let contentWidth = self.view.width() - 32
		let navHeight = self.navigationController?.navigationBar.height() ?? 0
		let statusHeight = UIApplication.shared.statusBarFrame.size.height

		self.enableDevModeLabel.sizeToFit()
		self.enableDevModeLabel.anchorTopLeft(withLeftPadding: 16, topPadding: statusHeight + navHeight + 24, width: contentWidth - (self.enableDevModeSwitch.width() + 8), height: self.enableDevModeLabel.height())
		self.enableDevModeSwitch.align(toTheRightOf: self.enableDevModeLabel, matchingCenterWithLeftPadding: 8, width: self.enableDevModeSwitch.width(), height: self.enableDevModeSwitch.height())
		
		self.statusBarHiddenLabel.sizeToFit()
		self.statusBarHiddenLabel.alignUnder(self.enableDevModeLabel, matchingLeftWithTopPadding: 24, width: contentWidth - (self.statusBarHiddenSwitch.width() + 8), height: self.statusBarHiddenLabel.height())
		self.statusBarHiddenSwitch.align(toTheRightOf: self.statusBarHiddenLabel, matchingCenterWithLeftPadding: 8, width: self.statusBarHiddenSwitch.width(), height: self.statusBarHiddenSwitch.height())
		
		self.serverUriField.alignUnder(self.statusBarHiddenLabel, matchingLeftWithTopPadding: 8, width: contentWidth, height: 48)
		self.serverAddressOption.alignUnder(self.serverUriField, matchingCenterWithTopPadding: 8, width: 200, height: 32)
		self.clearImageCacheButton.alignUnder(self.serverAddressOption, centeredFillingWidthWithLeftAndRightPadding: 16, topPadding: 24, height: 48)
	}
    
    func enableDevModeAction(sender: AnyObject) {
        self.userDefaults.set(enableDevModeSwitch.isOn, forKey: PatchrUserDefaultKey(subKey: "enableDevModeAction"))
        if self.enableDevModeSwitch.isOn {
            AudioController.instance.play(sound: Sound.pop.rawValue)
        }
    }

	func statusBarHiddenAction(sender: AnyObject) {
		self.userDefaults.set(statusBarHiddenSwitch.isOn, forKey: PatchrUserDefaultKey(subKey: "statusBarHidden"))
		UIApplication.shared.setStatusBarHidden(statusBarHiddenSwitch.isOn, with: UIStatusBarAnimation.slide)
		self.view.setNeedsLayout()
	}
	
	func serverAddressOptionAction(sender: AnyObject) {
		if self.serverAddressOption.selectedSegmentIndex == 0 {
			self.serverUriField.text = DataController.proxibase.ProductionURI
		}
		else if self.serverAddressOption.selectedSegmentIndex == 1 {
			self.serverUriField.text = DataController.proxibase.StagingURI
		}
	}
    
    func clearImageCacheAction(sender: AnyObject) {
        let imageCache = SDImageCache.shared()
        imageCache?.clearDisk()
        imageCache?.clearMemory()
        UIShared.Toast(message: "Image cache cleared")
        AudioController.instance.play(sound: Sound.pop.rawValue)        
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		
		Reporting.screen("DevelopmentSettings")
		self.view.backgroundColor = Theme.colorBackgroundForm
		
		self.enableDevModeSwitch.isOn = userDefaults.bool(forKey: PatchrUserDefaultKey(subKey: "enableDevModeAction"))
		self.statusBarHiddenSwitch.isOn = userDefaults.bool(forKey: PatchrUserDefaultKey(subKey: "statusBarHidden"))
		self.serverUriField.text = userDefaults.string(forKey: PatchrUserDefaultKey(subKey: "serverUri"))
		
		self.enableDevModeLabel.text = "Enable development mode:"
		self.statusBarHiddenLabel.text = "Status bar hidden:"
		self.clearImageCacheButton.setTitle("Clear image cache".uppercased(), for: .normal)
		self.serverUriField.placeholder = "Server address"
		self.serverAddressOption = UISegmentedControl(items: ["Production", "Staging"])

		updateSegmentControl()
		
		self.view.addSubview(self.enableDevModeLabel)
		self.view.addSubview(self.enableDevModeSwitch)
		self.view.addSubview(self.serverUriField)
		self.view.addSubview(self.serverAddressOption)
		self.view.addSubview(self.clearImageCacheButton)
		self.view.addSubview(self.statusBarHiddenLabel)
		self.view.addSubview(self.statusBarHiddenSwitch)
		
		self.enableDevModeSwitch.addTarget(self, action: #selector(DevelopmentViewController.enableDevModeAction(sender:)), for: .touchUpInside)
		self.statusBarHiddenSwitch.addTarget(self, action: #selector(DevelopmentViewController.statusBarHiddenAction(sender:)), for: .touchUpInside)
		self.serverAddressOption.addTarget(self, action: #selector(DevelopmentViewController.serverAddressOptionAction(sender:)), for: .valueChanged)
		self.clearImageCacheButton.addTarget(self, action: #selector(DevelopmentViewController.clearImageCacheAction(sender:)), for: .touchUpInside)
		
		uriAtStart = self.serverUriField.text!
	}
	
    private func updateSegmentControl() {
        if serverUriField.text == DataController.proxibase.ProductionURI {
            serverAddressOption.selectedSegmentIndex = 0
        }
        else if serverUriField.text == DataController.proxibase.StagingURI {
            serverAddressOption.selectedSegmentIndex = 1
        }
        else {
            serverAddressOption.selectedSegmentIndex = -1 /*none*/
        }
    }
}
