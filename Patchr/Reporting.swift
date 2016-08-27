//
//  Utilities.swift
//  Patchr
//
//  Created by Brent on 2015-03-05.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import ObjectiveC
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
        if let installId = NotificationController.instance.installId {
            Bugsnag.addAttribute("patchr_install_id", withValue: installId, toTabWithName: "device")
        }
		
        /* Location info */
        if let location: CLLocation? = LocationController.instance.lastLocationAccepted() {
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
		let tracker = GAI.sharedInstance().defaultTracker
        if user != nil {
			tracker.set(kGAIUserId, value: user!.id_)
			BranchProvider.setIdentity(user!.id_)
			Bugsnag.configuration()!.setUser(user!.id_, withName: user!.name, andEmail: user!.email)
        }
        else {
			tracker.set(kGAIUserId, value: nil)
			BranchProvider.logout()
			Bugsnag.configuration()!.setUser(nil, withName: nil, andEmail: nil)
        }
    }
	
	static func track(event: String, properties: [String : AnyObject]? = nil) {
		let tracker = GAI.sharedInstance().defaultTracker
		let builder = GAIDictionaryBuilder.createEventWithCategory("Action", action: event, label: nil, value: nil)
		if properties != nil {
			builder.set(Array(properties!.keys).first, forKey: kGAIEventLabel)
			builder.set(Array(properties!.values).first as! String, forKey: kGAIEventValue)
		}
		let event = builder.build()
		tracker.send(event as [NSObject : AnyObject])
	}
	
	static func screen(name: String) {
		let tracker = GAI.sharedInstance().defaultTracker
		tracker.set(kGAIScreenName, value: name)
		let builder = GAIDictionaryBuilder.createScreenView()
		tracker.send(builder.build() as [NSObject : AnyObject])
	}
}
