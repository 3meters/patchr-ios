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
import Branch
import Firebase
import FirebaseInstanceID
import FirebaseMessaging
import Localize_Swift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate {

    var window: UIWindow? // Photo browser expects this to be here
    var firstLaunch: Bool = false
    var showedLaunchOnboarding = true
    var pendingNotification: [AnyHashable: Any]?
    
    /*--------------------------------------------------------------------------------------------
    * MARK: - Delegate methods
    *--------------------------------------------------------------------------------------------*/
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        Log.prepare()
        Log.i("Teeny launching...")
        
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
        Database.setLoggingEnabled(false)
        
        /* Remote notifications */
        if #available(iOS 10.0, *) {
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in })
            UNUserNotificationCenter.current().delegate = self // For iOS 10 display notification (sent via APNS)
            Messaging.messaging().delegate = self // For iOS 10 data message (sent via FCM)
        }
        else {
            /* Triggers permission UI if needed */
            application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil))
        }
        
        application.registerForRemoteNotifications() // Initiate the registration process with Apple Push Notification service.
        
        #if DEBUG
        AFNetworkActivityLogger.shared().startLogging()
        AFNetworkActivityLogger.shared().level = AFHTTPRequestLoggerLevel.AFLoggerLevelFatal
        #endif        

        /* Flag first launch for special treatment */
        if !UserDefaults.standard.bool(forKey: Prefs.firstLaunch) {
            let appDomain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: appDomain)    // Clear old prefs
            UserDefaults.standard.set(true, forKey: Prefs.firstLaunch)
            self.firstLaunch = true
            self.showedLaunchOnboarding = false
            try! Auth.auth().signOut()  // Triggers cleanup by canned queries
            
            /* Initial language setting */
            if (UserDefaults.standard.object(forKey: "LCLCurrentLanguageKey") as? String) == nil {
                if let langCode = Locale.current.languageCode {
                    Localize.setCurrentLanguage(langCode)
                }
            }

            Reporting.track("first_launch")
        }
        
        self.window = UIWindow(frame: UIScreen.main.bounds)

        /* Instance the data controller */
        FireController.instance.prepare()
        
        /* Instance the reachability manager */
        ReachabilityManager.instance.prepare()
        
        /* Setup master UI */
        MainController.instance.prepare(launchOptions: launchOptions)
        
        /* Auto login user, initialize current channel state */
        StateController.instance.prepare()
        
        /* App started because user tapped push notification */
        if let notification = launchOptions?[.remoteNotification] as? [String: AnyObject] {
            if !StateController.instance.stateIntialized {
                self.pendingNotification = notification
                NotificationCenter.default.addObserver(self, selector: #selector(stateInitialized(notification:)), name: NSNotification.Name(rawValue: Events.StateInitialized), object: nil)
            }
            else {
                showChannel(notification: notification)
            }
        }

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
        if let controller = UIViewController.topController {
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
        Reporting.track(AnalyticsEventAppOpen)
        Log.d("Application will enter foreground", breadcrumb: true)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        Log.d("Application did become active", breadcrumb: true)
        connectToFcm()
        Database.database().goOnline()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        Log.d("Application will resign active", breadcrumb: true)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Reporting.track(AnalyticsEventAppOpen)
        Log.d("Application did enter background", breadcrumb: true)
        disconnectFromFcm()
        Database.database().goOffline()
    }
    
    /*--------------------------------------------------------------------------------------------
    * MARK: - Remote Notifications
    *--------------------------------------------------------------------------------------------*/
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        /*
         * .inactive:    Always means that the user tapped on remote notification and app was covered by notification drawer.
         * .active:      Notification received while app is active (foreground).
         *
         * We have thirty seconds to process and call the completion handler before being
         * terminated if the app was started to process the notification.
         */
        Log.d("Notification received - app state: \(Config.appState())")
        //sendLocalNotification(notification: userInfo)
        Messaging.messaging().appDidReceiveMessage(userInfo) // For analytics tracking
        completionHandler(.noData)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Log.w("Failed to register for remote notifications: \(error)")
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Log.d("Success registering for remote notifications: APNS: \(deviceToken.description)")
        Messaging.messaging().setAPNSToken(deviceToken, type: Config.isDebug ? .sandbox : .prod)
        if let token = InstanceID.instanceID().token(),
            let userId = UserController.instance.userId {
            Log.i("AppDelegate: Setting firebase messaging token")
            FireController.db.child("installs/\(userId)/\(token)").setValue(true)
        }
    }
    
    func sendLocalNotification(notification: [AnyHashable: Any]) {
        let aps = notification["aps"] as! [AnyHashable: Any]
        let body = aps["alert"] as! String
        let sound = aps["sound"] as? String
        
        if #available(iOS 10.0, *) {
            let content = UNMutableNotificationContent()
            content.body = body
            if sound != nil {
                content.sound = UNNotificationSound.init(named: sound!)
            }
            content.userInfo = notification
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: "Local", content: content, trigger: trigger) // Schedule the notification.
            UNUserNotificationCenter.current().add(request) { error in
                if error != nil {
                    Log.e("User notification error: \(error as Any)")
                }
            }
        }
        else {
            // Fallback on earlier versions
        }
    }
    
    func stateInitialized(notification: AnyObject?) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Events.StateInitialized), object: nil)
        if self.pendingNotification != nil {
            showChannel(notification: self.pendingNotification)
        }
    }
    
    func showChannel(notification: [AnyHashable: Any]?) {
        if notification != nil {
            if let channelId = notification!["channel_id"] as? String {
                if StateController.instance.channelId != channelId {
                    StateController.instance.setChannelId(channelId: channelId)
                    MainController.instance.showChannel(channelId: channelId)
                }
            }
        }
    }
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Firebase Messaging
     *--------------------------------------------------------------------------------------------*/
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        /*
         * Receive data message on iOS 10 devices while app is in the foreground. Must
         * include data object in notification and NOT include notification object.
         */
        Log.d("Received firebase message: \(remoteMessage.appData.description)")
    }
    
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        if let userId = UserController.instance.userId {
            Log.i("AppDelegate: refreshing firebase messaging token: \(userId)")
            FireController.db.child("installs/\(userId)/\(fcmToken)").setValue(true)
            connectToFcm() /* Connect to FCM since connection may have failed when attempted before having a token. */
        }
    }
    
    func connectToFcm() {
        Messaging.messaging().shouldEstablishDirectChannel = true
        Log.d("Connected to FCM")
    }
    
    func disconnectFromFcm() {
        Messaging.messaging().shouldEstablishDirectChannel = false
        Log.d("Disconnected from FCM")
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
         */
        Log.d("handleEventsForBackgroundURLSession called")
    }
}

@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter
        , didReceive response: UNNotificationResponse
        , withCompletionHandler completionHandler: @escaping () -> Void) {
        
        /* User interacted with notification. Could be tap, dismiss, action button. */
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            if !StateController.instance.stateIntialized {
                self.pendingNotification = response.notification.request.content.userInfo
                NotificationCenter.default.addObserver(self, selector: #selector(stateInitialized(notification:)), name: NSNotification.Name(rawValue: Events.StateInitialized), object: nil)
            }
            else {
                showChannel(notification: response.notification.request.content.userInfo)
            }
        }
    }
}
