//
//  AppDelegate.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-20.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import UserNotifications
import Keys
import AFNetworking
import AFNetworkActivityLogger
import AWSCore
import AWSS3
import Branch
import Bugsnag
import Firebase
import FirebaseInstanceID
import FirebaseMessaging
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
        
        /* Remote notifications */
        if #available(iOS 10.0, *) {
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in })
            
            /* For iOS 10 display notification (sent via APNS) */
            UNUserNotificationCenter.current().delegate = self
            
            /* For iOS 10 data message (sent via FCM) */
            FIRMessaging.messaging().remoteMessageDelegate = self
        }
        else {
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        NotificationController.instance.prepare()
        application.registerForRemoteNotifications()
        
        FIRApp.configure()
        FIRDatabase.database().persistenceEnabled = true
        FIRDatabase.setLoggingEnabled(false)
        
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
        
        /* Instance the reachability manager */
        ReachabilityManager.instance.prepare()
        
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
            if controller is PhotoBrowser {
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
        application.applicationIconBadgeNumber = 0
        NotificationController.instance.totalBadgeCount = 0
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        Log.d("Application did become active", breadcrumb: true)
        NotificationController.instance.connectToFcm()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        Log.d("Application will resign active", breadcrumb: true)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Log.d("Application did enter background", breadcrumb: true)
        NotificationController.instance.disconnectFromFcm()
    }

    /*--------------------------------------------------------------------------------------------
    * Notifications
    *--------------------------------------------------------------------------------------------*/
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        NotificationController.instance.didReceiveRemoteNotification(application: application, notification: userInfo, fetchCompletionHandler: nil)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        NotificationController.instance.didReceiveRemoteNotification(application: application, notification: userInfo, fetchCompletionHandler: completionHandler)
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        NotificationController.instance.didReceiveLocalNotification(application: application, notification: notification)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NotificationController.instance.didFailToRegisterForRemoteNotificationsWithError(application: application, error: error)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationController.instance.didRegisterForRemoteNotificationsWithDeviceToken(application: application, deviceToken: deviceToken)
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


@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter
        , willPresent notification: UNNotification
        , withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        /* A local or remote notification has been delivered. */
        
        let userInfo = notification.request.content.userInfo
        Log.d(userInfo.description)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter
        , didReceive response: UNNotificationResponse
        , withCompletionHandler completionHandler: @escaping () -> Void) {
        
        /* User interacted with notification. Could be tap, dismiss, action button. */
        
        let userInfo = response.notification.request.content.userInfo
        let channelId = userInfo["channelId"] as! String
        let groupId = userInfo["groupId"] as! String
        StateController.instance.setGroupId(groupId: groupId, channelId: channelId)
        MainController.instance.showChannel(groupId: groupId, channelId: channelId)
    }
}

extension AppDelegate : FIRMessagingDelegate {
    func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
        /* Receive data message on iOS 10 devices while app is in the foreground. */
        Log.d(remoteMessage.appData.description)
    }
}
