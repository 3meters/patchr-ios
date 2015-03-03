//
//  MainTabBarViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-19.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

class MainTabBarController: UITabBarController, RMCoreDataStackDelegate, CLLocationManagerDelegate {
    
    private var coreDataStack : RMCoreDataStack!
    private var dataStore : DataStore!
    private var locationManager : CLLocationManager!
    
    deinit {
        if self.locationManager != nil {
            self.locationManager.stopUpdatingLocation()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let coreDataConfiguration = RMCoreDataConfiguration()
        coreDataConfiguration.persistentStoreType = NSInMemoryStoreType
        self.coreDataStack = RMCoreDataStack()
        self.coreDataStack.delegate = self
        self.coreDataStack.constructWithConfiguration(coreDataConfiguration)
        
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            if self.locationManager.respondsToSelector(Selector("requestWhenInUseAuthorization")) {
                // iOS 8
                self.locationManager.requestWhenInUseAuthorization()
            } else {
                // iOS 7
                self.locationManager.startUpdatingLocation() // Prompts automatically
            }
        } else if CLLocationManager.authorizationStatus() == .Authorized || CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            self.locationManager.startUpdatingLocation()
        } else {
            // TODO notify that location is not enabled?
        }
        
        self.dataStore = DataStore(managedObjectContext: self.coreDataStack.managedObjectContext, proxibaseClient: ProxibaseClient.sharedInstance, locationManager: self.locationManager)
        
        self.initializeViewControllers()
    }
    
    @IBAction func logoutButtonAction(sender: UIButton) {
        ProxibaseClient.sharedInstance.signOut { (response, error) -> Void in
            if error != nil {
                NSLog("Error during logout \(error)")
            }
            let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
            let destinationViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("SplashNavigationController") as UIViewController
            appDelegate.window!.setRootViewController(destinationViewController, animated: true)
        }
    }
    
    // MARK: RMCoreDataStackDelegate
    
    func coreDataStack(stack: RMCoreDataStack!, didFinishInitializingWithInfo info: [NSObject : AnyObject]!) {
        NSLog("[%@ %@]", reflect(self).summary, __FUNCTION__)
    }
    
    func coreDataStack(stack: RMCoreDataStack!, failedInitializingWithInfo info: [NSObject : AnyObject]!) {
        NSLog("[%@ %@]", reflect(self).summary, __FUNCTION__)
    }
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .Authorized || status == .AuthorizedWhenInUse {
            manager.startUpdatingLocation()
        } else if status == CLAuthorizationStatus.Denied {
            let alert = UIAlertController(title: "Location Services Disabled", message: "This app relies on your location to find Patches near you!", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [CLLocation]!) {}
    
    // MARK: Private internal
    
    func initializeViewControllers() {
        for viewController in self.viewControllers! {
            let navController = viewController as UINavigationController
            if let queryResultTable = navController.topViewController as? QueryResultTableViewController {
                queryResultTable.managedObjectContext = self.coreDataStack.managedObjectContext
                queryResultTable.dataStore = self.dataStore
            }
        }
    }
}
