//
//  OneShotLocationManager - fetches the current device location once and invokes a completion closure
//  Patchr
//
//  Created by Jay Massena on 7/18/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import CoreLocation

enum OneShotLocationManagerErrors: Int {
    case AuthorizationDenied
    case AuthorizationNotDetermined
    case InvalidLocation
}

class OneShotLocationManager: NSObject, CLLocationManagerDelegate {
    
    private var locationManager: CLLocationManager?
    
    deinit {
        locationManager?.delegate = nil
        locationManager = nil
    }
    
    typealias LocationClosure = ((location: CLLocation?, error: NSError?)->())
    private var didComplete: LocationClosure?
    
    private func _didComplete(location: CLLocation?, error: NSError?) {
        locationManager?.stopUpdatingLocation()
        didComplete?(location: location, error: error)
        locationManager?.delegate = nil
        locationManager = nil
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        switch status {
            case .AuthorizedWhenInUse:
                self.locationManager!.startUpdatingLocation()
            case .Denied:
                _didComplete(nil, error: NSError(domain: self.classForCoder.description(),
                    code: OneShotLocationManagerErrors.AuthorizationDenied.rawValue,
                    userInfo: nil))
            default:
                break
        }
    }
    
    internal func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        _didComplete(nil, error: error)
    }
    
    internal func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if let location = locations[0] as? CLLocation {
            _didComplete(location, error: nil)
        }
        else {
            _didComplete(nil, error: NSError(domain: self.classForCoder.description(),
                code: OneShotLocationManagerErrors.InvalidLocation.rawValue,
                userInfo: nil))
        }
    }
    
    /* 
     * We assume that if we are called then needed location permissions are in place.
     * Fetch one location and return.
     */
    func fetchWithCompletion(completion: LocationClosure) {
        
        //store the completion closure
        didComplete = completion
        
        //fire the location manager
        locationManager = CLLocationManager()
        locationManager!.delegate = self
    }
}