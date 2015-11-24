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
class AppDelegate: UIResponder, UIApplicationDelegate, HarpyDelegate {
    
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
		
		self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
		
        #if DEBUG
			AFNetworkActivityLogger.sharedLogger().startLogging()
			AFNetworkActivityLogger.sharedLogger().level = AFHTTPRequestLoggerLevel.AFLoggerLevelInfo
        #endif
        
        /* Turn on network activity indicator */
        AFNetworkActivityIndicatorManager.sharedManager().enabled = true
		
        /* Default config for AWS */
        // let credProvider = AWSCognitoCredentialsProvider(regionType: CognitoRegionType, identityPoolId: COGNITO_POOLID)
        let credProvider  = AWSStaticCredentialsProvider(accessKey: keys.awsS3Key(), secretKey: keys.awsS3Secret())
        let serviceConfig = AWSServiceConfiguration(region: AWSRegionType(rawValue: 3/*'us-west-2'*/)!, credentialsProvider: credProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = serviceConfig
        
        /* Turn on status bar */
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
        
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
        NSUserDefaults.standardUserDefaults().registerDefaults(settingsDictionary as! [String : AnyObject])
        
        /* Initialize Google analytics */
        var configureError:NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        
        // Optional: configure GAI options.
        let gai = GAI.sharedInstance()
        gai.trackerWithTrackingId("UA-33660954-6")
        gai.trackUncaughtExceptions = true  // report uncaught exceptions
        gai.defaultTracker.allowIDFACollection = true
        gai.dispatchInterval = 30    // Seconds
        gai.logger.logLevel = GAILogLevel.None
        
        #if DEBUG
			gai.logger.logLevel = GAILogLevel.Warning
			gai.dispatchInterval = 5    // Seconds
        #endif
        
        /* Initialize Crashlytics: 25% of method time */
        Fabric.with([Crashlytics()])
        
        /* Initialize Creative sdk: 25% of method time */
        AdobeUXAuthManager.sharedManager().setAuthenticationParametersWithClientID(keys.creativeSdkClientId(), clientSecret: keys.creativeSdkClientSecret(), enableSignUp: false)
        
        /* Change default font for button bar items */
        let customFont = UIFont(name:"HelveticaNeue", size: 18)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: customFont!], forState: UIControlState.Normal)

        /* Setup parse for push notifications */
        Parse.setApplicationId(keys.parseApplicationId(), clientKey: keys.parseApplicationKey())
		
		#if DEBUG
			#if TARGET_IPHONE_SIMULATOR
				PDDebugger.defaultInstance().enableNetworkTrafficDebugging()
				PDDebugger.defaultInstance().forwardAllNetworkTraffic()
				PDDebugger.defaultInstance().enableCoreDataDebugging()
				PDDebugger.defaultInstance().addManagedObjectContext(DataController.instance.coreDataStack.stackMainContext, withName: "Main")
				PDDebugger.defaultInstance().addManagedObjectContext(DataController.instance.coreDataStack.stackWriterContext, withName: "Writer")
				PDDebugger.defaultInstance().connectToURL(NSURL(string: "ws://127.0.0.1:9000/device"))
			#endif
		#endif
		
        /* Get the latest on the authenticated user if we have one */
		if UserController.instance.authenticated {	// Checks for current userId and sessionKey
            UserController.instance.signinAuto()
            /*
            * Register this install with the service. If install registration fails the
            * device will not accurately track notifications.
            */
            DataController.proxibase.registerInstallStandard {
                response, error in
				
				NSOperationQueue.mainQueue().addOperationWithBlock {
					if let error = ServerError(error) {
						if error.code == .UNAUTHORIZED_SESSION_EXPIRED {
							UIViewController.topMostViewController()!.handleError(error, errorActionType: .TOAST)
						}
						else {
							Log.w("Error during registerInstall: \(error)")
						}
					}
				}
            }
        }
        else {
			/* Register as anonymous guest user. registerInstall service call is done without user/session params */
            DataController.proxibase.registerInstallStandard {
                response, error in
				
				NSOperationQueue.mainQueue().addOperationWithBlock {
					if let error = ServerError(error) {
						Log.w("Error during registerInstall: \(error)")
					}
				}
            }
        }
        
        /* Instance the reachability manager */
        ReachabilityManager.instance
        
        /* Global UI tweaks */
        self.window?.backgroundColor = Colors.windowColor /* Light gray is better than black */
        self.window?.tintColor = Colors.brandColor
        UITabBar.appearance().tintColor = Colors.brandColorDark
        UISwitch.appearance().onTintColor = self.window?.tintColor
        
        /* We handle remote notifications */
        NotificationController.instance.registerForRemoteNotifications()
		
		/* Facebook */
		FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
//		FBSDKLoginManager.renewSystemCredentials {
//			result, error in
//		}
		
		/* Show initial controller */
		route()
		
        return true
    }
    
    /*--------------------------------------------------------------------------------------------
    * Routing
    *--------------------------------------------------------------------------------------------*/
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
		/*
		 * Even though the Facebook SDK can make this determinitaion on its own,
		 * let's make sure that the facebook SDK only sees urls intended for it,
		 * facebook has enough info already!
		 */
		if url.scheme.hasPrefix("fb\(FBSDKSettings.appID())") && url.host == "authorize" {
			return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
		}
		else if Branch.getInstance().handleDeepLink(url) {
            Log.d("Branch handled deep link: \(url.absoluteString)")
            return true
        }
        return false
    }
    
    func route() {
        
        /* Show initial controller */
		
        /* If we have an authenticated user then start at the usual spot, otherwise start at the lobby scene. */
        
		self.window?.makeKeyAndVisible()
        if UserController.instance.authenticated {
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            if let controller = storyboard.instantiateViewControllerWithIdentifier("MainTabBarController") as? MainTabBarController {
                self.window?.setRootViewController(controller, animated: true)
                controller.selectedIndex = 0
            }
        }
        else {
            let storyboard: UIStoryboard = UIStoryboard(name: "Lobby", bundle: NSBundle.mainBundle())
            let controller = storyboard.instantiateViewControllerWithIdentifier("LobbyNavigationController")
            self.window?.setRootViewController(controller, animated: true)
        }
		
		/* Configure Harpy */
		if UIApplication.sharedApplication().isInstalledViaAppStore() {
			if let harpy = Harpy.sharedInstance() {
				harpy.appID = APP_ID
				harpy.appName = "Patchr"
				harpy.presentingViewController = self.window?.rootViewController
				harpy.alertControllerTintColor = Colors.brandColorDark
				harpy.majorUpdateAlertType = HarpyAlertType.Force
				harpy.minorUpdateAlertType = HarpyAlertType.Option
				harpy.patchUpdateAlertType = HarpyAlertType.Skip
				harpy.revisionUpdateAlertType = HarpyAlertType.None
				harpy.checkVersion()
				#if DEBUG
					harpy.debugEnabled = true
				#endif
			}
		}
    }
    
    func routeDeepLink(params: NSDictionary?, error: NSError?) {
        
        if let entityId = params!["entityId"] as? String, entitySchema = params!["entitySchema"] as? String {
            let storyBoard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            
            if entitySchema == "patch" {
                if let controller = storyBoard.instantiateViewControllerWithIdentifier("PatchDetailViewController") as? PatchDetailViewController {
                    controller.entityId = entityId
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
                    controller.messageId = entityId
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
		Harpy.sharedInstance().checkVersionDaily()
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
    
