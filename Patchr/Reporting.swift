//
//  Utilities.swift
//  Patchr
//
//  Created by Brent on 2015-03-05.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import ObjectiveC
import Google
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
	
	static func breadcrumb(message: String!) {
		Bugsnag.leaveBreadcrumbWithMessage(message);
	}
    
    static func updateCrashUser(user: User?) {
        if user != nil {
			Bugsnag.configuration().setUser(user!.id_, withName: user!.name, andEmail: user!.email)
        }
        else {
			Bugsnag.configuration().setUser(nil, withName: nil, andEmail: nil)
        }
    }
}

extension UIViewController {
	
	func setScreenName(name: String) {
		self.sendScreenView(name)
	}
	
	func sendScreenView(name: String) {
		if let tracker = GAI.sharedInstance().defaultTracker {
			tracker.set(kGAIScreenName, value: name)
			tracker.send(GAIDictionaryBuilder.createScreenView().build() as NSDictionary as [NSObject : AnyObject])
		}
	}
	
	func trackEvent(category: String, action: String, label: String, value: NSNumber?) {
		/*
		* Not used yet.
		*/
		if let tracker = GAI.sharedInstance().defaultTracker {
			let trackDictionary = GAIDictionaryBuilder.createEventWithCategory(category, action: action, label: label, value: value).build()
			tracker.send(trackDictionary as [NSObject : AnyObject])
		}
	}
}
