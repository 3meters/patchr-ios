//
//  LobbyViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import pop
import AlertOnboarding

class LobbyViewController: UIViewController {
	
	var appName	= AirLabelBanner()
	var imageBackground = AirImageView(frame: CGRect.zero)
	var imageLogo = AirImageView(frame: CGRect.zero)
	var buttonLogin = AirButton()
	var buttonSignup = AirButton()
    var buttonOnboard = AirButton()
	var buttonGroup	= UIView()
    var alertView: AlertOnboarding!
	var firstLaunch	= true
	
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
		self.buttonGroup.anchorInCenter(withWidth: 240, height: 96)
		self.buttonSignup.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 44)
		self.buttonLogin.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 44)
        self.buttonOnboard.alignUnder(self.buttonGroup, matchingCenterWithTopPadding: 36, width: 240, height: 44)
		self.appName.align(above: self.buttonGroup, matchingCenterWithBottomPadding: 20, width: 228, height: 48)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		Reporting.screen("Lobby")
		
		self.view.endEditing(true)
		self.navigationController?.setNavigationBarHidden(true, animated: animated)
		if self.firstLaunch {
			self.imageLogo.anchorInCenter(withWidth: 72, height: 72)
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if appDelegate.firstLaunch {
            Reporting.track("Onboarding_displayed_first_launch")
            showOnboarding()
        }
		
		if self.firstLaunch {
            
            UIView.animate(withDuration: 0.3
                , delay: 0
                , animations: { [weak self] in
                    guard let this = self else { return }
                    this.imageLogo.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                }
                , completion: { finished in
                    
                    UIView.animate(withDuration: 1.0
                        , delay: 0
                        , usingSpringWithDamping: 0.2
                        , initialSpringVelocity: 6.0
                        , options: []
                        , animations: { [weak self] in
                            guard let this = self else { return }
                            this.imageLogo.transform = .identity
                        }
                        , completion: { finished in
                            
                            UIView.animate(withDuration: 1.0
                                , delay: 0
                                , usingSpringWithDamping: 0.4
                                , initialSpringVelocity: 4.0
                                , options: [.curveEaseIn]
                                , animations: { [weak self] in
                                    guard let this = self else { return }
                                    this.imageLogo.transform = CGAffineTransform(translationX: 0, y: -156)
                                }
                                , completion: { finished in
                                    if finished {
                                        self.appName.fadeIn(duration: 0.3)
                                        self.buttonGroup.fadeIn(duration: 0.7)
                                        self.buttonOnboard.fadeIn(duration: 0.7)
                                    }
                            })
                    })
            })
			self.firstLaunch = false
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.navigationController?.setNavigationBarHidden(false, animated: animated)
	}
	
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
	func loginAction(sender: AnyObject?) {
		if MainController.instance.upgradeRequired {
			UIShared.compatibilityUpgrade()
		}
		else {
			let controller = EmailViewController()
			controller.flow = .onboardLogin
			self.navigationController?.pushViewController(controller, animated: true)
		}
	}
	
	func signupAction(sender: AnyObject?) {

		if MainController.instance.upgradeRequired {
			UIShared.compatibilityUpgrade()
		}
		else {
			FireController.instance.isConnected() { connected in
				if connected == nil || !connected! {
					let message = "Creating a group requires a network connection."
					self.alert(title: "Not connected", message: message, cancelButtonTitle: "OK")
				}
				else {
					let controller = EmailViewController()
					controller.flow = .onboardCreate
					self.navigationController?.pushViewController(controller, animated: true)
				}
			}
		}
	}
	
    func onboardingAction(sender: AnyObject?) {
        Reporting.track("Onboarding_displayed_by_user")
        showOnboarding()
    }
    
    /*--------------------------------------------------------------------------------------------
     * Notifications
     *--------------------------------------------------------------------------------------------*/
    
    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/
	
	func initialize() {
        
		self.imageBackground.image = UIImage(named: "imgLobbyBackground")
		self.imageBackground.contentMode = UIViewContentMode.scaleToFill
		self.view.addSubview(self.imageBackground)
		
		self.imageLogo.image = UIImage(named: "imgPatchrWhite")
		self.imageLogo.contentMode = UIViewContentMode.scaleAspectFill
		self.view.addSubview(self.imageLogo)
		
		self.appName.text = "Patchr"
		self.appName.textAlignment = NSTextAlignment.center
		self.view.addSubview(self.appName)
		
		self.buttonLogin.setTitle("Log in to an existing group", for: .normal)
		self.buttonLogin.setTitleColor(Colors.white, for: .normal)
		self.buttonLogin.setTitleColor(Theme.colorTint, for: .highlighted)
		self.buttonLogin.borderColor = Colors.white
		self.buttonLogin.borderWidth = Theme.dimenButtonBorderWidth
		self.buttonLogin.cornerRadius = Theme.dimenButtonCornerRadius
		
		self.buttonSignup.setTitle("Create a new Patchr group", for: .normal)
		self.buttonSignup.setTitleColor(Colors.white, for: .normal)
		self.buttonSignup.setTitleColor(Theme.colorTint, for: .highlighted)
		self.buttonSignup.borderColor = Colors.white
		self.buttonSignup.borderWidth = Theme.dimenButtonBorderWidth
		self.buttonSignup.cornerRadius = Theme.dimenButtonCornerRadius
        
        self.buttonOnboard.setTitle("Onboard me!", for: .normal)
        self.buttonOnboard.setTitleColor(Colors.white, for: .normal)
        self.buttonOnboard.setTitleColor(Theme.colorTint, for: .highlighted)
        self.buttonOnboard.borderColor = Colors.clear
		
		self.buttonGroup.addSubview(self.buttonLogin)
		self.buttonGroup.addSubview(self.buttonSignup)
        self.view.addSubview(self.buttonOnboard)
		self.view.addSubview(self.buttonGroup)
		
		self.buttonLogin.addTarget(self, action: #selector(loginAction(sender:)), for: .touchUpInside)
		self.buttonSignup.addTarget(self, action: #selector(signupAction(sender:)), for: .touchUpInside)
        self.buttonOnboard.addTarget(self, action: #selector(onboardingAction(sender:)), for: .touchUpInside)
		
		if self.firstLaunch {
			self.appName.alpha = 0.0
			self.buttonGroup.alpha = 0.0
            self.buttonOnboard.alpha = 0.0
		}
	}
    
    func showOnboarding() {
        
        if self.alertView == nil {
            let images = [
                "create_group",
                "invite_friends_2",
                "group_chat"]
            
            let titles = [
                "Create a Group".uppercased(),
                "Invite Members".uppercased(),
                "Carry On!".uppercased()
            ]
            
            let descriptions = [
                "Patchr groups are a modern way to organize all your group messaging for free!",
                "Select members from your contacts and we handle the rest! We email them an invite, help them install Patchr and gently launch them into your group.",
                "Patchr has brilliant messaging features: great privacy and sharing controls, photo search and editing, and offline posting."
            ]
            
            self.alertView = AlertOnboarding(arrayOfImage: images, arrayOfTitle: titles, arrayOfDescription: descriptions)
            self.alertView.delegate = self
            self.alertView.colorButtonBottomBackground = Colors.accentColorFill
            self.alertView.colorButtonText = Colors.white
            self.alertView.colorCurrentPageIndicator = Colors.brandColor
            if Config.screenWidth > 414 {                
                self.alertView.percentageRatioWidth = (331 / Config.screenWidth)
                self.alertView.percentageRatioHeight = (588 / Config.screenHeight)
            }
            self.alertView.titleGotItButton = "Got it!".uppercased()
        }
        
        self.alertView.show()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
}

extension LobbyViewController: AlertOnboardingDelegate {
    func alertOnboardingSkipped(_ currentStep: Int, maxStep: Int) {
        Reporting.track("Onboarding_skipped")
    }
    
    func alertOnboardingCompleted() {
        Reporting.track("Onboarding_completed")
    }
    
    func alertOnboardingNext(_ nextStep: Int) { }
}
