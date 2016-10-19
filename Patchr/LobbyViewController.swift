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
	var imageBackground = AirImageView(frame: CGRect.zero)
	var imageLogo		= AirImageView(frame: CGRect.zero)
	var buttonLogin		= AirButton()
	var buttonSignup	= AirButton()
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
		self.buttonGroup.anchorInCenter(withWidth: 228, height: 96)
		self.buttonLogin.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 44)
		self.buttonSignup.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 44)
		self.appName.align(above: self.buttonGroup, matchingCenterWithBottomPadding: 20, width: 228, height: 48)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		Reporting.screen("Lobby")
		
		self.view.endEditing(true)
		self.navigationController?.setNavigationBarHidden(true, animated: animated)
		self.setNeedsStatusBarAppearanceUpdate()
		if self.firstLaunch {
			self.imageLogo.anchorInCenter(withWidth: 72, height: 72)
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		
		if self.firstLaunch {
			
			Utils.delay(0.5){
				let spring = POPSpringAnimation(propertyNamed: kPOPViewFrame)
				spring?.toValue = NSValue(cgRect: self.imageLogo.frame.offsetBy(dx: 0, dy: -156))
				spring?.springBounciness = 10
				spring?.springSpeed = 8
				self.imageLogo.pop_add(spring, forKey: "moveUp")
				
				self.appName.fadeIn(duration: 0.5)
				self.buttonGroup.fadeIn(duration: 1.0)
			}
			
			Animation.bounce(view: self.imageLogo)
			
			self.firstLaunch = false
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
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
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
		self.imageBackground.image = UIImage(named: "imgLobbyBackground")
		self.imageBackground.contentMode = UIViewContentMode.scaleToFill
		self.view.addSubview(self.imageBackground)
		
		self.imageLogo.image = UIImage(named: "imgPatchrWhite")
		self.imageLogo.contentMode = UIViewContentMode.scaleAspectFill
		self.view.addSubview(self.imageLogo)
		
		self.appName.text = "Patchr"
		self.appName.textAlignment = NSTextAlignment.center
		self.view.addSubview(self.appName)
		
		self.buttonLogin.setTitle("LOG IN", for: .normal)
		self.buttonLogin.setTitleColor(Colors.white, for: .normal)
		self.buttonLogin.setTitleColor(Theme.colorTint, for: .highlighted)
		self.buttonLogin.borderColor = Colors.white
		self.buttonLogin.borderWidth = Theme.dimenButtonBorderWidth
		self.buttonLogin.cornerRadius = Theme.dimenButtonCornerRadius
		
		self.buttonSignup.setTitle("SIGN UP", for: .normal)
		self.buttonSignup.setTitleColor(Colors.white, for: .normal)
		self.buttonSignup.setTitleColor(Theme.colorTint, for: .highlighted)
		self.buttonSignup.borderColor = Colors.white
		self.buttonSignup.borderWidth = Theme.dimenButtonBorderWidth
		self.buttonSignup.cornerRadius = Theme.dimenButtonCornerRadius
		
		self.buttonGroup.addSubview(self.buttonLogin)
		self.buttonGroup.addSubview(self.buttonSignup)
		self.view.addSubview(self.buttonGroup)
		
		self.buttonLogin.addTarget(self, action: #selector(LobbyViewController.loginAction(sender:)), for: .touchUpInside)
		self.buttonSignup.addTarget(self, action: #selector(LobbyViewController.signupAction(sender:)), for: .touchUpInside)
		
		if self.firstLaunch {
			self.appName.alpha = 0.0
			self.buttonGroup.alpha = 0.0
		}
	}
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
}

