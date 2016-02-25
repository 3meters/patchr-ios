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
    
    private var bgTask:             	UIBackgroundTaskIdentifier?
    private var locationManager:    	CLLocationManager!
    private var _lastLocationAccepted:  CLLocation?
	private var updatesActive = false
    
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
	
    func lastLocationFromManager() -> CLLocation?  {
		if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
			return self._lastLocationAccepted ?? self.locationManager.location
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
		Log.d("Location injected")
		let location = CLLocation(coordinate: coordinate, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: NSDate())
		locationManager(self.locationManager, didUpdateLocations: [location])
	}
	
	func requestAuthorizationIfNeeded() {
		if CLLocationManager.authorizationStatus() == .NotDetermined {
			self.locationManager.requestWhenInUseAuthorization()
		}
	}
    
	func startUpdates(force force: Bool){
		
		/* Exit if not force and updates are already active */
		guard force || !self.updatesActive else { return }
		
		if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
			if self.locationManager != nil {
				
				if self.locationManager.delegate == nil {
					Log.w("Location manager delegate is nil")
				}
				
				Log.d("***** Location updates \((force && self.updatesActive) ? "restarted" : "started")")
				
				if force {
					self.locationManager.stopUpdatingLocation()	// Supposed to ensure that we will get at least one location update.
					self.clearLastLocationAccepted()
				}
				
				self.locationManager.startUpdatingLocation()
				self.updatesActive = true
				
				/* Last ditch effort to deliver a location */
				Utils.delay(5.0) {
					if self.updatesActive && self._lastLocationAccepted == nil {
						if let last = self.locationManager.location {
							/* Force in a location because sometimes we seem to be stuck. */
							Log.d("Manual push of last location")
							self.locationManager(self.locationManager, didUpdateLocations: [last])
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
	
    func startSignificantChangeUpdates(){
        /* Ignores desired distance and accuracy */
		if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
			if self.locationManager != nil {
				self.locationManager.startMonitoringSignificantLocationChanges()
			}
        }
    }
    
    func stopSignificantChangeUpdates(){
		if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
			if self.locationManager != nil {
				self.locationManager.stopMonitoringSignificantLocationChanges()
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
    
    func sendBackgroundLocation(locations: [String:CLLocation]) {
        /*
         * Should only be called if user is authenticated.
         */
        if let loc = locations["location"] {
            
            self.bgTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler() {
                UIApplication.sharedApplication().endBackgroundTask(self.bgTask!)
            }
            
            let age = abs(trunc(loc.timestamp.timeIntervalSinceNow * 100) / 100)
            let lat = trunc(loc.coordinate.latitude * 100) / 100
            let lng = trunc(loc.coordinate.longitude * 100) / 100
            
            var message = "Background location accepted ***: lat: \(lat), lng: \(lng), acc: \(loc.horizontalAccuracy)m, age: \(age)s"
            
            if let locOld = locations["locationOld"] {
                let moved = Int(loc.distanceFromLocation(locOld))
                message = "Background location accepted ***: lat: \(lat), lng: \(lng), acc: \(loc.horizontalAccuracy)m, age: \(age)s, moved: \(moved)m"
            }
            
            if NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("enableDevModeAction")) {
                UIShared.Toast(message)
                AudioController.instance.play(Sound.pop.rawValue)
            }
            
            /*  Update location associated with this install */
			if UserController.instance.authenticated {
				DataController.proxibase.updateProximity(loc){
					response, error in
					
					NSOperationQueue.mainQueue().addOperationWithBlock {
						if let _ = ServerError(error) {
							Log.w("Error during updateProximity")
						}
						else {
							Log.d("Install proximity updated because of accepted background location")
						}
						if self.bgTask != UIBackgroundTaskInvalid {
							UIApplication.sharedApplication().endBackgroundTask(self.bgTask!)
							self.bgTask = UIBackgroundTaskInvalid
						}
					}
				}
			}
        }
    }

	func resendLast() {
		if self._lastLocationAccepted != nil {
			let dictionary:[NSObject: AnyObject] = ["location":self._lastLocationAccepted!]
			NSNotificationCenter.defaultCenter().postNotificationName(Events.LocationUpdate, object: nil, userInfo: dictionary)
		}
	}
}

extension LocationController: CLLocationManagerDelegate {

	func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
		if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
			Log.d("Location service authorized")
			NSNotificationCenter.defaultCenter().postNotificationName(Events.LocationAllowed, object: nil, userInfo: nil)
		}
        else if status == CLAuthorizationStatus.Denied {
			Log.d("Location service denied")
			NSNotificationCenter.defaultCenter().postNotificationName(Events.LocationDenied, object: nil, userInfo: nil)
		}
		else if status == CLAuthorizationStatus.NotDetermined {
			Log.d("Location service not determined")
		}
	}
	
	func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
		if error.code == CLError.LocationUnknown.rawValue {
			Log.w("Location currently unknown")
		}
		else if error.code == CLError.Denied.rawValue  {
			Log.w("Location access denied by user")
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
            let locationLast: CLLocation? = self._lastLocationAccepted
            let age = abs(trunc(location.timestamp.timeIntervalSinceNow * 100) / 100)
			let lat = trunc(location.coordinate.latitude * 100) / 100
			let lng = trunc(location.coordinate.longitude * 100) / 100
			
			var message = "Location received: lat: \(lat), lng: \(lng), acc: \(location.horizontalAccuracy)m, age: \(age)s"
			
			if locationLast != nil {
				let moved = Int(location.distanceFromLocation(locationLast!))
				message = "Location received: lat: \(lat), lng: \(lng), acc: \(location.horizontalAccuracy)m, age: \(age)s, moved: \(moved)m"
			}
			Log.v(message)
			
            if !isValidLocation(location, oldLocation: locationLast) {
				Log.d("Location rejected as invalid")
                return
            }
            
            if Int(location.horizontalAccuracy) > ACCURACY_MINIMUM {
                Log.d("Location rejected for crap accuracy: \(Int(location.horizontalAccuracy))")
                return
            }
            
            if locationLast != nil {
                let moved = Int(location.distanceFromLocation(locationLast!))
                if moved < MIN_DISPLACEMENT {
                    /* We haven't moved far so skip unless nice accuracy improvement */
                    if Int(location.horizontalAccuracy) > Int(locationLast!.horizontalAccuracy / 2.0) {
                        Log.d("Location update ignored: distance moved only: \(moved)m")
                        return
                    }
					else {
						Log.d("Location upgraded: distance moved only: \(moved)m but at least double the accuracy")
					}
                }
            }
            
            var dictionary = ["location":location]
            if locationLast != nil {
                dictionary["locationOld"] = locationLast
            }
            
            self._lastLocationAccepted = location
			
            if isInBackground {
                sendBackgroundLocation(dictionary)
            }
            else {
				
				message = "Location accepted ***: lat: \(lat), lng: \(lng), acc: \(location.horizontalAccuracy)m, age: \(age)s"
				
				if let locOld = locationLast {
					let moved = Int(location.distanceFromLocation(locOld))
					message = "Location accepted ***: lat: \(lat), lng: \(lng), acc: \(location.horizontalAccuracy)m, age: \(age)s, moved: \(moved)m"
				}
				
				Log.i(message)
				
				if NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("enableDevModeAction")) {
					UIShared.Toast(message)
					AudioController.instance.play(Sound.pop.rawValue)
				}
				
                NSNotificationCenter.defaultCenter().postNotificationName(Events.LocationUpdate, object: nil, userInfo: dictionary)
            }
        }
    }
    
    func isValidLocation(newLocation: CLLocation!, oldLocation: CLLocation?) -> Bool {
        
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

func ==(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> Bool {
    return a.latitude == b.latitude && a.longitude == b.longitude
}

func !=(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> Bool {
	return !(a == b)
}

