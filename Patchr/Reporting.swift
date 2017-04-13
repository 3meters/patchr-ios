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
import FirebaseAuth
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
    }
	
    static func updateUser(user: FIRUser?) {
        
        FIRAnalytics.setUserID(user?.uid)
        FIRAnalytics.setUserPropertyString(user?.displayName, forName: "name")
        FIRAnalytics.setUserPropertyString(user?.email, forName: "email") // TODO: Is this allowed?
        
        Bugsnag.configuration()!.setUser(user?.uid, withName: user?.displayName, andEmail: user?.email)
        
        if user != nil {
			BranchProvider.setIdentity(identity: user!.uid)
        }
        else {
			BranchProvider.logout()
        }
    }
	
	static func track(_ event: String, properties: [String : Any]? = nil) {
        let event = event.lowercased().replacingOccurrences(of: " ", with: "_")
        FIRAnalytics.logEvent(withName: event, parameters: nil)
	}
}
