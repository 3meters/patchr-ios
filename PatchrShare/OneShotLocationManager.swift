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
    
    typealias LocationClosure = ((_ location: CLLocation?, _ error: Error?)->())
    
    private var didComplete: LocationClosure?
    
    private func _didComplete(location: CLLocation?, error: Error?) {
        locationManager?.stopUpdatingLocation()
        didComplete?(location, error)
        locationManager?.delegate = nil
        locationManager = nil
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
            case .authorizedWhenInUse:
                self.locationManager!.startUpdatingLocation()
            case .denied:
                _didComplete(location: nil, error: NSError(domain: self.classForCoder.description(),
                    code: OneShotLocationManagerErrors.AuthorizationDenied.rawValue,
                    userInfo: nil))
            default:
                break
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        _didComplete(location: nil, error: error)
    }
    
    internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        _didComplete(location: location, error: nil)
    }
    
    /* 
     * We assume that if we are called then needed location permissions are in place.
     * Fetch one location and return. We accept it regardless of accuracy.
     */
    func fetchWithCompletion(completion: @escaping LocationClosure) {
        
        //store the completion closure
        didComplete = completion
        
        //fire the location manager
        locationManager = CLLocationManager()
        locationManager!.delegate = self
    }
}
