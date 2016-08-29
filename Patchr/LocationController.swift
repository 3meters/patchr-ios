//
//  LocationManager.swift
//  Patchr
//
//  Created by Jay Massena on 5/10/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import CoreLocation
import UIKit
import Foundation

class LocationController: NSObject {
    
    static let instance = LocationController()
    
    let ACCURACY_PREFERRED: Int = 50
    let ACCURACY_MINIMUM:   Int = 500
    let MIN_DISPLACEMENT:   Int = 200
    
    static let METERS_PER_MILE:             Float = 1609.344
    static let METERS_PER_YARD:             Float = 0.9144
    static let METERS_TO_MILES_CONVERSION:  Float = 0.000621371192237334
    static let METERS_TO_FEET_CONVERSION:   Float  = 3.28084
    static let METERS_TO_YARDS_CONVERSION:  Float = 1.09361
    static let FEET_TO_METERS_CONVERSION:   Float = 0.3048

    var locationManager                     : CLLocationManager!

    private var bgTask                      : UIBackgroundTaskIdentifier?
    private var _lastLocationAccepted       : CLLocation?
    private var updatesActive               = false
    
    override init(){
        super.init()
        initialize()
    }

    func initialize() {
        Log.d("***** Location controller initialized *****")
        locationManager = CLLocationManager()
        locationManager.pausesLocationUpdatesAutomatically = true       // Location manager will pause to save battery when location is unlikely to change
        locationManager.desiredAccuracy = Double(ACCURACY_PREFERRED)
        locationManager.activityType = CLActivityType.Fitness           // Pedestrian activity vs moving transportation (car, plane, train, etc)
        locationManager.distanceFilter = CLLocationDistance.abs(Double(MIN_DISPLACEMENT))
        locationManager.delegate = self
    }

