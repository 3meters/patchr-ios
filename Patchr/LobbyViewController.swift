//
//  LobbyViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import pop

class LobbyViewController: BaseViewController {
	
	var appName			= AirLabelBanner()
	var imageBackground = AirImageView(frame: CGRectZero)
	var imageLogo		= AirImageView(frame: CGRectZero)
	var buttonLogin		= AirButton()
	var buttonSignup	= AirButton()
	var buttonGuest		= AirLinkButton()
	var buttonGroup		= UIView()
	var firstLaunch		= true
	
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		super.loadView()
		initialize()
	}
    
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		self.imageBackground.fillSuperview()
		self.buttonGroup.anchorInCenterWithWidth(228, height: 96)
		self.buttonLogin.anchorTopCenterFillingWidthWithLeftAndRightPadding(0, topPadding: 0, height: 44)
		self.buttonSignup.anchorBottomCenterFillingWidthWithLeftAndRightPadding(0, bottomPadding: 0, height: 44)
		self.buttonGuest.alignUnder(self.buttonGroup, matchingCenterWithTopPadding: 120, width: 228, height: 44)
		self.appName.alignAbove(self.buttonGroup, matchingCenterWithBottomPadding: 20, width: 228, height: 48)
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		Reporting.screen("Lobby")
		
		self.view.endEditing(true)
		self.navigationController?.setNavigationBarHidden(true, animated: animated)
		self.setNeedsStatusBarAppearanceUpdate()
		if self.firstLaunch {
			self.imageLogo.anchorInCenterWithWidth(72, height: 72)
		}
	}
	
	override func viewDidAppear(animated: Bool) {
		
		if self.firstLaunch {
			
			Utils.delay(0.5){
				let spring = POPSpringAnimation(propertyNamed: kPOPViewFrame)
				spring.toValue = NSValue(CGRect: self.imageLogo.frame.offsetBy(dx: 0, dy: -156))
				spring.springBounciness = 10
				spring.springSpeed = 8
				self.imageLogo.pop_addAnimation(spring, forKey: "moveUp")
				
				self.appName.fadeIn(0.5)
				self.buttonGroup.fadeIn(1.0)
				self.buttonGuest.fadeIn(1.5)
			}
			
			Animation.bounce(self.imageLogo)
			
			self.firstLaunch = false
		}
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		self.navigationController?.setNavigationBarHidden(false, animated: animated)
		self.setNeedsStatusBarAppearanceUpdate()
	}
	
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
	func loginAction(sender: AnyObject?) {
		
		guard DataController.proxibase.versionIsValid else {
			UIShared.compatibilityUpgrade()
			return
		}
		
		let controller = LoginViewController()
		controller.onboardMode = OnboardMode.Login
		self.navigationController?.pushViewController(controller, animated: true)
	}
	
	func signupAction(sender: AnyObject?) {
		
		guard DataController.proxibase.versionIsValid else {
			UIShared.compatibilityUpgrade()
			return
		}
		
		let controller = LoginViewController()
		controller.onboardMode = OnboardMode.Signup
		self.navigationController?.pushViewController(controller, animated: true)
	}
	
	func guestAction(sender: UIButton) {

		guard DataController.proxibase.versionIsValid else {
			UIShared.compatibilityUpgrade()
			return
		}
		
		let controller = MainTabBarController()
		controller.selectedIndex = 0
		AppDelegate.appDelegate().window!.setRootViewController(controller, animated: true)
		Reporting.track("Entered as Guest", properties: nil)
	}
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
		self.view.accessibilityIdentifier = View.Lobby
		
		self.imageBackground.image = UIImage(named: "imgLobbyBackground")
		self.imageBackground.contentMode = UIViewContentMode.ScaleToFill
		self.view.addSubview(self.imageBackground)
		
		self.imageLogo.image = UIImage(named: "imgPatchrWhite")
		self.imageLogo.contentMode = UIViewContentMode.ScaleAspectFill
		self.view.addSubview(self.imageLogo)
		
		self.appName.text = "Patchr"
		self.appName.textAlignment = NSTextAlignment.Center
		self.view.addSubview(self.appName)
		
		self.buttonLogin.setTitle("LOG IN", forState: .Normal)
		self.buttonLogin.accessibilityIdentifier = "login_button"
		self.buttonLogin.setTitleColor(Colors.white, forState: .Normal)
		self.buttonLogin.setTitleColor(Theme.colorTint, forState: .Highlighted)
		self.buttonLogin.borderColor = Colors.white
		self.buttonLogin.borderWidth = Theme.dimenButtonBorderWidth
		self.buttonLogin.cornerRadius = Theme.dimenButtonCornerRadius
		
		self.buttonSignup.setTitle("SIGN UP", forState: .Normal)
		self.buttonSignup.accessibilityIdentifier = "signup_button"
		self.buttonSignup.setTitleColor(Colors.white, forState: .Normal)
		self.buttonSignup.setTitleColor(Theme.colorTint, forState: .Highlighted)
		self.buttonSignup.borderColor = Colors.white
		self.buttonSignup.borderWidth = Theme.dimenButtonBorderWidth
		self.buttonSignup.cornerRadius = Theme.dimenButtonCornerRadius
		
		self.buttonGroup.addSubview(self.buttonLogin)
		self.buttonGroup.addSubview(self.buttonSignup)
		self.view.addSubview(self.buttonGroup)
		
		self.buttonGuest.setTitle("skip", forState: .Normal)
		self.buttonGuest.accessibilityIdentifier = "guest_button"
		self.buttonGuest.setTitleColor(Colors.white, forState: .Normal)
		self.buttonGuest.setTitleColor(Theme.colorTint, forState: .Highlighted)
		self.buttonGuest.titleLabel?.font = Theme.fontLinkText
		self.view.addSubview(self.buttonGuest)
		
		self.buttonLogin.addTarget(self, action: #selector(LobbyViewController.loginAction(_:)), forControlEvents: .TouchUpInside)
		self.buttonSignup.addTarget(self, action: #selector(LobbyViewController.signupAction(_:)), forControlEvents: .TouchUpInside)
		self.buttonGuest.addTarget(self, action: #selector(LobbyViewController.guestAction(_:)), forControlEvents: .TouchUpInside)
		
		if self.firstLaunch {
			self.appName.alpha = 0.0
			self.buttonGroup.alpha = 0.0
			self.buttonGuest.alpha = 0.0
		}
	}
	
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}

