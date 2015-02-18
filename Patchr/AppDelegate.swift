//
//  AppDelegate.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-20.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        #if DEBUG
        AFNetworkActivityLogger.sharedLogger().startLogging()
        #endif
        
        let userId = NSUserDefaults.standardUserDefaults().stringForKey("com.3meters.patchr.ios.userId")
        let sessionKey = NSUserDefaults.standardUserDefaults().stringForKey("com.3meters.patchr.ios.sessionKey")
        let authenticatedUser = (userId != nil) && (sessionKey != nil)
        
        if authenticatedUser {
            self.window?.rootViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateInitialViewController() as? UIViewController;
        } else {
            let rootController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("SplashNavigationController") as? UIViewController
            self.window?.rootViewController = rootController
        }
        
        return true
    }
}