    func mostRecentAvailableLocation() -> CLLocation?  {
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            return self._lastLocationAccepted ?? self.locationManager.location ?? lastLocationFromSettings() ?? nil
        }
        return nil
    }
    
    func lastLocationAccepted() -> CLLocation?  {
        return self._lastLocationAccepted
    }
    
    func clearLastLocationAccepted() {
        self._lastLocationAccepted = nil
    }

    func setMockLocation(coordinate: CLLocationCoordinate2D) {
        /* Used for testing */
        Log.d("Location injected")
        let location = CLLocation(coordinate: coordinate, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: NSDate())
        locationManager(self.locationManager, didUpdateLocations: [location])
    }

    func requestWhenInUseAuthorization() {
        self.locationManager.requestWhenInUseAuthorization()
    }

    func guardedRequestAuthorization(message: String?) {

        let message = message ?? "This lets you discover nearby patches."

        if let controller = UIViewController.topMostViewController() {

            let alert = UIAlertController(title: "Let Patchr use your location?", message: message, preferredStyle: UIAlertControllerStyle.Alert)

            let nearby = UIAlertAction(title: "Nearby patches", style: .Default) { action in
                Log.d("Guarded when in use location authorization accepted")
                Reporting.track("Selected When In Use Location Authorization")
                self.requestWhenInUseAuthorization()
            }
            let cancel = UIAlertAction(title: "Not now", style: .Cancel) { action in
                Log.d("Guarded location authorization declined")
                Reporting.track("Selected Decline Location Authorization")
                NSNotificationCenter.defaultCenter().postNotificationName(Events.LocationWasDenied, object: nil, userInfo: nil)
                alert.dismissViewControllerAnimated(true, completion: nil)
            }

            alert.addAction(nearby)
            alert.addAction(cancel)

            if #available(iOS 9.0, *) {
                alert.preferredAction = nearby
            }

            controller.presentViewController(alert, animated: true, completion: nil)
        }
    }

    func startUpdates(force force: Bool){

        /* Exit if not force and updates are already active */
        if self.updatesActive && !force { return }

        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            if self.locationManager != nil {
                if force {
                    self.locationManager.stopUpdatingLocation()	// Supposed to ensure that we will get at least one location update.
                    self.clearLastLocationAccepted()
                    Log.d("***** Location updates started with force")
                }
                else {
                    Log.d("***** Location updates started")
                }

                self.locationManager.startUpdatingLocation()
                self.updatesActive = true

                /* Last ditch effort to deliver a location */
                Utils.delay(5.0) {
                    if self.updatesActive && self._lastLocationAccepted == nil {
                        if let last = self.mostRecentAvailableLocation() {
                            /*
                             * Force in a location as a last resort. It will be updated when
                             * and if we get something better. Also can get here because device just
                             * doesn't have location support like the simulators.
                             */
                            Log.d("Hail mary manual push of most recent available location")
                            self.locationManager(self.locationManager, didUpdateLocations: [last])
                        }
                        else {
                            Log.w("Hail mary manual push failed because we have never had a location fix")
                        }
                    }
                }
            }
        }
    }

    func stopUpdates(){		
        guard self.updatesActive else { return }

        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            if self.locationManager != nil {
                Log.d("***** Location updates stopped *****")
                self.locationManager.stopUpdatingLocation()
                self.updatesActive = false
            }
        }
    }

    func distancePretty(meters: Float) -> String {
        var info: String = "here"
        /*
        * If distance = -1 then we don't have the location info
        * yet needed to correctly determine distance.
        */
        let miles: Float = meters * LocationController.METERS_TO_MILES_CONVERSION
        let feet: Float = meters * LocationController.METERS_TO_FEET_CONVERSION
        let yards: Float = meters * LocationController.METERS_TO_YARDS_CONVERSION
        
        if (feet >= 0) {
            if (miles >= 0.1) {
                info = String(format: "%.1f mi", miles);
            }
            else if (feet >= 50) {
                info = String(format: "%.0f yds", yards);
            }
            else {
                info = String(format: "%.0f ft", feet);
            }
        }
        
        if (feet <= 60) {
            info = "here";
        }
        
        return info
    }

    private func lastLocationFromSettings() -> CLLocation? {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let timestamp = userDefaults.objectForKey(PatchrUserDefaultKey("last_loc_timestamp")) as? NSDate {
            let lat = userDefaults.doubleForKey(PatchrUserDefaultKey("last_loc_lat"))
            let lng = userDefaults.doubleForKey(PatchrUserDefaultKey("last_loc_lng"))
            let acc = userDefaults.doubleForKey(PatchrUserDefaultKey("last_loc_acc"))
            let coordinate = CLLocationCoordinate2DMake(lat, lng)
            let location = CLLocation(coordinate: coordinate, altitude: 0, horizontalAccuracy: acc, verticalAccuracy: 0, timestamp: timestamp ?? NSDate())
            return location
        }
        return nil
    }

    private func isValidLocation(newLocation: CLLocation!, oldLocation: CLLocation?) -> Bool {

        /* filter out nil locations */
        if newLocation == nil {
            Log.d("Invalid location: location is nil")
            return false
        }

        /* filter out points with invalid accuracy */
        if newLocation.horizontalAccuracy < 0 {
            Log.d("Invalid location: horizontal accuracy is less than zero")
            return false
        }

        /* filter out points that are out of order */
        if oldLocation != nil {
            let secondsSinceLastPoint: NSTimeInterval = newLocation.timestamp.timeIntervalSinceDate(oldLocation!.timestamp)
            if secondsSinceLastPoint < 0 {
                Log.d("Invalid location: location timestamp is older than last accepted location")
                return false
            }
        }

        /* Location passes basic validation */
        return true;
    }
}

