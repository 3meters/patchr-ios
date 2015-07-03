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
    let ACCURACY_MINIMUM: Int = 500
    let MIN_DISPLACEMENT:Int = 200
    let userDefaults = { NSUserDefaults.standardUserDefaults() }()
    
    static let METERS_PER_MILE: Float = 1609.344
    static let METERS_PER_YARD: Float = 0.9144
    static let METERS_TO_MILES_CONVERSION: Float = 0.000621371192237334
    static let METERS_TO_FEET_CONVERSION: Float  = 3.28084
    static let METERS_TO_YARDS_CONVERSION: Float = 1.09361
    static let FEET_TO_METERS_CONVERSION: Float = 0.3048
    
    private var locationManager : CLLocationManager!
    
    var locationLocked : CLLocation?
    
    override init(){
        super.init()
        locationManager = CLLocationManager()
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.desiredAccuracy = Double(ACCURACY_PREFERRED)
        locationManager.activityType = CLActivityType.Fitness
        locationManager.distanceFilter = CLLocationDistance.abs(Double(MIN_DISPLACEMENT))
        locationManager.delegate = self
    }
    
    func currentLocation() -> CLLocation? {
        if let locLocked = locationLocked {
            return locLocked
        }

		return nil

		// Fallback location
		// - store/retrieve location in NSUserDefaults
		// - likely get a nearby major city based on timezone
		// return CLLocationCoordinate2D(latitude: 47.593677669, longitude: -122.1595818)
    }
    
    func getLocation() -> CLLocation?  {
        return locationManager.location
    }
    
    func stopUpdates(){
        println("Location updates stopped")
        println("***************************************")
        if self.locationManager != nil {
            self.locationManager.stopUpdatingLocation()
        }
    }
    
    func startUpdates(){
        println("Location updates started")
        println("***************************************")
        
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            if self.locationManager.respondsToSelector(Selector("requestWhenInUseAuthorization")) {
                // iOS 8
                self.locationManager.requestWhenInUseAuthorization()
            } else {
                // iOS 7
                self.locationManager.startUpdatingLocation() // Prompts automatically
            }
        } else if CLLocationManager.authorizationStatus() == .AuthorizedAlways
            || CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            self.locationManager.startUpdatingLocation()
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
}

func ==(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> Bool {
    return a.latitude == b.latitude && a.longitude == b.longitude
}

func !=(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> Bool {
    return !(a == b)
}

extension LocationController: CLLocationManagerDelegate {

	func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
		if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
			manager.startUpdatingLocation()
		}
        else if status == CLAuthorizationStatus.Denied {
            let windowList = UIApplication.sharedApplication().windows
            let topWindow = windowList[windowList.count - 1] as! UIWindow
            topWindow.rootViewController?.Alert("Location Disabled",
                message: "You can enable location access in Settings → Patchr → Location")
		}
	}
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        println("Location update received")
        
        if let location = locations.last as? CLLocation {
            
            var age = abs(trunc(location.timestamp.timeIntervalSinceNow * 100) / 100)
            
            if self.userDefaults.boolForKey(Utils.PatchrUserDefaultKey("devModeEnabled")) {
                var lat = trunc(location.coordinate.latitude * 100) / 100
                var lng = trunc(location.coordinate.longitude * 100) / 100
                
                var message = "Location received: lat: \(lat), lng: \(lng), acc: \(location.horizontalAccuracy)m, age: \(age)s"
                
                if let locPrev = self.locationLocked {
                    let moved = Int(location.distanceFromLocation(locPrev))
                    message = "Location received: lat: \(lat), lng: \(lng), acc: \(location.horizontalAccuracy)m, age: \(age)s, moved: \(moved)m"
                }
                println(message)
            }
            
            if !isValidLocation(location, oldLocation: self.locationLocked) {
                return
            }
            
            if Int(location.horizontalAccuracy) > ACCURACY_MINIMUM {
                println("Location rejected for crap accuracy: \(Int(location.horizontalAccuracy))")
                return
            }
            
            if let locLocked = self.locationLocked {
                let moved = Int(location.distanceFromLocation(locLocked))
                if moved < MIN_DISPLACEMENT {
                    println("Location upgrade ignored: distance moved: \(moved)")
                    return
                }
                if Int(location.horizontalAccuracy) > Int(locLocked.horizontalAccuracy / 2.0) {
                    println("Location upgrade ignored: current acc: \(Int(locLocked.horizontalAccuracy)) new acc: \(Int(location.horizontalAccuracy))")
                    return
                }
            }
            
            var dictionary = ["location":location]
            if self.locationLocked != nil {
                dictionary["locationOld"] = self.locationLocked
            }
            self.locationLocked = location
            NSNotificationCenter.defaultCenter().postNotificationName(Event.LocationUpdate.rawValue, object: nil, userInfo: dictionary)
        }
    }
    
    func isValidLocation(newLocation: CLLocation!, oldLocation: CLLocation?) -> Bool {
        
        /* filter out nil locations */
        if newLocation == nil {
            return false
        }
        
        /* filter out points with invalid accuracy */
        if newLocation.horizontalAccuracy < 0 {
            return false
        }
        
        /* filter out points that are out of order */
        if oldLocation != nil {
            let secondsSinceLastPoint: NSTimeInterval = newLocation.timestamp.timeIntervalSinceDate(oldLocation!.timestamp)
            if secondsSinceLastPoint < 0 {
                return false
            }
        }
        
        /* Location passes basic validation */
        return true;
    }
}
