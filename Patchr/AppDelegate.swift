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
import iRate
import MBProgressHUD
import SlideMenuControllerSwift
import Bugsnag
import FirebaseRemoteConfig
import Firebase
import FirebaseAuth
import FirebaseDatabase
import SwiftyBeaver

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, iRateDelegate {

    var window: UIWindow?
    var firstLaunch: Bool = false
    var backgroundSessionCompletionHandler: (() -> Void)?

    class func appDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
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
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        /* Initialize Firebase */
        FIRApp.configure()
        
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
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        /* Instance the data controller */
        DataController.instance.warmup()

        iRate.sharedInstance().delegate = self

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
        
        let log = SwiftyBeaver.self
        let console = ConsoleDestination()
        log.addDestination(console)

        Log.i("Patchr launching...")

        /* Turn on network activity indicator */
        AFNetworkActivityIndicatorManager.shared().isEnabled = true

        /* Load setting defaults */
        let defaultSettingsFile: NSString = Bundle.main.path(forResource: "DefaultSettings", ofType: "plist")! as NSString
        let settingsDictionary: NSDictionary = NSDictionary(contentsOfFile: defaultSettingsFile as String)!
        UserDefaults.standard.register(defaults: settingsDictionary as! [String:AnyObject])

        /* Notifications */
        NotificationController.instance.initWithLaunchOptions(launchOptions: launchOptions as [NSObject : AnyObject]!)

        /* Instance the reachability manager */
        ReachabilityManager.instance.warmup()
        
        /* Start listening for auth changes */
        UserController.instance.warmup()

        initUI()

        let ref = FIRDatabase.database().reference()
        ref.child("clients").child("ios").observeSingleEvent(of: .value, with: {
            snapshot in
            if let minVersion = snapshot.value as? Int {
                if !UIShared.versionIsValid(versionMin: Int(minVersion)) {
                    UIShared.compatibilityUpgrade()
                }
            }
        })

        routeForRoot()

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

    func applicationDidBecomeActive(_ application: UIApplication) {
        /* Guard against becoming active without any UI */
        if self.window?.rootViewController == nil {
            Log.w("Patchr is becoming active without a root view controller, resetting to launch routing", breadcrumb: true)
            initUI()
            routeForRoot()
        }
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if let controller = UIViewController.topMostViewController() {
            if controller is PhotoBrowser || controller is PhotoPreview {
                return UIInterfaceOrientationMask.all;
            }
            else {
                return UIInterfaceOrientationMask.portrait;
            }
        }
        return UIInterfaceOrientationMask.portrait;
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        /*
         * This is the initial entry point for universal links vs openURL for old school uri schemes.
         */
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

    func initUI() {

        /* Initialize Creative sdk: 25% of method time */
        AdobeUXAuthManager.shared().setAuthenticationParametersWithClientID(PatchrKeys().creativeSdkClientId(), clientSecret: PatchrKeys().creativeSdkClientSecret(), enableSignUp: false)

        /* Turn on status bar */
        let statusBarHidden = UserDefaults.standard.bool(forKey: PatchrUserDefaultKey(subKey: "statusBarHidden"))    // Default = false, set in dev settings
        UIApplication.shared.setStatusBarHidden(statusBarHidden, with: UIStatusBarAnimation.slide)

        /* Global UI tweaks */
        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: Theme.fontBarText], for: UIControlState.normal)
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
            let navigationController = DrawerController()
            navigationController.filter = PatchListFilter.Watching
            let mainController = PatchDetailViewController()
            mainController.entityId = "pa.150820.00499.464.259239"
            let mainNavController = AirNavigationController(rootViewController: mainController)
            
            let drawerController = SlideMenuController(mainViewController: mainNavController, leftMenuViewController: navigationController, rightMenuViewController: menuController)
            //let drawerController = NavigationDrawerController(rootViewController: mainNavController, leftViewController: navigationController, rightViewController: menuController)
            self.window?.setRootViewController(rootViewController: drawerController, animated: true)
        }
        else {
            let controller = LobbyViewController()
            let navController = AirNavigationController()
            navController.viewControllers = [controller]
            self.window?.setRootViewController(rootViewController: navController, animated: true)
        }

        self.window?.makeKeyAndVisible()
    }

    func routeDeepLink(params: NSDictionary?, error: NSError?) {

        if let feature = params!["~feature"] as? String, feature == "reset_password" {
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
                    controller.inputUserName = userName.replacingOccurrences(of: "+", with: " ")
                    if let userPhoto = params!["userPhoto"] as? String {
                        controller.inputUserPhoto = userPhoto
                    }
                }

                let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: controller, action: #selector(controller.cancelAction(sender:)))
                controller.navigationItem.rightBarButtonItems = [cancelButton]
                let navController = AirNavigationController()
                navController.viewControllers = [controller]
                UIViewController.topMostViewController()?.present(navController, animated: true, completion: nil)
            }
        }
    }

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
         * Applications using an NSURLSession with a background configuration may be launched or resumed in the b@escaping @escaping ackground in order to handle the
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
        UIShared.Toast(message: "Message Posted!")
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
        Reporting.updateUser(user: nil)
        BranchProvider.logout()

        UserDefaults.standard.set(nil, forKey: PatchrUserDefaultKey(subKey: "userEmail"))
        UserController.instance.clearStore()
        LocationController.instance.clearLastLocationAccepted()

        if !(UIViewController.topMostViewController() is LobbyViewController) {
            let navController = AirNavigationController()
            navController.viewControllers = [LobbyViewController()]
            self.window!.setRootViewController(rootViewController: navController, animated: true)
        }
    }

    func resetToMain() {
        routeForRoot()
    }

    func disableAnimations(state: Bool) {
        UIView.setAnimationsEnabled(!state)
        UIApplication.shared.keyWindow!.layer.speed = state ? 100.0 : 1.0
    }
}
