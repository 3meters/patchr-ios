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
import Branch
import CocoaLumberjack
import iRate
import MBProgressHUD
import SlideMenuControllerSwift
import Bugsnag
import FirebaseRemoteConfig
import Firebase
import FirebaseAuth
import FirebaseDatabase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, iRateDelegate {

    var window: UIWindow?
    var firstLaunch: Bool = false
    var backgroundSessionCompletionHandler: (() -> Void)?

    class func appDelegate() -> AppDelegate {
        return UIApplication.sharedApplication().delegate as! AppDelegate
    }

    override class func initialize() -> Void {
        iRate.sharedInstance().verboseLogging = false
        iRate.sharedInstance().daysUntilPrompt = 7
        iRate.sharedInstance().usesUntilPrompt = 10
        iRate.sharedInstance().remindPeriod = 1
        iRate.sharedInstance().promptForNewVersionIfUserRated = true
        iRate.sharedInstance().onlyPromptIfLatestVersion = true
        iRate.sharedInstance().useUIAlertControllerIfAvailable = true
        iRate.sharedInstance().promptAtLaunch = false
    }

    /*--------------------------------------------------------------------------------------------
    * Delegate methods
    *--------------------------------------------------------------------------------------------*/

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?) -> Bool {
        
        /* Initialize Firebase */
        FIRApp.configure()
        
        /* Remote config */
        FIRRemoteConfig.remoteConfig().fetchWithCompletionHandler { status, error in
            if (status == FIRRemoteConfigFetchStatus.Success) {
                
                if FIRRemoteConfig.remoteConfig().activateFetched() {
                    Log.d("Remote config activated", breadcrumb: true)
                }
                
                /* Default config for AWS */
                let access = FIRRemoteConfig.remoteConfig().configValueForKey("aws_access_key").stringValue!
                let secret = FIRRemoteConfig.remoteConfig().configValueForKey("aws_secret_key").stringValue!
                let credProvider = AWSStaticCredentialsProvider(accessKey: access, secretKey: secret)
                let serviceConfig = AWSServiceConfiguration(region: AWSRegionType(rawValue: 3/*'us-west-2'*/)!, credentialsProvider: credProvider)
                AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = serviceConfig
            }
            else {
                Log.d("Remote config not fetched", breadcrumb: true)
                Log.d("Error \(error!.localizedDescription)", breadcrumb: true)
            }
        }
        
        /* Initialize Bugsnag */
        Bugsnag.startBugsnagWithApiKey(BUGSNAG_KEY)
        
        /* Instance the data controller */
        DataController.instance

        iRate.sharedInstance().delegate = self

        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)

        #if DEBUG
        AFNetworkActivityLogger.sharedLogger().startLogging()
        AFNetworkActivityLogger.sharedLogger().level = AFHTTPRequestLoggerLevel.AFLoggerLevelFatal
        #endif

        /* Flag first launch for special treatment */
        if !NSUserDefaults.standardUserDefaults().boolForKey("firstLaunch") {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "firstLaunch")
            self.firstLaunch = true
            Reporting.track("Launched for First Time")
        }

        /* Logging */
        DDLog.addLogger(DDTTYLogger.sharedInstance()) // TTY = Xcode console
        DDLog.addLogger(DDASLLogger.sharedInstance()) // ASL = Apple System Logs

        DDTTYLogger.sharedInstance().colorsEnabled = true
        DDTTYLogger.sharedInstance().setForegroundColor(Theme.colorLogVerbose, backgroundColor: nil, forFlag: DDLogFlag.Verbose)
        DDTTYLogger.sharedInstance().setForegroundColor(Theme.colorLogDebug, backgroundColor: nil, forFlag: DDLogFlag.Debug)
        DDTTYLogger.sharedInstance().setForegroundColor(Theme.colorLogInfo, backgroundColor: nil, forFlag: DDLogFlag.Info)
        DDTTYLogger.sharedInstance().setForegroundColor(Theme.colorLogWarning, backgroundColor: nil, forFlag: DDLogFlag.Warning)
        DDTTYLogger.sharedInstance().setForegroundColor(Theme.colorLogError, backgroundColor: nil, forFlag: DDLogFlag.Error)

        let fileLogger: DDFileLogger = DDFileLogger() // File Logger
        fileLogger.rollingFrequency = 60 * 60 * 24  // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.addLogger(fileLogger)

        Log.i("Patchr launching...")

        /* Turn on network activity indicator */
        AFNetworkActivityIndicatorManager.sharedManager().enabled = true

        /* Load setting defaults */
        let defaultSettingsFile: NSString = NSBundle.mainBundle().pathForResource("DefaultSettings", ofType: "plist")!
        let settingsDictionary: NSDictionary = NSDictionary(contentsOfFile: defaultSettingsFile as String)!
        NSUserDefaults.standardUserDefaults().registerDefaults(settingsDictionary as! [String:AnyObject])

        /* Notifications */
        NotificationController.instance.initWithLaunchOptions(launchOptions)

        /* Instance the reachability manager */
        ReachabilityManager.instance
        
        /* Start listening for auth changes */
        UserController.instance

        initUI()

        let ref = FIRDatabase.database().reference()
        ref.child("clients").child("ios").observeSingleEventOfType(.Value, withBlock: {
            snapshot in
            if let minVersion = snapshot.value as? Int {
                if !UIShared.versionIsValid(Int(minVersion)) {
                    UIShared.compatibilityUpgrade()
                }
            }
        })

        routeForRoot()

        return true
    }

    @available(iOS 9.0, *)
    func application(application: UIApplication, openURL url: NSURL, options: [String:AnyObject]) -> Bool {
        let sourceApplication: String? = options[UIApplicationOpenURLOptionsSourceApplicationKey] as? String
        return openUrl(application, openURL: url, sourceApplication: sourceApplication, annotation: nil)
    }

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return openUrl(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func openUrl(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {

        /* First see if Branch claims it as a deep link. Calls handler registered in onLaunch. */
        if Branch.getInstance().handleDeepLink(url) {
            Log.d("Branch detected a deep link in openUrl: \(url.absoluteString)", breadcrumb: true)
            return true
        }

        return false
    }

    func applicationDidBecomeActive(application: UIApplication) {
        /* Guard against becoming active without any UI */
        if self.window?.rootViewController == nil {
            Log.w("Patchr is becoming active without a root view controller, resetting to launch routing", breadcrumb: true)
            initUI()
            routeForRoot()
        }
    }

    func application(application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> UIInterfaceOrientationMask {
        if let controller = UIViewController.topMostViewController() {
            if controller is PhotoBrowser || controller is PhotoPreview {
                return UIInterfaceOrientationMask.All;
            }
            else {
                return UIInterfaceOrientationMask.Portrait;
            }
        }
        return UIInterfaceOrientationMask.Portrait;
    }

    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
        /*
         * This is the initial entry point for universal links vs openURL for old school uri schemes.
         */
        return Branch.getInstance().continueUserActivity(userActivity) // Returns true if call was caused by a branch universal link
    }

    func applicationWillEnterForeground(application: UIApplication) {
        Log.d("Application will enter foreground", breadcrumb: true)
    }

    func applicationWillResignActive(application: UIApplication) {
        Log.d("Application will resign active", breadcrumb: true)
    }

    func applicationDidEnterBackground(application: UIApplication) {
        Log.d("Application did enter background", breadcrumb: true)
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func initUI() {

        /* Initialize Creative sdk: 25% of method time */
        AdobeUXAuthManager.sharedManager().setAuthenticationParametersWithClientID(PatchrKeys().creativeSdkClientId(), clientSecret: PatchrKeys().creativeSdkClientSecret(), enableSignUp: false)

        /* Turn on status bar */
        let statusBarHidden = NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("statusBarHidden"))    // Default = false, set in dev settings
        UIApplication.sharedApplication().setStatusBarHidden(statusBarHidden, withAnimation: UIStatusBarAnimation.Slide)

        /* Global UI tweaks */
        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: Theme.fontBarText], forState: UIControlState.Normal)
        self.window?.backgroundColor = Theme.colorBackgroundWindow
        self.window?.tintColor = Theme.colorTint
        UINavigationBar.appearance().tintColor = Theme.colorTint
        UITabBar.appearance().tintColor = Theme.colorTabBarTint
        UISwitch.appearance().onTintColor = Theme.colorTint
    }

    func routeForRoot() {

        /* If we have an authenticated user then start at the usual spot, otherwise start at the lobby scene. */
        if (FIRAuth.auth()?.currentUser) != nil {
            
            SlideMenuOptions.leftViewWidth = NAVIGATION_DRAWER_WIDTH
            SlideMenuOptions.rightViewWidth = SIDE_MENU_WIDTH
            SlideMenuOptions.animationDuration = CGFloat(0.2)
            SlideMenuOptions.simultaneousGestureRecognizers = false
            
            let menuController = SideMenuViewController()
            
            let navigationController = NavigationController()
            navigationController.filter = PatchListFilter.Watching
            
            let mainController = PatchDetailViewController()
            mainController.entityId = "pa.150820.00499.464.259239"
            let mainNavController = AirNavigationController(rootViewController: mainController)
            
            let slideController = SlideMenuController(mainViewController: mainNavController, leftMenuViewController: navigationController, rightMenuViewController: menuController)
            self.window?.setRootViewController(slideController, animated: true)
        }
        else {
            let controller = LobbyViewController()
            let navController = AirNavigationController()
            navController.viewControllers = [controller]
            self.window?.setRootViewController(navController, animated: true)
        }

        self.window?.makeKeyAndVisible()
    }

    func routeDeepLink(params: NSDictionary?, error: NSError?) {

        if let feature = params!["~feature"] as? String where feature == "reset_password" {
            if let token = params!["token"] as? String {
                /* Skip if we are already showing the reset screen */
                if let topController = UIViewController.topMostViewController() as? PasswordResetViewController {
                    if topController.inputToken == token {
                        return
                    }
                }

                let controller = PasswordResetViewController()
                controller.inputToken = token
                if let userName = params!["userName"] as? String {
                    controller.inputUserName = userName.stringByReplacingOccurrencesOfString("+", withString: " ")
                    if let userPhoto = params!["userPhoto"] as? String {
                        controller.inputUserPhoto = userPhoto
                    }
                }

                let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: controller, action: #selector(controller.cancelAction(_:)))
                controller.navigationItem.rightBarButtonItems = [cancelButton]
                let navController = AirNavigationController()
                navController.viewControllers = [controller]
                UIViewController.topMostViewController()?.presentViewController(navController, animated: true, completion: nil)
            }
        }
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

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject:AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
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
        NotificationController.instance.didReceiveRemoteNotification(application, notification: userInfo, fetchCompletionHandler: completionHandler)
    }

    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        NotificationController.instance.didReceiveLocalNotification(application, notification: notification)
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
        UIShared.Toast("Message Posted!")
    }
}

