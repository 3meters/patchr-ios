//
//  AppDelegate.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-20.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics

let PAApplicationDidReceiveRemoteNotification = "PAApplicationDidReceiveRemoteNotification"
let PAapplicationDidBecomeActiveWithNonZeroBadge = "PAapplicationDidBecomeActiveWithNonZeroBadge"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    class func appDelegate() -> AppDelegate {
        return UIApplication.sharedApplication().delegate as! AppDelegate
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        #if DEBUG
        AFNetworkActivityLogger.sharedLogger().startLogging()
        AFNetworkActivityLogger.sharedLogger().level = AFHTTPRequestLoggerLevel.AFLoggerLevelWarn
        #endif
        
        /* Load setting defaults */
        let defaultSettingsFile: NSString = NSBundle.mainBundle().pathForResource("DefaultSettings", ofType: "plist")!
        let settingsDictionary: NSDictionary = NSDictionary(contentsOfFile: defaultSettingsFile as String)!
        NSUserDefaults.standardUserDefaults().registerDefaults(settingsDictionary as [NSObject : AnyObject])
        
        /* Initialize Crashlytics */
        Fabric.with([Crashlytics()])        

        /* Setup parse for push notifications */
        Parse.setApplicationId("EonZJ4FXEADijslgqXCkg37sOGpB7AB9lDYxoHtz", clientKey: "5QRFlRQ3j7gkxyJ2cBYbHTK98WRQhoHCnHdpEKSD")
        
        DataController.proxibase.registerInstallStandard {
            response, error in
            
            if let error = ServerError(error) {
                /*
                 * If install registration fails the device will not accurately track notifications.
                 */
                NSLog("Error during registerInstall: \(error)")
            }
        }

        /* If we have an authenticated user then start at the usual spot, otherwise start at the lobby scene. */
        if UserController.instance.authenticated {
			self.window?.rootViewController = UIStoryboard(
                name: "Main",
                bundle: NSBundle.mainBundle()).instantiateInitialViewController() as? UIViewController;
        } else {
            let rootController = UIStoryboard(
                name: "Lobby",
                bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("SplashNavigationController") as? UIViewController
            self.window?.rootViewController = rootController
        }
        
        /* Get the latest on the authenticated user if we have one */
        if UserController.instance.authenticated {
            UserController.instance.signinAuto()
        }
        
        self.window?.tintColor = Colors.brandColor
        UISwitch.appearance().onTintColor = self.window?.tintColor
        
        self.registerForRemoteNotifications()
        
        return true
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        NSNotificationCenter.defaultCenter().postNotificationName(Event.ApplicationDidEnterBackground.rawValue, object: nil)
    }

    func applicationWillEnterForeground(application: UIApplication){
        NSNotificationCenter.defaultCenter().postNotificationName(Event.ApplicationWillEnterForeground.rawValue, object: nil)
    }
    
    func applicationWillResignActive(application: UIApplication){
        NSNotificationCenter.defaultCenter().postNotificationName(Event.ApplicationWillResignActive.rawValue, object: nil)
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        
        if application.applicationIconBadgeNumber > 0 {
            NSNotificationCenter.defaultCenter().postNotificationName(PAapplicationDidBecomeActiveWithNonZeroBadge, object: self, userInfo: nil)
        }
        
        application.applicationIconBadgeNumber = 0
        
        if PFInstallation.currentInstallation().badge != 0 {
            PFInstallation.currentInstallation().badge = 0
            PFInstallation.currentInstallation().saveEventually(nil)
        }
        NSNotificationCenter.defaultCenter().postNotificationName(Event.ApplicationDidBecomeActive.rawValue, object: nil)
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let parseInstallation = PFInstallation.currentInstallation()
        parseInstallation.setDeviceTokenFromData(deviceToken)
        parseInstallation.saveInBackgroundWithBlock(nil)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject],
        fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
        var augmentedUserInfo = NSMutableDictionary(dictionary: userInfo)
        augmentedUserInfo["receivedInApplicationState"] = application.applicationState.rawValue
        NSNotificationCenter.defaultCenter().postNotificationName(PAApplicationDidReceiveRemoteNotification, object: self, userInfo: augmentedUserInfo as [NSObject : AnyObject])
        completionHandler(.NewData)
    }

    func registerForRemoteNotifications() {
        
        let application = UIApplication.sharedApplication()
        
        // http://stackoverflow.com/a/28742391/2247399
        if application.respondsToSelector("registerUserNotificationSettings:") {
            
            let types: UIUserNotificationType = (.Alert | .Badge | .Sound)
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(forTypes: types, categories: nil)
            
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
            
        } else {
            // Register for Push Notifications before iOS 8
            application.registerForRemoteNotificationTypes(.Alert | .Badge | .Sound)
        }
    }
}

extension UIApplication {
    
    func isInstalledViaAppStore() -> Bool {
        
    #if (arch(i386) || arch(x86_64)) && os(iOS)
        // Simulator http://stackoverflow.com/a/24869607/2247399
        return false
    #else
        let receiptURL = NSBundle.mainBundle().appStoreReceiptURL
        if receiptURL?.path?.rangeOfString("sandboxReceipt") == nil {
            return true
        }
        return false
    #endif
        
    }
}
    
