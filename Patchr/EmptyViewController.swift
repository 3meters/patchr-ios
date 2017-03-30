//
//  BaseViewController.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import pop

class EmptyViewController: UIViewController {
    
    var appName			= AirLabelBanner()
    var imageBackground = UIImageView(frame: CGRect.zero)
    var imageLogo		= UIImageView(frame: CGRect.zero)
    var scenePlayed		= false
		
	/*--------------------------------------------------------------------------------------------
	* MARK: - Lifecycle
	*--------------------------------------------------------------------------------------------*/
    
    override func loadView() {
        super.loadView()
        initialize()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        self.imageBackground.fillSuperview()
        self.appName.anchorInCenter(withWidth: 228, height: 48)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.view.endEditing(true)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        self.setNeedsStatusBarAppearanceUpdate()
        self.imageLogo.anchorInCenter(withWidth: 72, height: 72)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.setNeedsStatusBarAppearanceUpdate()
    }

    deinit {
        Log.v("\(self.className) released")
    }

    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/
    
    func initialize() {
        
        self.imageBackground.image = UIImage(named: "imgLobbyBackground")
        self.imageBackground.contentMode = UIViewContentMode.scaleToFill
        
        self.imageLogo.image = UIImage(named: "imgPatchrWhite")
        self.imageLogo.contentMode = UIViewContentMode.scaleAspectFill
        
        self.appName.text = "Patchr"
        self.appName.textAlignment = NSTextAlignment.center
        
        self.view.addSubview(self.imageBackground)
        self.view.addSubview(self.imageLogo)
        self.view.addSubview(self.appName)
        
        self.appName.alpha = 0.0
    }
    
    func startScene(then: (() -> Void)? = nil) {
        
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
                                    self.appName.fadeIn(duration: 0.5) { finished in
                                        self.scenePlayed = true
                                        then?()
                                    }
                                }
                        })
                })
        })
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
