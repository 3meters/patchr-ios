//
//  Location.swift
//  Patchr
//
//  Created by Jay Massena on 11/11/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import Foundation
import FirebaseAuth
import Firebase
import FirebaseDatabase

class FireUser: NSObject {

    var path: String {
        return "users/\(self.id)"
    }

    var createdAt: Int64!
    var createdBy: String!
    var developer: Bool?
    var id: String!
    var membership: Membership?
    var modifiedAt: Int64!
    var presence: Any?
    var profile: FireProfile?
    var username: String!
    
    var fullName: String! {
        get {
            if profile?.fullName != nil && !profile!.fullName!.isEmpty {
                return profile!.fullName!
            }
            return username!
        }
    }
    
    init(dict: [String: Any], membership: [String: Any]? = nil, id: String?) {
        self.id = id
        self.createdAt = dict["created_at"] as? Int64
        self.createdBy = dict["created_by"] as? String
        self.modifiedAt = dict["modified_at"] as? Int64
        self.presence = dict["presence"]
        self.username = dict["username"] as? String
        self.developer = dict["developer"] as? Bool
        if (dict["profile"] as? [String : Any]) != nil {
            self.profile = FireProfile(dict: dict["profile"] as! [String : Any])
        }
        if membership != nil {
            self.membership = Membership(dict: membership!)
        }
    }
    
    func membershipClear() {
        self.membership?.clear()
        self.membership = nil
    }

    func membershipFrom(dict: [String: Any]) {
        let membership = Membership(dict: dict)
        self.membership = membership
    }
}

class Membership: NSObject {
    var notifications: String?
    var role: String!
    var starred: Bool!
    
    init(dict: [String: Any]) {
        self.notifications = dict["notifications"] as? String
        self.role = dict["role"] as! String
        self.starred = dict["starred"] as? Bool
    }
    
    func clear() {
        self.notifications = nil
        self.role = nil
        self.starred = nil
    }
}