extension LocationController: CLLocationManagerDelegate {

    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            Log.d("Location service authorized when in use for Patchr")
            NSNotificationCenter.defaultCenter().postNotificationName(Events.LocationWasAllowed, object: nil, userInfo: nil)
        }
        else if status == CLAuthorizationStatus.Denied {
            Log.d("Location service denied for Patchr")
            Reporting.track("Denied Location Service")
            NSNotificationCenter.defaultCenter().postNotificationName(Events.LocationWasDenied, object: nil, userInfo: nil)
        }
        else if status == CLAuthorizationStatus.Restricted {
            Log.d("Location service restricted")
            Reporting.track("Restricted Location Service")
            NSNotificationCenter.defaultCenter().postNotificationName(Events.LocationWasRestricted, object: nil, userInfo: nil)
        }
        else if status == CLAuthorizationStatus.NotDetermined {
            Log.d("Location service not determined for Patchr")
        }
    }

    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        if error.code == CLError.LocationUnknown.rawValue {	// This fires on simulator without a location mocked
            Log.w("Location currently unknown")
        }
        else if error.code == CLError.Denied.rawValue  {
            Log.w("Location access denied")
            stopUpdates()
        }
        else if error.code == CLError.Network.rawValue  {
            Log.w("Location error: network related error")
        }
        else {
            Log.w("Location error: \(error)")
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        if let location = locations.last {
            
            let isInBackground = (UIApplication.sharedApplication().applicationState == UIApplicationState.Background)
            let lastLocation: CLLocation? = self._lastLocationAccepted
            let age = abs(trunc(location.timestamp.timeIntervalSinceNow * 100) / 100)
            let lat = trunc(location.coordinate.latitude * 100) / 100
            let lng = trunc(location.coordinate.longitude * 100) / 100
            let moved: Int? = lastLocation != nil ? Int(location.distanceFromLocation(lastLocation!)) : nil
            let movedString = moved != nil ? String(moved!) : "--"

            Log.v("Location received: lat: \(lat), lng: \(lng), acc: \(location.horizontalAccuracy)m, age: \(age)s, moved: \(movedString)m")

            if !isValidLocation(location, oldLocation: lastLocation) {
                Log.d("Location rejected as invalid")
                return
            }
            
            if Int(location.horizontalAccuracy) > ACCURACY_MINIMUM {
                Log.d("Location rejected for crap accuracy: \(Int(location.horizontalAccuracy))")
                return
            }
            
            if moved != nil && moved < MIN_DISPLACEMENT {
                /* We haven't moved far so skip unless nice accuracy improvement */
                if Int(location.horizontalAccuracy) > Int(lastLocation!.horizontalAccuracy / 2.0) {
                    Log.d("Location update ignored: distance moved only: \(moved!)m")
                    return
                }
                else {
                    Log.d("Location upgraded: distance moved only: \(moved!)m but at least twice as accurate")
                }
            }

            /* Every accepted location results in a nearby query o\if nearby list is active */
            self._lastLocationAccepted = location

            let message = "Location accepted ***: lat: \(lat), lng: \(lng), acc: \(location.horizontalAccuracy)m, age: \(age)s, moved: \(movedString)m"
            Log.i(message)

            if !isInBackground {
                if NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("enableDevModeAction")) {
                    UIShared.Toast(message)
                    AudioController.instance.play(Sound.pop.rawValue)
                }
                NSNotificationCenter.defaultCenter().postNotificationName(Events.LocationWasUpdated, object: nil, userInfo: ["location": location])
            }

            /* Persist so available as a last resort */
            let userDefaults = NSUserDefaults.standardUserDefaults()
            userDefaults.setDouble(lat, forKey: PatchrUserDefaultKey("last_loc_lat"))
            userDefaults.setDouble(lng, forKey: PatchrUserDefaultKey("last_loc_lng"))
            userDefaults.setDouble(location.horizontalAccuracy, forKey: PatchrUserDefaultKey("last_loc_acc"))
            userDefaults.setObject(location.timestamp, forKey: PatchrUserDefaultKey("last_loc_timestamp"))
        }
    }
}

func ==(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> Bool {
    return a.latitude == b.latitude && a.longitude == b.longitude
}

func !=(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> Bool {
    return !(a == b)
}

