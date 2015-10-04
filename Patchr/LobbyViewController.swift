//
//  LobbyViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class LobbyViewController: UIViewController {
    
    @IBOutlet weak var logo: UIButton!
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setScreenName("Lobby")
        
        self.view.endEditing(true)
        self.logo.imageView!.tintColor(Colors.brandColor)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    @IBAction func guestButtonAction(sender: UIButton) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        if let controller = storyboard.instantiateViewControllerWithIdentifier("MainTabBarController") as? UIViewController {
            appDelegate.window!.setRootViewController(controller, animated: true)
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}

