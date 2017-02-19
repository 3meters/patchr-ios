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

class DevelopmentViewController: BaseViewController {
    
	var enableDevModeLabel		= AirLabelDisplay()
	var enableDevModeSwitch		= UISwitch()
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
		
		self.clearImageCacheButton.alignUnder(self.statusBarHiddenLabel, centeredFillingWidthWithLeftAndRightPadding: 16, topPadding: 24, height: 48)
	}
    
    func enableDevModeAction(sender: AnyObject) {
        UserDefaults.standard.set(enableDevModeSwitch.isOn, forKey: Prefs.developerMode)
        if self.enableDevModeSwitch.isOn {
            AudioController.instance.play(sound: Sound.pop.rawValue)
        }
    }

	func statusBarHiddenAction(sender: AnyObject) {
		UserDefaults.standard.set(statusBarHiddenSwitch.isOn, forKey: Prefs.statusBarHidden)
        self.statusBarHidden = statusBarHiddenSwitch.isOn
		self.view.setNeedsLayout()
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
	
	override func initialize() {
        super.initialize()
		
		Reporting.screen("DevelopmentSettings")
		self.view.backgroundColor = Theme.colorBackgroundForm
		
		self.enableDevModeSwitch.isOn = UserDefaults.standard.bool(forKey: Prefs.developerMode)
		self.statusBarHiddenSwitch.isOn = UserDefaults.standard.bool(forKey: Prefs.statusBarHidden)
		
		self.enableDevModeLabel.text = "Enable development mode:"
		self.statusBarHiddenLabel.text = "Status bar hidden:"
		self.clearImageCacheButton.setTitle("Clear image cache".uppercased(), for: .normal)
		
		self.view.addSubview(self.enableDevModeLabel)
		self.view.addSubview(self.enableDevModeSwitch)
		self.view.addSubview(self.clearImageCacheButton)
		self.view.addSubview(self.statusBarHiddenLabel)
		self.view.addSubview(self.statusBarHiddenSwitch)
		
		self.enableDevModeSwitch.addTarget(self, action: #selector(DevelopmentViewController.enableDevModeAction(sender:)), for: .touchUpInside)
		self.statusBarHiddenSwitch.addTarget(self, action: #selector(DevelopmentViewController.statusBarHiddenAction(sender:)), for: .touchUpInside)
		self.clearImageCacheButton.addTarget(self, action: #selector(DevelopmentViewController.clearImageCacheAction(sender:)), for: .touchUpInside)
	}
}