extension AppDelegate {
    func iRateDidPromptForRating() {
        Reporting.track("Prompted for Rating")
    }

    func iRateUserDidAttemptToRateApp() {
        Reporting.track("Attempted to Rate")
    }

    func iRateUserDidDeclineToRateApp() {
        Reporting.track("Declined to Rate")
    }

    func iRateUserDidRequestReminderToRateApp() {
        Reporting.track("Requested Reminder to Rate")
    }
}

extension AppDelegate {
    /*
     * Testing support
     */
    func resetToLobby() {
        /*
         * Client state is reset but service may still see the install as signed in.
         * The service will still send notifications to the install based on the signed in user.
         * We assume that if no authenticated user then we are at correct initial state.
         */
        UserController.instance.discardCredentials()
        Reporting.updateUser(nil)
        BranchProvider.logout()

        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: PatchrUserDefaultKey("userEmail"))
        UserController.instance.clearStore()
        LocationController.instance.clearLastLocationAccepted()

        if !(UIViewController.topMostViewController() is LobbyViewController) {
            let navController = AirNavigationController()
            navController.viewControllers = [LobbyViewController()]
            self.window!.setRootViewController(navController, animated: true)
        }
    }

    func resetToMain() {
        routeForRoot()
    }

    func disableAnimations(state: Bool) {
        UIView.setAnimationsEnabled(!state)
        UIApplication.sharedApplication().keyWindow!.layer.speed = state ? 100.0 : 1.0
    }

    func logLevel(level: DDLogLevel) {
        LOG_LEVEL = level
    }
}

extension UIApplication {
    func isInstalledViaAppStore() -> Bool {

#if (arch(i386) || arch(x86_64)) && os(iOS)
        // Simulator http://stackoverflow.com/a/24869607/2247399
        return false
#else
        let receiptURL = NSBundle.mainBundle().appStoreReceiptURL
        return (receiptURL?.path?.rangeOfString("sandboxReceipt") == nil)
#endif
    }
}

