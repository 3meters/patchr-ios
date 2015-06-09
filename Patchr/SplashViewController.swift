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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.view.endEditing(true)
        self.logo?.imageView?.tintColor = AirUi.brandColor
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    @IBAction func guestButtonAction(sender: UIButton) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let destinationViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateInitialViewController() as! UIViewController
        appDelegate.window!.setRootViewController(destinationViewController, animated: true)
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
            animations: { () -> Void in
                // The animation enabling/disabling are to address a status bar
                // issue on the destination view controller. http://stackoverflow.com/a/8505364/2247399
                let oldState = UIView.areAnimationsEnabled()
                UIView.setAnimationsEnabled(false)
                self.rootViewController = rootViewController
                UIView.setAnimationsEnabled(oldState)
            }) { (_) -> Void in }
    }
}
