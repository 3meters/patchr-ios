//
//  PatchTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-10.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation

class NearbyTableViewController: PatchTableViewController {
    
    var audioPlayer: AVAudioPlayer! = nil
    let userDefaults = { NSUserDefaults.standardUserDefaults() }()

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.activityDate = DataController.instance.activityDate
        self.filter = .Nearby
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        registerForLocationNotifications()
        LocationController.instance.startUpdates()
    }
    
    override func viewDidAppear(animated: Bool) {
        /* We do this here so user can see the changes */
        if DataController.instance.activityDate > self.activityDate {
            self.refreshQueryItems(force: true)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        unregisterForLocationNotifications()
        LocationController.instance.stopUpdates()
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    override func refreshQueryItems(force: Bool = false, paging: Bool = false) {
        if force {
            LocationController.instance.locationLocked = nil
            LocationController.instance.stopUpdates()
            LocationController.instance.startUpdates()
        }
    }
    
    func didUpdateLocation(notification: NSNotification) {
        
        let loc = notification.userInfo!["location"] as! CLLocation
        
        var eventDate = loc.timestamp
        var howRecent = abs(trunc(eventDate.timeIntervalSinceNow * 100) / 100)
        var lat = trunc(loc.coordinate.latitude * 100) / 100
        var lng = trunc(loc.coordinate.longitude * 100) / 100
        
        var message = "Location accepted ***: lat: \(lat), lng: \(lng), acc: \(loc.horizontalAccuracy)m, age: \(howRecent)s"
        
        if let locOld = notification.userInfo!["locationOld"] as? CLLocation {
            let moved = Int(loc.distanceFromLocation(locOld))
            message = "Location accepted ***: lat: \(lat), lng: \(lng), acc: \(loc.horizontalAccuracy)m, age: \(howRecent)s, moved: \(moved)m"
        }
        
        if self.userDefaults.boolForKey(Utils.PatchrUserDefaultKey("devModeEnabled")) {
            self.Toast(message)
            AudioController.instance.play(Sound.pop.rawValue)
        }
        
        println(message)
        
        refresh()
    }
    
    private func refresh() {
        
        if !self.refreshControl!.refreshing {
            self.progress!.show(true)
        }
        
        DataController.instance.refreshItemsFor(query(), force: false, paging: false, completion: {
            results, query, error in
            
            if let error = ServerError(error) {
                
                /* Always reset location after a network error */
                LocationController.instance.locationLocked = nil
                
                /* User credentials probably need to be refreshed */
                if error.code == ServerStatusCode.UNAUTHORIZED {
                    let controller = UIStoryboard(
                        name: "Lobby",
                        bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("SplashNavigationController") as? UIViewController
                    self.view.window?.rootViewController = controller
                }
                else {
                    self.handleError(error)
                }
                self.progress!.hide(true)
                self.refreshControl!.endRefreshing()
                return
            }
            
            if self.userDefaults.boolForKey(Utils.PatchrUserDefaultKey("SoundEffects")) {
                if !query.executedValue {
                    AudioController.instance.play(Sound.greeting.rawValue)
                }
            }
            
            self.activityDate = DataController.instance.activityDate
            
            // Delay seems to be necessary to avoid visual glitch with UIRefreshControl
            delay(0.5, {
                
                /* Flag query as having been executed at least once */
                self.progress!.hide(true)
                self.refreshControl!.endRefreshing()
                self.query().executedValue = true
                return
            })
        })
    }
    
    /*
     * We only get these callbacks if nearby is the current view controller.
     */
//    override func applicationDidEnterBackground() {
//        super.applicationDidEnterBackground()
//        
//        unregisterForLocationNotifications()
//        LocationController.instance.stopUpdates()
//    }
//    
//    override func applicationWillEnterForeground(){
//        super.applicationWillEnterForeground()
//        
//        /*
//         * When patchr comes back into the foreground after after the
//         * device has moved to a new location, we get a single location update
//         * which will be from last fix obtained before patchr went into the
//         * background. To be conservative, we clear our old location fix and
//         * treat this like a manual refresh.
//         */
//        LocationController.instance.locationLocked = nil
//        registerForLocationNotifications()
//        LocationController.instance.startUpdates()
//    }
    
    func registerForLocationNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didUpdateLocation:",
            name: Event.LocationUpdate.rawValue, object: nil)
    }
    
    func unregisterForLocationNotifications(){
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: Event.LocationUpdate.rawValue, object: nil)
    }
}

/*--------------------------------------------------------------------------------------------
 * Extensions
 *--------------------------------------------------------------------------------------------*/
