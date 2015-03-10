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
        } else if (CLLocationManager.authorizationStatus() == .AuthorizedAlways || CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse) {
            self.locationManager.startUpdatingLocation()
        }
        
        self.dataStore = DataStore(managedObjectContext: self.coreDataStack.managedObjectContext, proxibaseClient: ProxibaseClient.sharedInstance, locationManager: self.locationManager)
        
        self.initializeViewControllers()
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
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            manager.startUpdatingLocation()
        } else if status == CLAuthorizationStatus.Denied {
            SCLAlertView().showWarning(self, title:"Location Disabled", subTitle: "You can enable location access in Settings → Patchr → Location", closeButtonTitle: "OK", duration: 0.0)
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
