//
//  Utilities.swift
//  Teeny
//
//  Created by Brent on 2015-03-05.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import ObjectiveC
import Firebase
import FirebaseAuth
import ReachabilitySwift

struct Reporting {
    
    static func updateCrashKeys() { }
	
    static func updateUser(user: User?) {
        
        Analytics.setUserID(user?.uid)
        Analytics.setUserProperty(user?.displayName, forName: "name")
        Analytics.setUserProperty(user?.email, forName: "email") // TODO: Is this allowed?
        
        if user != nil {
			BranchProvider.setIdentity(identity: user!.uid)
        }
        else {
			BranchProvider.logout()
        }
    }
	
	static func track(_ event: String, properties: [String : Any]? = nil) {
        let event = event.lowercased().replacingOccurrences(of: " ", with: "_")
        Analytics.logEvent(event, parameters: properties as! [String : NSObject]?)
	}
}
