//
//  AppDelegate.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-20.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import Parse
import Keys
import AFNetworking
import AFNetworkActivityLogger
import AWSCore
import FBSDKCoreKit
import Branch
import Analytics
import CocoaLumberjack
import iRate
import Bugsnag

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
	
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		
		let keys = PatchrKeys()
		
		/* Initialize Bugsnag */
		Bugsnag.startBugsnagWithApiKey(keys.bugsnagKey())
		
		/* Initialize Segment */
		let configuration = SEGAnalyticsConfiguration(writeKey: keys.segmentKey())
		configuration.flushAt = 20
		#if DEBUG
			configuration.flushAt = 1
		#endif
		SEGAnalytics.setupWithConfiguration(configuration)

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
			NSUserDefaults.standardUserDefaults().synchronize()
			self.firstLaunch = true
			Reporting.track("Launched for First Time")
		}
		/*
		* Init location controller. If this is done in the init of the nearby patch list
		* controller, we don't get properly hooked up when onboarding a new user. I could not
		* figure out exactly what causes the problem. Init does not require or trigger the
		* location permission request.
		*/
		LocationController.instance
		/*
		* We might have been launched because of a location change. We have
		* about ten seconds to call updateProximity with the new location.
		*/
		if launchOptions?[UIApplicationLaunchOptionsLocationKey] != nil {
			Log.d("Launching with location key", breadcrumb: true)
			if let locationManager = LocationController.instance.locationManager {
				if let last = LocationController.instance.mostRecentAvailableLocation() {
					LocationController.instance.locationManager(locationManager, didUpdateLocations: [last])
				}
			}
			return true
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
		
        /* Default config for AWS */
        // let credProvider = AWSCognitoCredentialsProvider(regionType: CognitoRegionType, identityPoolId: COGNITO_POOLID)
        let credProvider  = AWSStaticCredentialsProvider(accessKey: keys.awsS3Key(), secretKey: keys.awsS3Secret())
        let serviceConfig = AWSServiceConfiguration(region: AWSRegionType(rawValue: 3/*'us-west-2'*/)!, credentialsProvider: credProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = serviceConfig
        
        /* Load setting defaults */
        let defaultSettingsFile: NSString = NSBundle.mainBundle().pathForResource("DefaultSettings", ofType: "plist")!
        let settingsDictionary: NSDictionary = NSDictionary(contentsOfFile: defaultSettingsFile as String)!
        NSUserDefaults.standardUserDefaults().registerDefaults(settingsDictionary as! [String : AnyObject])
		
        /* Setup parse for push notifications - enabling notifications with the system is done with login */
		Parse.setApplicationId(keys.parseApplicationId(), clientKey: keys.parseApplicationKey())
		
        /* Instance the reachability manager */
        ReachabilityManager.instance
		
		/* Facebook */
		FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
		FBSDKProfile.enableUpdatesOnAccessTokenChange(true)
		
		/* Initialize Branch: The deepLinkHandler gets called every time the app opens. */
		Branch.getInstance().initSessionWithLaunchOptions(launchOptions, andRegisterDeepLinkHandler: { params, error in
			if error == nil {
				/* A hit could mean a deferred link match */
				if let clickedBranchLink = params["+clicked_branch_link"] as? Bool where clickedBranchLink {
					Log.d("Deep link routing based on clicked branch link", breadcrumb: true)
					self.routeDeepLink(params, error: error)	/* Presents modally on top of main tab controller. */
				}
			}
		})
		
		/* We might have been launched because of a deferred facebook deep link. */
		if launchOptions?[UIApplicationLaunchOptionsURLKey] == nil && self.firstLaunch {
			FBSDKAppLinkUtility.fetchDeferredAppInvite() { url in
				if url != nil {
					Log.d("Deep link routing for deferred facebook app invite", breadcrumb: true)
				}
			}
		}
		
		initUser()
		
		initUI()
		
		routeForRoot()
		
        return true
    }
	
	@available(iOS 9.0, *)
	func application(application: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
		let sourceApplication: String? = options[UIApplicationOpenURLOptionsSourceApplicationKey] as? String
		return openUrl(application, openURL: url, sourceApplication: sourceApplication, annotation: nil)
	}
	
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
		return  openUrl(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }
	
	func openUrl(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
		
		/* First see if Branch claims it as a deep link. Calls handler registered in onLaunch. */
		if Branch.getInstance().handleDeepLink(url) {
			Log.d("Branch detected a deep link in openUrl: \(url.absoluteString)", breadcrumb: true)
			return true
		}
		
		/* See if Facebook claims it as part of interaction with native Facebook client and Facebook dialogs */
		if FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation) {
			Log.d("Url passed to openUrl was intended for Facebook: \(url.absoluteString)", breadcrumb: true)
			return true
		}
		
		/* If the Branch or Facebook did not handle the incoming URL, check it for app link data */
		let parsedUrl: BFURL = BFURL(inboundURL: url, sourceApplication: sourceApplication)
		if (parsedUrl.appLinkData != nil) {
			if let params = parsedUrl.targetQueryParameters {
				Log.d("Facebook detected a deep link in openUrl: \(url.absoluteString)", breadcrumb: true)
				routeDeepLink(params, error: nil)
			}
			return true
		}
		
		return false
	}
	
	func applicationDidBecomeActive(application: UIApplication) {
		
		/* UIApplicationWillEnterForegroundNotification fires before this is called. */
		FBSDKAppEvents.activateApp()
		
		/*
		* Check to see if Facebook has a deferred deep link. Should only be
		* called after any launching url is processed. The facebook code
		* makes a graph call. It looks at appId/activities endpoint. The
		* advertisingId and the time the link was clicked in Facebook are key elements
		* in the matching process. They append fb_click_time_utc param to url.
		*/
		FBSDKAppLinkUtility.fetchDeferredAppLink { url, error in
			if url != nil && UIApplication.sharedApplication().canOpenURL(url) {
				Log.d("Facebook has detected a deferred app link, calling openUrl: \(url!.absoluteString)", breadcrumb: true)
				UIApplication.sharedApplication().openURL(url)
			}
		}

		/* Guard against becoming active without any UI */
		if self.window?.rootViewController == nil {
			Log.w("Patchr is becoming active without a root view controller, resetting to launch routing", breadcrumb: true)
			initUser()
			initUI()
			routeForRoot()
		}
	}
	
	func application(application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> UIInterfaceOrientationMask {
		if let controller = UIViewController.topMostViewController() {
			if controller is PhotoBrowser || controller is AirPhotoPreview {
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
		 * This is the initial entry point for universal links. 
		 * Pass the url to the branch deep link handler we registered in didFinishLaunchingWithOptions.
		 */
		Branch.getInstance().continueUserActivity(userActivity)
		return true
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
		let statusBarHidden = NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("statusBarHidden"))	// Default = false, set in dev settings
		UIApplication.sharedApplication().setStatusBarHidden(statusBarHidden, withAnimation: UIStatusBarAnimation.Slide)
		
		/* Global UI tweaks */
		UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: Theme.fontBarText], forState: UIControlState.Normal)
		self.window?.backgroundColor = Theme.colorBackgroundWindow
		self.window?.tintColor = Theme.colorTint
		UINavigationBar.appearance().tintColor = Theme.colorTint
		UITabBar.appearance().tintColor = Theme.colorTabBarTint
		UISwitch.appearance().onTintColor = Theme.colorTint
		
	}
	
	func initUser() {
		
		/* Get the latest on the authenticated user if we have one */
		if UserController.instance.authenticated {	// Checks for current userId and sessionKey
			UserController.instance.signinAuto()
		}
		
		/* We call even if install record exists and using this as a chance to update the metadata */
		UserController.instance.registerInstall()
	}
	
	func routeForRoot() {
		
		/* If we have an authenticated user then start at the usual spot, otherwise start at the lobby scene. */
		if UserController.instance.authenticated {
			let controller = MainTabBarController()
			controller.selectedIndex = 0
			self.window?.setRootViewController(controller, animated: true)
		}
		else {
			let controller = LobbyViewController()
			let navController = UINavigationController()
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
				controller.navigationItem.leftBarButtonItems = [cancelButton]
				let navController = UINavigationController()
				navController.viewControllers = [controller]
				UIViewController.topMostViewController()?.presentViewController(navController, animated: true, completion: nil)
			}
		}
		
		if let entityId = params!["entityId"] as? String, entitySchema = params!["entitySchema"] as? String {
			
			if entitySchema == "patch" {
				
				let controller = PatchDetailViewController()
				controller.entityId = entityId
				
				if let referrerName = params!["referrerName"] as? String {
					controller.inputReferrerName = referrerName.stringByReplacingOccurrencesOfString("+", withString: " ")
				}
				if let referrerPhotoUrl = params!["referrerPhotoUrl"] as? String {
					controller.inputReferrerPhotoUrl = referrerPhotoUrl
				}
				
				/* Navigation bar buttons */
				let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: controller, action: #selector(controller.dismissAction(_:)))
				controller.navigationItem.leftBarButtonItems = [doneButton]
				let navController = UINavigationController()
				navController.viewControllers = [controller]
				UIViewController.topMostViewController()?.presentViewController(navController, animated: true, completion: nil)
			}
			else if entitySchema == "message" {
				
				let controller = MessageDetailViewController()
				controller.inputMessageId = entityId
				controller.shareActive = true
				
				if let referrerName = params!["referrerName"] as? String {
					controller.inputReferrerName = referrerName.stringByReplacingOccurrencesOfString("+", withString: " ")
				}
				if let referrerPhotoUrl = params!["referrerPhotoUrl"] as? String {
					controller.inputReferrerPhotoUrl = referrerPhotoUrl
				}
				
				/* Navigation bar buttons */
				let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: controller, action: #selector(controller.dismissAction(_:)))
				controller.navigationItem.leftBarButtonItems = [doneButton]
				let navController = UINavigationController()
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
		if UserController.instance.authenticated {			
			UserController.instance.discardCredentials()
			Reporting.updateUser(nil)
			BranchProvider.logout()
		}
		
		NSUserDefaults.standardUserDefaults().setObject(nil, forKey: PatchrUserDefaultKey("userEmail"))
		NSUserDefaults.standardUserDefaults().synchronize()
		UserController.instance.clearStore()
		LocationController.instance.clearLastLocationAccepted()
		
		if !(UIViewController.topMostViewController() is LobbyViewController) {
			let navController = UINavigationController()
			navController.viewControllers = [LobbyViewController()]
			self.window!.setRootViewController(navController, animated: true)
		}
	}
	
	func resetToMain() {
		
		if let controller = UIViewController.getTabBarController() {
			controller.selectedIndex = 0	// Patches
		}
		else {
			let controller = MainTabBarController()
			controller.selectedIndex = 0
			self.window?.setRootViewController(controller, animated: true)
		}
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
        if receiptURL?.path?.rangeOfString("sandboxReceipt") == nil {
            return true
        }
        return false
    #endif
        
    }
}
    
