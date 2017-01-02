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
        
        self.appName.alpha = 0.0
    }
    
    func startScene(then: (() -> Void)? = nil) {
        
        Utils.delay(0.5) {
            let spring = POPSpringAnimation(propertyNamed: kPOPViewFrame)
            spring?.toValue = NSValue(cgRect: self.imageLogo.frame.offsetBy(dx: 0, dy: -156))
            spring?.springBounciness = 10
            spring?.springSpeed = 8
            self.imageLogo.pop_add(spring, forKey: "moveUp")
            self.appName.fadeIn(duration: 0.5) { finished in
                self.scenePlayed = true
                then?()
            }
        }
        
        Animation.bounce(view: self.imageLogo)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
}
