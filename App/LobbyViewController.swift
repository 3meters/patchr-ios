//
//  LobbyViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import Pastel
import pop
import AlertOnboarding

class LobbyViewController: UIViewController {
	
	var appName	= AirLabelBanner()
	var imageBackground = PastelView(frame: CGRect.zero)
    var imageLogo: UIImageView!
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imageLogo.translatesAutoresizingMaskIntoConstraints = false
        self.imageLogo.widthAnchor.constraint(equalToConstant: 72).isActive = true
        self.imageLogo.heightAnchor.constraint(equalToConstant: 72).isActive = true
        
        if #available(iOS 11.0, *) {
            self.imageLogo.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor).isActive = true
            self.imageLogo.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        }
        else {
            self.imageLogo.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            self.imageLogo.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        }
    }
    
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.view.endEditing(true)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
	}
	
	override func viewDidAppear(_ animated: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if appDelegate.firstLaunch && !appDelegate.showedLaunchOnboarding {
            Reporting.track("view_onboarding_auto")
            showOnboarding(appFirstLaunch: true)
            appDelegate.showedLaunchOnboarding = true
        }
		if self.firstLaunch {
            startScene() {
                self.firstLaunch = false
            }
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.navigationController?.setNavigationBarHidden(false, animated: false)
	}

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        self.appName.sizeToFit()
        self.imageBackground.fillSuperview()
        self.buttonGroup.anchorInCenter(withWidth: 240, height: 96)
        self.buttonSignup.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 44)
        self.buttonLogin.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 44)
        self.buttonOnboard.alignUnder(self.buttonGroup, matchingCenterWithTopPadding: 36, width: 240, height: 44)
        self.appName.align(above: self.buttonGroup, matchingCenterWithBottomPadding: 20, width: self.appName.width(), height: 48)
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
	@objc func loginAction(sender: AnyObject?) {
		if MainController.instance.upgradeRequired {
			UIShared.compatibilityUpgrade()
		}
		else {
            Reporting.track("view_email_form")
			let controller = EmailViewController()
			controller.flow = .onboardLogin
			self.navigationController?.pushViewController(controller, animated: true)
		}
	}
	
	@objc func signupAction(sender: AnyObject?) {
		if MainController.instance.upgradeRequired {
			UIShared.compatibilityUpgrade()
		}
		else {
            Reporting.track("view_email_form")
            let controller = EmailViewController()
            controller.flow = .onboardSignup
            self.navigationController?.pushViewController(controller, animated: true)
		}
	}
	
    @objc func onboardingAction(sender: AnyObject?) {
        Reporting.track("view_onboarding")
        showOnboarding()
    }
    
    /*--------------------------------------------------------------------------------------------
     * Notifications
     *--------------------------------------------------------------------------------------------*/
    
    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/
	
	func initialize() {
        
        self.imageBackground.startPastelPoint = .topLeft
        self.imageBackground.endPastelPoint = .bottomRight
        self.imageBackground.animationDuration = 5.0
        self.imageBackground.setColors([Colors.accentColor, Colors.accentColor, Colors.brandColor])
        self.imageBackground.startAnimation()
        
        self.imageLogo = UIImageView(image: UIImage(named: "imgPatchrWhite"))
		self.imageLogo.contentMode = UIViewContentMode.scaleAspectFill
        self.imageLogo.backgroundColor = Colors.clear
        self.imageLogo.clipsToBounds = false

		self.appName.text = Strings.appName
		self.appName.textAlignment = NSTextAlignment.center
        
        self.view.addSubview(self.imageBackground)
        self.view.addSubview(self.imageLogo)
        self.view.addSubview(self.appName)
        
		self.buttonLogin.setTitle("log_in".localized(), for: .normal)
		self.buttonLogin.setTitleColor(Colors.white, for: .normal)
		self.buttonLogin.setTitleColor(Theme.colorTint, for: .highlighted)
		self.buttonLogin.borderColor = Colors.white
		self.buttonLogin.borderWidth = Theme.dimenButtonBorderWidth
		self.buttonLogin.cornerRadius = Theme.dimenButtonCornerRadius
		
		self.buttonSignup.setTitle("sign_up".localized(), for: .normal)
		self.buttonSignup.setTitleColor(Colors.white, for: .normal)
		self.buttonSignup.setTitleColor(Theme.colorTint, for: .highlighted)
		self.buttonSignup.borderColor = Colors.white
		self.buttonSignup.borderWidth = Theme.dimenButtonBorderWidth
		self.buttonSignup.cornerRadius = Theme.dimenButtonCornerRadius
        
        self.buttonOnboard.setTitle("onboard_me".localized(), for: .normal)
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
    
    func startScene(then: (() -> Void)? = nil) {
        
        UIView.animate(withDuration: 0.3
            , delay: 0
            , animations: { [weak self] in
                guard let this = self else { then?(); return; }
                this.imageLogo.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            }
            , completion: { finished in
                
                UIView.animate(withDuration: 1.0
                    , delay: 0
                    , usingSpringWithDamping: 0.2
                    , initialSpringVelocity: 6.0
                    , options: []
                    , animations: { [weak self] in
                        guard let this = self else { then?(); return; }
                        this.imageLogo.transform = .identity
                    }
                    , completion: { finished in
                        
                        UIView.animate(withDuration: 1.0
                            , delay: 0
                            , usingSpringWithDamping: 0.4
                            , initialSpringVelocity: 4.0
                            , options: [.curveEaseIn]
                            , animations: { [weak self] in
                                guard let this = self else { then?(); return; }
                                this.imageLogo.transform = CGAffineTransform(translationX: 0, y: -168)
                            }
                            , completion: { [weak self] finished in
                                guard let this = self else { then?(); return; }
                                this.appName.fadeIn(duration: 0.3)
                                this.buttonGroup.fadeIn(duration: 0.7)
                                this.buttonOnboard.fadeIn(duration: 0.7)
                                then?()
                        })
                })
        })
    }
    
    func showOnboarding(appFirstLaunch: Bool = false) {
        
        if self.alertView == nil {
            var images = [
                "imgCreateGroup",
                "imgInviteFriends",
                "imgGroupChat"]
            
            var titles = [
                "onboard_create_title".localized().uppercased(),
                "onboard_invite_title".localized().uppercased(),
                "onboard_features_title".localized().uppercased()
            ]
            
            var descriptions = [
                "onboard_create_description".localized(),
                "onboard_invite_description".localized(),
                "onboard_features_description".localized()
            ]
            
            if appFirstLaunch {
                images.insert("imgGroupChat", at: 0)
                titles.insert("onboard_welcome_title".localized().uppercased(), at: 0)
                descriptions.insert("onboard_welcome_description".localized(), at: 0)
            }
            
            self.alertView = AlertOnboarding(arrayOfImage: images, arrayOfTitle: titles, arrayOfDescription: descriptions)
            self.alertView.delegate = self
            self.alertView.colorButtonBottomBackground = Colors.accentColorFill
            self.alertView.colorButtonText = Colors.white
            self.alertView.colorCurrentPageIndicator = Colors.brandColor
            
            if Config.screenWidth > 414 {                
                self.alertView.percentageRatioWidth = (331 / Config.screenWidth)
                self.alertView.percentageRatioHeight = (588 / Config.screenHeight)
            }
            self.alertView.titleGotItButton = "onboard_got_it".localized().uppercased()
            self.alertView.titleSkipButton = "skip".localized().uppercased()
        }
        
        self.alertView.show()
    }
}

extension LobbyViewController: AlertOnboardingDelegate {
    func alertOnboardingSkipped(_ currentStep: Int, maxStep: Int) {
        Reporting.track("skip_onboarding")
    }
    
    func alertOnboardingCompleted() {
        Reporting.track("complete_onboarding")
    }
    
    func alertOnboardingNext(_ nextStep: Int) { }
}
