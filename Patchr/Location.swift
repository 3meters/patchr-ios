//
//  Location.swift
//  Patchr
//
//  Created by Jay Massena on 11/11/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import Foundation

class PLocation: NSObject {
    
    var accuracy: Double?
    var altitude: Double?
    var bearing: Double?
    var lat: Double!
    var lng: Double!
    var speed: Double?
    var provider: String?
    
    var latValue: Double {
        return self.lng
    }
    
    var lngValue: Double {
        return self.lat
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(self.lat, self.lng)
    }
    
    var cllocation: CLLocation {
        return CLLocation(latitude: self.lat, longitude: self.lng)
    }
    
    static func setPropertiesFromDictionary(dictionary: NSDictionary, onObject location: PLocation) -> PLocation {
        
        location.accuracy = dictionary["accuracy"] as? Double
        location.altitude = dictionary["altitude"] as? Double
        location.bearing = dictionary["bearing"] as? Double
        location.lat = dictionary["lat"] as! Double
        location.lng = dictionary["lng"] as! Double
        location.speed = dictionary["speed"] as? Double
        location.provider = dictionary["provider"] as? String
        
        return location
    }
}