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
	var kTrackingID = "YOUR_TRACKING_ID"
	
    class func appDelegate() -> AppDelegate {
        return UIApplication.sharedApplication().delegate as! AppDelegate
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

        /* Setup parse for push notifications */
        Parse.setApplicationId(keys.parseApplicationId(), clientKey: keys.parseApplicationKey())
		
        /* Get the latest on the authenticated user if we have one */
		if UserController.instance.authenticated {	// Checks for current userId and sessionKey
            UserController.instance.signinAuto()
        }
		
		/* We call even if install record exists and using this as a chance to update the metadata */
		UserController.instance.registerInstall()
		
		/* Instance the location manager */
		LocationController.instance
		
        /* Instance the reachability manager */
        ReachabilityManager.instance
        
        /* Global UI tweaks */
        self.window?.backgroundColor = Theme.colorBackgroundWindow
        self.window?.tintColor = Theme.colorTint
        UITabBar.appearance().tintColor = Theme.colorTint
        UISwitch.appearance().onTintColor = Theme.colorTint
        
        /* We handle remote notifications */

		#if os(iOS) && !arch(i386) && !arch(x86_64)
			NotificationController.instance.registerForRemoteNotifications()			
		#endif

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
		
		/* First see if Branch claims it as a deep link */
		if Branch.getInstance().handleDeepLink(url) {
			Log.d("Branch handled deep link: \(url.absoluteString)")
			return true
		}
		
		/* See if this is a Facebook deep link */
		let parsedUrl: BFURL = BFURL(inboundURL: url, sourceApplication: sourceApplication)
		if (parsedUrl.appLinkData != nil) {
			if let inputQueryParameters = parsedUrl.inputQueryParameters {
				routeDeepLink(inputQueryParameters, error: nil)
			}
			return true
		}
		
		/* See if Facebook claims it */
		if FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation) {
			Log.d("Facebook handled url")
			return true
		}				
		
        return false
    }
	
	func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
		// pass the url to the handle deep link call
		Branch.getInstance().continueUserActivity(userActivity)		
		return true
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
            let storyBoard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            
            if entitySchema == "patch" {
                if let controller = storyBoard.instantiateViewControllerWithIdentifier("PatchDetailViewController") as? PatchDetailViewController {
                    controller.entityId = entityId
					controller.inputShowInviteWelcome = true
					if let inviterName = params!["inviterName"] as? String {
						controller.inputInviterName = inviterName.stringByReplacingOccurrencesOfString("+", withString: " ")
					}
                    /* Navigation bar buttons */
                    let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: controller, action: Selector("dismissAction:"))
                    controller.navigationItem.leftBarButtonItems = [doneButton]
                    let navController = UINavigationController()
                    navController.viewControllers = [controller]
                    UIViewController.topMostViewController()?.presentViewController(navController, animated: true, completion: nil)
                }
            }
            else if entitySchema == "message" {
                if let controller = storyBoard.instantiateViewControllerWithIdentifier("MessageDetailViewController") as? MessageDetailViewController {
                    controller.inputMessageId = entityId
                    /* Navigation bar buttons */
                    let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: controller, action: Selector("dismissAction:"))
                    controller.navigationItem.leftBarButtonItems = [doneButton]
                    let navController = UINavigationController()
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
    
    func application(application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> UIInterfaceOrientationMask {
        if let controller = UIViewController.topMostViewController() {
            if controller is AirPhotoBrowser || controller is AirPhotoPreview {
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
        Shared.Toast("Message Posted!")
    }
}

extension AppDelegate {
	/*
	* HarpyDelegate
	*/
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
    
