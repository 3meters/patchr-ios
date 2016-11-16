//
//  AppDelegate.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-20.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import Keys
import AFNetworking
import AFNetworkActivityLogger
import AWSCore
import AWSS3
import Branch
import Bugsnag
import Firebase
import FirebaseRemoteConfig

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var firstLaunch: Bool = false

    /*--------------------------------------------------------------------------------------------
    * Delegate methods
    *--------------------------------------------------------------------------------------------*/
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        Log.prepare()
        Log.i("Patchr launching...")
        
        /* Initialize Firebase */
        FIRApp.configure()
        //FIRDatabase.setLoggingEnabled(false)
        
        /* Remote config */
        FIRRemoteConfig.remoteConfig().fetch { status, error in
            if (status == FIRRemoteConfigFetchStatus.success) {
                
                if FIRRemoteConfig.remoteConfig().activateFetched() {
                    Log.d("Remote config activated", breadcrumb: true)
                }
                
                /* Default config for AWS */
                let access = FIRRemoteConfig.remoteConfig().configValue(forKey: "aws_access_key").stringValue!
                let secret = FIRRemoteConfig.remoteConfig().configValue(forKey: "aws_secret_key").stringValue!
                let credProvider = AWSStaticCredentialsProvider(accessKey: access, secretKey: secret)
                let serviceConfig = AWSServiceConfiguration(region: AWSRegionType(rawValue: 3/*'us-west-2'*/)!, credentialsProvider: credProvider)
                AWSServiceManager.default().defaultServiceConfiguration = serviceConfig
            }
            else {
                Log.d("Remote config not fetched", breadcrumb: true)
                Log.d("Error \(error!.localizedDescription)", breadcrumb: true)
            }
        }
        
        /* Initialize Bugsnag */
        Bugsnag.start(withApiKey: BUGSNAG_KEY)
        
        #if DEBUG
        AFNetworkActivityLogger.shared().startLogging()
        AFNetworkActivityLogger.shared().level = AFHTTPRequestLoggerLevel.AFLoggerLevelFatal
        #endif

        /* Flag first launch for special treatment */
        if !UserDefaults.standard.bool(forKey: "firstLaunch") {
            UserDefaults.standard.set(true, forKey: "firstLaunch")
            self.firstLaunch = true
            Reporting.track("Launched for First Time")
        }
        
        self.window = UIWindow(frame: UIScreen.main.bounds)

        /* Load setting defaults */
        let defaultSettingsFile: NSString = Bundle.main.path(forResource: "DefaultSettings", ofType: "plist")! as NSString
        let settingsDictionary: NSDictionary = NSDictionary(contentsOfFile: defaultSettingsFile as String)!
        UserDefaults.standard.register(defaults: settingsDictionary as! [String:AnyObject])
        
        /* Instance the data controller */
        FireController.instance.prepare()
        DataController.instance.prepare()
        
        /* Notifications */
        NotificationController.instance.initWithLaunchOptions(launchOptions: launchOptions as [NSObject: AnyObject]!)

        /* Instance the reachability manager */
        ReachabilityManager.instance.prepare()
        
        /* Start listening for auth changes */
        UserController.instance.prepare()
        
        /* Setup master UI */
        MainController.instance.prepare(launchOptions: launchOptions)

        /* Initialize current group and channel state */
        StateController.instance.prepare()

        return true
    }

    @available(iOS 9.0, *)
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let sourceApplication = options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String
        return openUrl(application: app, openURL: url as NSURL, sourceApplication: sourceApplication, annotation: nil)
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return openUrl(application: application, openURL: url as NSURL, sourceApplication: sourceApplication, annotation: annotation as AnyObject?)
    }

    func openUrl(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {

        /* First see if Branch claims it as a deep link. Calls handler registered in onLaunch. */
        if Branch.getInstance().handleDeepLink(url as URL!) {
            Log.d("Branch detected a deep link in openUrl: \(url.absoluteString)", breadcrumb: true)
            return true
        }

        return false
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if let controller = UIViewController.topMostViewController() {
            if controller is PhotoBrowser || controller is PhotoPreview {
                return UIInterfaceOrientationMask.all;
            }
        }
        return UIInterfaceOrientationMask.portrait;
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        /* This is the initial entry point for universal links vs openURL for old school uri schemes. */
        return Branch.getInstance().continue(userActivity) // Returns true if call was caused by a branch universal link
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        Log.d("Application will enter foreground", breadcrumb: true)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        Log.d("Application will resign active", breadcrumb: true)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Log.d("Application did enter background", breadcrumb: true)
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    /*--------------------------------------------------------------------------------------------
    * Notifications
    *--------------------------------------------------------------------------------------------*/
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationController.instance.didRegisterForRemoteNotificationsWithDeviceToken(application: application, deviceToken: deviceToken as NSData)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NotificationController.instance.didFailToRegisterForRemoteNotificationsWithError(application: application, error: error)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
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
        NotificationController.instance.didReceiveRemoteNotification(application: application, notification: userInfo as [NSObject : AnyObject], fetchCompletionHandler: completionHandler)
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        NotificationController.instance.didReceiveLocalNotification(application: application, notification: notification)
    }

    /*--------------------------------------------------------------------------------------------
    * Background Sessions
    *--------------------------------------------------------------------------------------------*/
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
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
        AWSS3TransferUtility.interceptApplication(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completionHandler)
        Log.d("handleEventsForBackgroundURLSession called")
    }
}
