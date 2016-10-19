//
//  Utilities.swift
//  Patchr
//
//  Created by Brent on 2015-03-05.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import ObjectiveC
import Firebase
import Bugsnag
import ReachabilitySwift

struct Reporting {
    
    static func updateCrashKeys() {
        
        let reachability: Reachability? = Reachability()
        let networkStatus: Reachability.NetworkStatus = (reachability?.currentReachabilityStatus)!
        if networkStatus != .notReachable {
			Bugsnag.addAttribute("connected", withValue: false, toTabWithName: "network")
        }
        else {
			Bugsnag.addAttribute("connected", withValue: true, toTabWithName: "network")
            if networkStatus == .reachableViaWiFi {
				Bugsnag.addAttribute("network_type", withValue: "wifi", toTabWithName: "network")
            }
            else if networkStatus == .reachableViaWWAN {
				Bugsnag.addAttribute("network_type", withValue: "wwan", toTabWithName: "network")
            }
        }

        /* Identifies device/install combo */
        if let installId = NotificationController.instance.installId {
            Bugsnag.addAttribute("patchr_install_id", withValue: installId, toTabWithName: "device")
        }
		
        /* Location info */
        if let location: CLLocation = LocationController.instance.lastLocationAccepted() {
            let eventDate = location.timestamp
            let howRecent = abs(trunc(eventDate.timeIntervalSinceNow * 100) / 100)
            Bugsnag.addAttribute("accuracy", withValue: location.horizontalAccuracy, toTabWithName: "location")
            Bugsnag.addAttribute("age", withValue: howRecent, toTabWithName: "location")
        }
        else {
			Bugsnag.addAttribute("accuracy", withValue: nil, toTabWithName: "location")
			Bugsnag.addAttribute("age", withValue: nil, toTabWithName: "location")
        }
    }
	
    static func updateUser(user: User?) {
        
        FIRAnalytics.setUserID(user?.id_)
        FIRAnalytics.setUserPropertyString(user?.name, forName: "name")
        FIRAnalytics.setUserPropertyString(user?.email, forName: "email")
        
        Bugsnag.configuration()!.setUser(user?.id_, withName: user?.name, andEmail: user?.email)
        
        if user != nil {
			BranchProvider.setIdentity(identity: user!.id_)
        }
        else {
			BranchProvider.logout()
        }
    }
	
	static func track(_ event: String, properties: [String : Any]? = nil) {
        let event = event.lowercased().replacingOccurrences(of: " ", with: "_")
        FIRAnalytics.logEvent(withName: event, parameters: nil)
	}
	
	static func screen(_ name: String) {
        FIRAnalytics.logEvent(withName: name, parameters: nil)
	}
}
