//
//  Utilities.swift
//  Patchr
//
//  Created by Brent on 2015-03-05.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import ObjectiveC
import Analytics
import Bugsnag

struct Reporting {
    
    static func updateCrashKeys() {
        
        let reachability: Reachability = Reachability.reachabilityForInternetConnection()
        let networkStatus: Int = reachability.currentReachabilityStatus().rawValue
        if networkStatus == 0 {
			Bugsnag.addAttribute("connected", withValue: false, toTabWithName: "network")
        }
        else {
			Bugsnag.addAttribute("connected", withValue: true, toTabWithName: "network")
            if networkStatus == 1 {
				Bugsnag.addAttribute("network_type", withValue: "wifi", toTabWithName: "network")
            }
            else if networkStatus == 2 {
				Bugsnag.addAttribute("network_type", withValue: "wwan", toTabWithName: "network")
            }
        }

        /* Identifies device/install combo */
		Bugsnag.addAttribute("patchr_install_id", withValue: UserController.instance.installId, toTabWithName: "device")
		
        /* Location info */
        let location: CLLocation? = LocationController.instance.lastLocationAccepted()
        if location != nil {
            let eventDate = location!.timestamp
            let howRecent = abs(trunc(eventDate.timeIntervalSinceNow * 100) / 100)
			Bugsnag.addAttribute("accuracy", withValue: location!.horizontalAccuracy, toTabWithName: "location")
			Bugsnag.addAttribute("age", withValue: howRecent, toTabWithName: "location")
        }
        else {
			Bugsnag.addAttribute("accuracy", withValue: nil, toTabWithName: "location")
			Bugsnag.addAttribute("age", withValue: nil, toTabWithName: "location")
        }
    }
	
    static func updateUser(user: User?) {
        if user != nil {
			SEGAnalytics.sharedAnalytics().alias(user!.id_)
			SEGAnalytics.sharedAnalytics().identify(user!.id_, traits: ["name":user!.name, "email":user!.email])
			BranchProvider.setIdentity(user!.id_)
			Bugsnag.configuration().setUser(user!.id_, withName: user!.name, andEmail: user!.email)
        }
        else {
			SEGAnalytics.sharedAnalytics().flush()	// Trigger upload of all queued events before clearing identity
			SEGAnalytics.sharedAnalytics().reset()	// Clears user id being used by segmentio
			BranchProvider.logout()
			Bugsnag.configuration().setUser(nil, withName: nil, andEmail: nil)
        }
    }
	
	static func track(event: String, properties: [String:AnyObject]? = nil) {
		SEGAnalytics.sharedAnalytics().track(event, properties: properties)
	}
	
	static func screen(name: String) {
		SEGAnalytics.sharedAnalytics().screen(name)
	}
}
