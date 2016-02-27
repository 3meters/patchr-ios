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
import Keys
import AFNetworking
import AFNetworkActivityLogger
import AWSCore
import FBSDKCoreKit
import Branch
import Google
import CocoaLumberjack
import iRate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var backgroundSessionCompletionHandler: (() -> Void)?
	var kTrackingID = "YOUR_TRACKING_ID"
	
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

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        Log.d("Patchr launching...")
		
		/* Initialize Crashlytics: 25% of method time */
		Fabric.with([Crashlytics()])

		/* Instance the data controller */
		DataController.instance

		let keys = PatchrKeys()
		
		self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
		
        #if DEBUG
			AFNetworkActivityLogger.sharedLogger().startLogging()
			AFNetworkActivityLogger.sharedLogger().level = AFHTTPRequestLoggerLevel.AFLoggerLevelFatal
        #endif
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
		
        /* Turn on network activity indicator */
        AFNetworkActivityIndicatorManager.sharedManager().enabled = true
		
        /* Default config for AWS */
        // let credProvider = AWSCognitoCredentialsProvider(regionType: CognitoRegionType, identityPoolId: COGNITO_POOLID)
        let credProvider  = AWSStaticCredentialsProvider(accessKey: keys.awsS3Key(), secretKey: keys.awsS3Secret())
        let serviceConfig = AWSServiceConfiguration(region: AWSRegionType(rawValue: 3/*'us-west-2'*/)!, credentialsProvider: credProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = serviceConfig
        
        /* Turn on status bar */
		let statusBarHidden = NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("statusBarHidden"))
        UIApplication.sharedApplication().setStatusBarHidden(statusBarHidden, withAnimation: UIStatusBarAnimation.Slide)
		
        /* Load setting defaults */
        let defaultSettingsFile: NSString = NSBundle.mainBundle().pathForResource("DefaultSettings", ofType: "plist")!
        let settingsDictionary: NSDictionary = NSDictionary(contentsOfFile: defaultSettingsFile as String)!
        NSUserDefaults.standardUserDefaults().registerDefaults(settingsDictionary as! [String : AnyObject])
        
        /* Initialize Google analytics */
        var configureError:NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
		
        // Optional: configure GAI options.
		if let gai = GAI.sharedInstance() {
			gai.trackerWithTrackingId(GOOGLE_ANALYTICS_ID)
			gai.trackUncaughtExceptions = true  // report uncaught exceptions
			gai.defaultTracker.allowIDFACollection = true
			gai.dispatchInterval = 30    // Seconds
			gai.logger.logLevel = GAILogLevel.None
			
			#if DEBUG
				gai.logger.logLevel = GAILogLevel.Warning
				gai.dispatchInterval = 5    // Seconds
			#endif
		}
		
        /* Initialize Creative sdk: 25% of method time */
        AdobeUXAuthManager.sharedManager().setAuthenticationParametersWithClientID(keys.creativeSdkClientId(), clientSecret: keys.creativeSdkClientSecret(), enableSignUp: false)
        
        /* Change default font for button bar items */
        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: Theme.fontBarText], forState: UIControlState.Normal)

        /* Setup parse for push notifications - enabling notifications with the system is done with login */
		Parse.setApplicationId(keys.parseApplicationId(), clientKey: keys.parseApplicationKey())
		
        /* Get the latest on the authenticated user if we have one */
		if UserController.instance.authenticated {	// Checks for current userId and sessionKey
			UserController.instance.signinAuto()
        }
		
		/* We call even if install record exists and using this as a chance to update the metadata */
		UserController.instance.registerInstall()
		
        /* Instance the reachability manager */
        ReachabilityManager.instance
        
        /* Global UI tweaks */
        self.window?.backgroundColor = Theme.colorBackgroundWindow
        self.window?.tintColor = Theme.colorTint
        UITabBar.appearance().tintColor = Theme.colorTint
        UISwitch.appearance().onTintColor = Theme.colorTint
        
		/* Facebook */
		FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
		FBSDKProfile.enableUpdatesOnAccessTokenChange(true)
		
		/*
		* Initialize Branch: The deepLinkHandler gets called every time the app opens.
		* That means it should be a good place to handle all initial routing.
		*/
		Branch.getInstance().initSessionWithLaunchOptions(launchOptions, andRegisterDeepLinkHandler: { params, error in
			if error == nil {
				if let clickedBranchLink = params["+clicked_branch_link"] as? Bool where clickedBranchLink {
					/* Presents modally on top of main tab controller. */
					self.routeDeepLink(params, error: error)
				}
			}
		})
		
		/* Show initial controller */
		self.route()
		
        return true
    }
    
    /*--------------------------------------------------------------------------------------------
    * Routing
    *--------------------------------------------------------------------------------------------*/
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
		
		/* 
		 * First see if Branch claims it as a deep link. Calls handler registered in 
		 * onLaunch.
		 */
		if Branch.getInstance().handleDeepLink(url) {
			Log.d("Branch handled deep link: \(url.absoluteString)")
			return true
		}
		
		/* See if this is a Facebook deep link */
		let parsedUrl: BFURL = BFURL(inboundURL: url, sourceApplication: sourceApplication)
		if (parsedUrl.appLinkData != nil) {
			if let params = parsedUrl.targetQueryParameters {
				routeDeepLink(params, error: nil)
			}
			return true
		}
		
		/* See if Facebook claims it as part of interaction with native Facebook client and Facebook dialogs */
		if FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation) {
			Log.d("Facebook handled url")
			return true
		}				
		
        return false
    }
	
    func route() {
        
        /* Show initial controller */
		
        /* If we have an authenticated user then start at the usual spot, otherwise start at the lobby scene. */
        
		self.window?.makeKeyAndVisible()
		
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
    }
    
    func routeDeepLink(params: NSDictionary?, error: NSError?) {
        
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
				let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: controller, action: Selector("dismissAction:"))
				controller.navigationItem.leftBarButtonItems = [doneButton]
				let navController = UINavigationController()
				navController.viewControllers = [controller]
				UIViewController.topMostViewController()?.presentViewController(navController, animated: true, completion: nil)
            }
            else if entitySchema == "message" {
				
				let controller = MessageDetailViewController()
				controller.inputMessageId = entityId
				
				if let referrerName = params!["referrerName"] as? String {
					controller.inputReferrerName = referrerName.stringByReplacingOccurrencesOfString("+", withString: " ")
				}
				if let referrerPhotoUrl = params!["referrerPhotoUrl"] as? String {
					controller.inputReferrerPhotoUrl = referrerPhotoUrl
				}
				
				/* Navigation bar buttons */
				let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: controller, action: Selector("dismissAction:"))
				controller.navigationItem.leftBarButtonItems = [doneButton]
				let navController = UINavigationController()
				navController.viewControllers = [controller]
				UIViewController.topMostViewController()?.presentViewController(navController, animated: true, completion: nil)
            }
        }
    }
	
	func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
		// pass the url to the handle deep link call
		Branch.getInstance().continueUserActivity(userActivity)
		return true
	}

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
	func applicationDidBecomeActive(application: UIApplication) {
		
		FBSDKAppEvents.activateApp()
		
		/* Check to see if Facebook has a deferred deep link */
		FBSDKAppLinkUtility.fetchDeferredAppLink { url, error in
			if error != nil {
				Log.w("Error while fetching deferred app link \(error)")
			}
			if url != nil {
				UIApplication.sharedApplication().openURL(url)
			}
		}
		
		/* NotificationsTableViewController uses this to manage badging */
		NSNotificationCenter.defaultCenter().postNotificationName(Events.ApplicationDidBecomeActive, object: nil)
	}
	
    func applicationDidEnterBackground(application: UIApplication) {
        NSNotificationCenter.defaultCenter().postNotificationName(Events.ApplicationDidEnterBackground, object: nil)
    }

    func applicationWillEnterForeground(application: UIApplication){
        NSNotificationCenter.defaultCenter().postNotificationName(Events.ApplicationWillEnterForeground, object: nil)
    }
    
    func applicationWillResignActive(application: UIApplication){
        NSNotificationCenter.defaultCenter().postNotificationName(Events.ApplicationWillResignActive, object: nil)
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
			Reporting.updateCrashUser(nil)
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
    
