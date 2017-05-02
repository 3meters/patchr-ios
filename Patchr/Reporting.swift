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
import ReachabilitySwift

struct Reporting {
    
    static func updateCrashKeys() { }
	
    static func updateUser(user: FIRUser?) {
        
        FIRAnalytics.setUserID(user?.uid)
        FIRAnalytics.setUserPropertyString(user?.displayName, forName: "name")
        FIRAnalytics.setUserPropertyString(user?.email, forName: "email") // TODO: Is this allowed?
        
        if user != nil {
			BranchProvider.setIdentity(identity: user!.uid)
        }
        else {
			BranchProvider.logout()
        }
    }
	
	static func track(_ event: String, properties: [String : Any]? = nil) {
        let event = event.lowercased().replacingOccurrences(of: " ", with: "_")
        FIRAnalytics.logEvent(withName: event, parameters: properties as! [String : NSObject]?)
	}
}
