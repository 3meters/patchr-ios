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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var backgroundSessionCompletionHandler: (() -> Void)?
    
    class func appDelegate() -> AppDelegate {
        return UIApplication.sharedApplication().delegate as! AppDelegate
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        Log.d("Patchr launching...")
        if launchOptions != nil {
            Log.d(String(format: "%@", launchOptions!))
        }
        
        let keys = PatchrKeys()
        
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
        AdobeUXAuthManager.sharedManager().setAuthenticationParametersWithClientID(keys.creativeSdkClientId(), clientSecret: keys.creativeSdkClientSecret(), enableSignUp: false)
        
        /* Change default font for button bar items */
        let customFont = UIFont(name:"HelveticaNeue", size: 18)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: customFont!], forState: UIControlState.Normal)

        /* Setup parse for push notifications */
        Parse.setApplicationId(keys.parseApplicationId(), clientKey: keys.parseApplicationKey())
        
        /* Get the latest on the authenticated user if we have one */
        if UserController.instance.authenticated {
            UserController.instance.signinAuto()
            /*
            * Register this install with the service. If install registration fails the
            * device will not accurately track notifications.
            */
            DataController.proxibase.registerInstallStandard {
                response, error in
                if let error = ServerError(error) {
                    Log.w("Error during registerInstall: \(error)")
                }
            }
        }
        else {
            DataController.proxibase.registerInstallStandard {
                response, error in
                if let error = ServerError(error) {
                    Log.w("Error during registerInstall: \(error)")
                }
            }
        }

        self.window?.tintColor = Colors.brandColor
        UISwitch.appearance().onTintColor = self.window?.tintColor
        
        NotificationController.instance.registerForRemoteNotifications()
        
        /* Show initial controller */
        route()
        
        return true
    }
    
    /*--------------------------------------------------------------------------------------------
    * Routing
    *--------------------------------------------------------------------------------------------*/
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        if Branch.getInstance().handleDeepLink(url) {
            Log.d("Branch handled deep link: \(url.absoluteString!)")
            return true
        }
        return false
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

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
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
        NSNotificationCenter.defaultCenter().postNotificationName(Event.ApplicationDidBecomeActive.rawValue, object: nil)
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
    
    /*--------------------------------------------------------------------------------------------
    * Notifications
    *--------------------------------------------------------------------------------------------*/
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        NotificationController.instance.didRegisterForRemoteNotificationsWithDeviceToken(application, deviceToken: deviceToken)
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        NotificationController.instance.didFailToRegisterForRemoteNotificationsWithError(application, error: error)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        /*
         * This delegate method offers an opportunity for applications with the "remote-notification" 
         * background mode to fetch appropriate new data in response to an incoming remote notification. 
         * You should call the fetchCompletionHandler as soon as you're finished performing that operation, 
         * so the system can accurately estimate its power and data cost.
         * 
         * This method will be invoked even if the application was launched or resumed because of the 
         * remote notification. The respective delegate methods will be invoked first. Note that this 
         * behavior is in contrast to application:didReceiveRemoteNotification:, which is not called in 
         * those cases, and which will not be invoked if this method is implemented. 
         *
         * If app is in the background, this is called if the user taps on the notification in the
         * pulldown tray.
         */
        NotificationController.instance.didReceiveRemoteNotification(application, userInfo: userInfo, fetchCompletionHandler: completionHandler)
    }

    /*--------------------------------------------------------------------------------------------
    * Background Sessions
    *--------------------------------------------------------------------------------------------*/
    
    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {
        /* 
         * Applications using an NSURLSession with a background configuration may be launched or resumed in the background in order to handle the
         * completion of tasks in that session, or to handle authentication. This method will be called with the identifier of the session needing
         * attention. Once a session has been created from a configuration object with that identifier, the session's delegate will begin receiving
         * callbacks. If such a session has already been created (if the app is being resumed, for instance), then the delegate will start receiving
         * callbacks without any action by the application. You should call the completionHandler as soon as you're finished handling the callbacks.
         *
         * This gets called if the share extension isn't running when the background data task 
         * completes. Use the identifier to reconstitute the URLSession.
         */
        self.backgroundSessionCompletionHandler = completionHandler
        Log.d("handleEventsForBackgroundURLSession called")
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
    
