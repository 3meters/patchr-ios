//
//  LobbyViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class LobbyViewController: BaseViewController {
	
	var appName			= AirLabelBanner()
	var imageBackground = AirImageView(frame: CGRectZero)
	var imageLogo		= AirImageView(frame: CGRectZero)
	var buttonLogin		= AirButton()
	var buttonSignup	= AirButton()
	var buttonGuest		= AirLinkButton()
	var buttonGroup		= UIView()
	
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setScreenName("Lobby")
        
        self.view.endEditing(true)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.setNeedsStatusBarAppearanceUpdate()
    }
	
	override func loadView() {
		super.loadView()
		initialize()
	}
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		self.imageBackground.fillSuperviewWithLeftPadding(-24, rightPadding: -24, topPadding: -26, bottomPadding: -36)
		self.buttonGroup.anchorInCenterWithWidth(228, height: 96)
		self.buttonLogin.anchorTopCenterFillingWidthWithLeftAndRightPadding(0, topPadding: 0, height: 44)
		self.buttonSignup.anchorBottomCenterFillingWidthWithLeftAndRightPadding(0, bottomPadding: 0, height: 44)
		self.buttonGuest.alignUnder(self.buttonGroup, matchingCenterWithTopPadding: 120, width: 228, height: 44)
		self.appName.alignAbove(self.buttonGroup, matchingCenterWithBottomPadding: 20, width: 228, height: 48)
		self.imageLogo.alignAbove(self.appName, matchingCenterWithBottomPadding: -6, width: 100, height: 100)
	}
	
	func loginAction(sender: AnyObject?) {
		
		guard DataController.proxibase.versionIsValid else {
			Shared.compatibilityUpgrade()
			return
		}
		
		let controller = LoginViewController()
		controller.onboardMode = OnboardMode.Login
		self.navigationController?.pushViewController(controller, animated: true)
	}
	
	func signupAction(sender: AnyObject?) {
		
		guard DataController.proxibase.versionIsValid else {
			Shared.compatibilityUpgrade()
			return
		}
		
		let controller = LoginViewController()
		controller.onboardMode = OnboardMode.Signup
		self.navigationController?.pushViewController(controller, animated: true)
	}
	
	func guestAction(sender: UIButton) {

		guard DataController.proxibase.versionIsValid else {
			Shared.compatibilityUpgrade()
			return
		}
		
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		let controller = MainTabBarController()
		controller.selectedIndex = 0
		appDelegate.window!.setRootViewController(controller, animated: true)
	}
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
		self.imageBackground.image = UIImage(named: "imgCityScape")
		self.imageBackground.contentMode = UIViewContentMode.ScaleAspectFill
		self.imageBackground.parallaxIntensity = -40
		self.view.addSubview(self.imageBackground)
		
		self.imageLogo.image = UIImage(named: "imgPatchr")
		self.imageLogo.contentMode = UIViewContentMode.ScaleAspectFill
		self.view.addSubview(self.imageLogo)
		
		self.appName.text = "Patchr"
		self.appName.textAlignment = NSTextAlignment.Center
		self.view.addSubview(self.appName)
		
		self.buttonLogin.setTitle("LOG IN", forState: .Normal)
		self.buttonLogin.setTitleColor(Colors.white, forState: .Normal)
		self.buttonLogin.setTitleColor(Theme.colorTint, forState: .Highlighted)
		self.buttonLogin.borderColor = Colors.white
		self.buttonLogin.borderWidth = Theme.dimenButtonBorderWidth
		self.buttonLogin.cornerRadius = Theme.dimenButtonCornerRadius
		
		self.buttonSignup.setTitle("SIGN UP", forState: .Normal)
		self.buttonSignup.setTitleColor(Colors.white, forState: .Normal)
		self.buttonSignup.setTitleColor(Theme.colorTint, forState: .Highlighted)
		self.buttonSignup.borderColor = Colors.white
		self.buttonSignup.borderWidth = Theme.dimenButtonBorderWidth
		self.buttonSignup.cornerRadius = Theme.dimenButtonCornerRadius
		
		self.buttonGroup.addSubview(self.buttonLogin)
		self.buttonGroup.addSubview(self.buttonSignup)
		self.view.addSubview(self.buttonGroup)
		
		self.buttonGuest.setTitle("skip", forState: .Normal)
		self.buttonGuest.setTitleColor(Colors.white, forState: .Normal)
		self.buttonGuest.setTitleColor(Theme.colorTint, forState: .Highlighted)
		self.buttonGuest.titleLabel?.font = Theme.fontLinkText
		self.view.addSubview(self.buttonGuest)
		
		self.buttonLogin.addTarget(self, action: Selector("loginAction:"), forControlEvents: .TouchUpInside)
		self.buttonSignup.addTarget(self, action: Selector("signupAction:"), forControlEvents: .TouchUpInside)
		self.buttonGuest.addTarget(self, action: Selector("guestAction:"), forControlEvents: .TouchUpInside)
	}
	
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
	
}

