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
        
        // If the connection to the database is considered valid, then start at the usual spot, otherwise start at the splash scene.
        
        if ProxibaseClient.sharedInstance.authenticated {
            self.window?.rootViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateInitialViewController() as? UIViewController;
        } else {
            let rootController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("SplashNavigationController") as? UIViewController
            self.window?.rootViewController = rootController
        }
        
        return true
    }
}

