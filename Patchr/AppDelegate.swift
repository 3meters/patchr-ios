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
import Parse

let PAApplicationDidReceiveRemoteNotification = "PAApplicationDidReceiveRemoteNotification"
let PAapplicationDidBecomeActiveWithNonZeroBadge = "PAapplicationDidBecomeActiveWithNonZeroBadge"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var backgroundSessionCompletionHandler: (() -> Void)?
    
    class func appDelegate() -> AppDelegate {
        return UIApplication.sharedApplication().delegate as! AppDelegate
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        #if DEBUG
        AFNetworkActivityLogger.sharedLogger().startLogging()
        AFNetworkActivityLogger.sharedLogger().level = AFHTTPRequestLoggerLevel.AFLoggerLevelWarn
        #endif
        
        /* Light gray is better than black */
        window?.backgroundColor = Colors.windowColor
        UITabBar.appearance().selectedImageTintColor = Colors.brandColor
        /* 
         * Initialize Branch: The deepLinkHandler gets called every time the app opens.
         * That means it should be a good place to handle all initial routing.
         */
        Branch.getInstance().initSessionWithLaunchOptions(launchOptions, andRegisterDeepLinkHandler: { params, error in
            if error == nil {
                if let clickedBranchLink = params["+clicked_branch_link"] as? Bool where clickedBranchLink {
                    self.routeDeepLink(params, error: error)
                    return
                }                
            }
        })
        
        /* Load setting defaults */
        let defaultSettingsFile: NSString = NSBundle.mainBundle().pathForResource("DefaultSettings", ofType: "plist")!
        let settingsDictionary: NSDictionary = NSDictionary(contentsOfFile: defaultSettingsFile as String)!
        NSUserDefaults.standardUserDefaults().registerDefaults(settingsDictionary as [NSObject : AnyObject])
        
        /* Initialize Crashlytics */
        Fabric.with([Crashlytics()])
        
        /* Initialize Creative sdk */
        AdobeUXAuthManager.sharedManager().setAuthenticationParametersWithClientID(CREATIVE_SDK_CLIENT_ID, clientSecret: CREATIVE_SDK_CLIENT_SECRET, enableSignUp: false)
        
        /* Change default font for button bar items */
        let customFont = UIFont(name:"HelveticaNeue", size: 18)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: customFont!], forState: UIControlState.Normal)

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

        /* Get the latest on the authenticated user if we have one */
        if UserController.instance.authenticated {
            UserController.instance.signinAuto()
        }
        
        self.window?.tintColor = Colors.brandColor
        UISwitch.appearance().onTintColor = self.window?.tintColor
        
        self.registerForRemoteNotifications()
        
        /* Show initial controller */
        route()
        
        return true
    }
    
    func route() {
        
        /* Show initial controller */
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        /* If we have an authenticated user then start at the usual spot, otherwise start at the lobby scene. */
        
        if UserController.instance.authenticated {
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            if let controller = storyboard.instantiateViewControllerWithIdentifier("MainTabBarController") as? UIViewController {
                self.window?.setRootViewController(controller, animated: true)
            }
        }
        else {
            let storyboard: UIStoryboard = UIStoryboard(name: "Lobby", bundle: NSBundle.mainBundle())
            if let controller = storyboard.instantiateViewControllerWithIdentifier("SplashNavigationController") as? UIViewController {
                self.window?.setRootViewController(controller, animated: true)
            }
        }
        
        self.window?.makeKeyAndVisible()
    }
    
    func routeDeepLink(params: NSDictionary?, error: NSError?) {
        
        if let entityId = params!["entityId"] as? String, entitySchema = params!["entitySchema"] as? String {
            let storyBoard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            
            if entitySchema == "patch" {
                if let controller = storyBoard.instantiateViewControllerWithIdentifier("PatchDetailViewController") as? PatchDetailViewController {
                    controller.patchId = entityId
                    /* Navigation bar buttons */
                    var doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: controller, action: Selector("dismissAction:"))
                    controller.navigationItem.leftBarButtonItems = [doneButton]
                    var navController = UINavigationController()
                    navController.viewControllers = [controller]
                    UIViewController.topMostViewController()?.presentViewController(navController, animated: true, completion: nil)
                }
            }
            else if entitySchema == "message" {
                if let controller = storyBoard.instantiateViewControllerWithIdentifier("MessageDetailViewController") as? MessageDetailViewController {
                    controller.messageId = entityId
                    /* Navigation bar buttons */
                    var doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: controller, action: Selector("dismissAction:"))
                    controller.navigationItem.leftBarButtonItems = [doneButton]
                    var navController = UINavigationController()
                    navController.viewControllers = [controller]
                    UIViewController.topMostViewController()?.presentViewController(navController, animated: true, completion: nil)
                }
            }
        }
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
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        if Branch.getInstance().handleDeepLink(url) {
            NSLog("Branch handled deep link: \(url.absoluteString!)")
            return true
        }
        return false
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
    
    func application(application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> Int {
        if let controller = UIViewController.topMostViewController() {
            if controller is AirPhotoBrowser || controller is AirPhotoPreview {
                return Int(UIInterfaceOrientationMask.All.rawValue);
            }
            else {
                return Int(UIInterfaceOrientationMask.Portrait.rawValue);
            }
        }
        return Int(UIInterfaceOrientationMask.Portrait.rawValue);
    }
    
    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {
        /*
         * This gets called if the share extension isn't running when the background data task 
         * completes.
         */
        self.backgroundSessionCompletionHandler = completionHandler
        NSLog("handleEventsForBackgroundURLSession called")
        Shared.Toast("Message Posted!")
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
    
