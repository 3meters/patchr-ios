//
//  AppDelegate.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-20.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

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
        
        return true
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

}
    
