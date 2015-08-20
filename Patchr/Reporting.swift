//
//  Utilities.swift
//  Patchr
//
//  Created by Brent on 2015-03-05.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import ObjectiveC
import Fabric
import Crashlytics

struct Reporting {
    
    static func updateCrashKeys() {
        
        let reachability: Reachability = Reachability.reachabilityForInternetConnection()
        let networkStatus: Int = reachability.currentReachabilityStatus().value
        if networkStatus == 0 {
            Crashlytics.sharedInstance().setBoolValue(false, forKey: "connected")
        }
        else {
            Crashlytics.sharedInstance().setBoolValue(true, forKey: "connected")
            if networkStatus == 1 {
                Crashlytics.sharedInstance().setObjectValue("wifi", forKey: "network_type")
            }
            else if networkStatus == 2 {
                Crashlytics.sharedInstance().setObjectValue("wwan", forKey: "network_type")
            }
        }

        /* Identifies device/install combo */
        Crashlytics.sharedInstance().setObjectValue(DataController.proxibase.installationIdentifier, forKey: "install_id")
        
        /* Location info */
        let location: CLLocation? = LocationController.instance.lastLocationAccepted()
        if location != nil {
            var eventDate = location!.timestamp
            var howRecent = abs(trunc(eventDate.timeIntervalSinceNow * 100) / 100)
            Crashlytics.sharedInstance().setFloatValue(Float(location!.horizontalAccuracy), forKey: "location_accuracy")
            Crashlytics.sharedInstance().setIntValue(Int32(howRecent), forKey: "location_age")
        }
        else {
            Crashlytics.sharedInstance().setFloatValue(0, forKey: "location_accuracy")
            Crashlytics.sharedInstance().setIntValue(0 , forKey: "location_age")
        }
    }
    
    static func updateCrashUser(user: User?) {
        if user != nil {
            Crashlytics.sharedInstance().setUserIdentifier(user!.id_)
            Crashlytics.sharedInstance().setUserName(user!.name)
            Crashlytics.sharedInstance().setUserEmail(user!.email)
        }
        else {
            Crashlytics.sharedInstance().setUserIdentifier(nil)
            Crashlytics.sharedInstance().setUserName(nil)
            Crashlytics.sharedInstance().setUserEmail(nil)
        }
    }
}