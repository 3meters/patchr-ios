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
    
    override func viewDidLoad() {
        //self.navigationController?.setNavigationBarHidden(true, animated: false)
        //        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
    }
    
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
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    @IBAction func guestButtonAction(sender: UIButton) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        if let controller = storyboard.instantiateViewControllerWithIdentifier("MainTabBarController") as? UIViewController {
            appDelegate.window!.setRootViewController(controller, animated: true)
        }
    }
}

extension UIWindow {
    
    func setRootViewController(rootViewController: UIViewController, animated: Bool) {
        
        if !animated {
            self.rootViewController = rootViewController
            return
        }
        
        UIView.transitionWithView(self,
            duration: 0.65,
            options: UIViewAnimationOptions.TransitionCrossDissolve,
            animations: {
                () -> Void in
                
                // The animation enabling/disabling are to address a status bar
                // issue on the destination view controller. http://stackoverflow.com/a/8505364/2247399
                let oldState = UIView.areAnimationsEnabled()
                UIView.setAnimationsEnabled(false)
                self.rootViewController = rootViewController
                UIView.setAnimationsEnabled(oldState)
            })
            { (_) -> Void in } // Trailing closure
    }
}