//
//  AppDelegate.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-20.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

let PAApplicationDidReceiveRemoteNotification = "PAApplicationDidReceiveRemoteNotification"
let PAapplicationDidBecomeActiveWithNonZeroBadge = "PAapplicationDidBecomeActiveWithNonZeroBadge"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var locationManager = CLLocationManager()
    
    class func appDelegate() -> AppDelegate
    {
        return UIApplication.sharedApplication().delegate as AppDelegate
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        #if DEBUG
        AFNetworkActivityLogger.sharedLogger().startLogging()
        #endif
        
        Parse.setApplicationId("EonZJ4FXEADijslgqXCkg37sOGpB7AB9lDYxoHtz", clientKey: "5QRFlRQ3j7gkxyJ2cBYbHTK98WRQhoHCnHdpEKSD")
        
        ProxibaseClient.sharedInstance.registerInstallStandard { (response, error) -> Void in
            if error != nil {
                NSLog("Error during registerInstall: \(error)")
            }
        }
        
        self.locationManager.delegate = self
        
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            if self.locationManager.respondsToSelector(Selector("requestWhenInUseAuthorization")) {
                // iOS 8
                self.locationManager.requestWhenInUseAuthorization()
            } else {
                // iOS 7
                self.locationManager.startUpdatingLocation() // Prompts automatically
            }
        } else if CLLocationManager.authorizationStatus() == .AuthorizedAlways || CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            self.locationManager.startUpdatingLocation()
        }

        
        // If the connection to the database is considered valid, then start at the usual spot, otherwise start at the splash scene.
        
        if ProxibaseClient.sharedInstance.authenticated {
            self.window?.rootViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateInitialViewController() as? UIViewController;
        } else {
            let rootController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("SplashNavigationController") as? UIViewController
            self.window?.rootViewController = rootController
        }
        
        self.window?.tintColor = UIColor(hue: 33/360, saturation: 1.0, brightness: 0.9, alpha: 1.0)
        
        self.registerForRemoteNotifications()
        
        return true
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        
        if application.applicationIconBadgeNumber > 0 {
            NSNotificationCenter.defaultCenter().postNotificationName(PAapplicationDidBecomeActiveWithNonZeroBadge, object: self, userInfo: nil)
        }
        
        application.applicationIconBadgeNumber = 0
        
        if PFInstallation.currentInstallation().badge != 0 {
            PFInstallation.currentInstallation().badge = 0
            PFInstallation.currentInstallation().saveEventually()
        }
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {

        let parseInstallation = PFInstallation.currentInstallation()
        parseInstallation.setDeviceTokenFromData(deviceToken)
        parseInstallation.saveInBackground()
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
        var augmentedUserInfo = NSMutableDictionary(dictionary: userInfo)
        augmentedUserInfo["receivedInApplicationState"] = application.applicationState.rawValue
        NSNotificationCenter.defaultCenter().postNotificationName(PAApplicationDidReceiveRemoteNotification, object: self, userInfo: augmentedUserInfo)
        completionHandler(.NewData)
    }

    // MARK: CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            manager.startUpdatingLocation()
        } else if status == CLAuthorizationStatus.Denied {
            let windowList = UIApplication.sharedApplication().windows
            let topWindow = windowList[windowList.count - 1] as UIWindow
            SCLAlertView().showWarning(topWindow.rootViewController, title:"Location Disabled", subTitle: "You can enable location access in Settings → Patchr → Location", closeButtonTitle: "OK", duration: 0.0)
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [CLLocation]!) {}
    
    func registerForRemoteNotifications() {
        
        let application = UIApplication.sharedApplication()
        
        // http://stackoverflow.com/a/28742391/2247399
        if application.respondsToSelector("registerUserNotificationSettings:") {
            
            let types: UIUserNotificationType = (.Alert | .Badge | .Sound)
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(forTypes: types, categories: nil)
            
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
            
        } else {
            // Register for Push Notifications before iOS 8
            application.registerForRemoteNotificationTypes(.Alert | .Badge | .Sound)
        }
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
    
