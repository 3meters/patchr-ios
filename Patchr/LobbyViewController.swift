//
//  LobbyViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import pop

class LobbyViewController: UIViewController {
	
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
		self.buttonGroup.anchorInCenter(withWidth: 240, height: 96)
		self.buttonSignup.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 44)
		self.buttonLogin.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 44)
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
            
            UIView.animate(withDuration: 0.3
                , delay: 0
                , animations: { [weak self] in
                    self?.imageLogo.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                }
                , completion: { finished in
                    
                    UIView.animate(withDuration: 1.0
                        , delay: 0
                        , usingSpringWithDamping: 0.2
                        , initialSpringVelocity: 6.0
                        , options: []
                        , animations: { [weak self] in
                            self?.imageLogo.transform = .identity
                        }
                        , completion: { finished in
                            
                            UIView.animate(withDuration: 1.0
                                , delay: 0
                                , usingSpringWithDamping: 0.5
                                , initialSpringVelocity: 6.0
                                , options: [.curveEaseIn]
                                , animations: { [weak self] in
                                    self?.imageLogo.transform = CGAffineTransform(translationX: 0, y: -156)
                                }
                                , completion: { finished in
                                    if finished {
                                        self.appName.fadeIn(duration: 0.5)
                                        self.buttonGroup.fadeIn(duration: 1.0)
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
		self.setNeedsStatusBarAppearanceUpdate()
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
		
		self.buttonGroup.addSubview(self.buttonLogin)
		self.buttonGroup.addSubview(self.buttonSignup)
		self.view.addSubview(self.buttonGroup)
		
		self.buttonLogin.addTarget(self, action: #selector(loginAction(sender:)), for: .touchUpInside)
		self.buttonSignup.addTarget(self, action: #selector(signupAction(sender:)), for: .touchUpInside)
		
		if self.firstLaunch {
			self.appName.alpha = 0.0
			self.buttonGroup.alpha = 0.0
		}
	}
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }
    
    override var prefersStatusBarHidden: Bool {
        return UserDefaults.standard.bool(forKey: Prefs.statusBarHidden)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
}
