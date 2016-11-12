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
        return "users/\(self.id!)"
    }

    var id: String?
    var createdAt: Int?
    var modifiedAt: Int?
    var username: String?
    var presence: Any?
    var profile: FireProfile?
    
    /* Link properties for the current user */
    var disabled: Bool?
    var role: String?
    var notifications: String?
    var hideEmail: Bool?
    var joinedAt: Int?
    
    static func from(dict: [String: Any]?, id: String?) -> FireUser? {
        if dict != nil {
            let user = FireUser()
            user.id = id
            user.createdAt = dict!["created_at"] as? Int
            user.modifiedAt = dict!["modified_at"] as? Int
            user.username = dict!["username"] as? String
            user.presence = dict!["presence"]
            user.profile = FireProfile.from(dict: dict!["profile"] as! [String : Any]?)
            return user
        }
        return nil
    }
    
    internal var dict: [String : Any] {
        return [
            "created_at": self.createdAt,
            "modified_at": self.modifiedAt,
            "username": self.username,
            "profile": self.profile?.dict
        ]
    }
    
    
    func membershipFrom(dict: [String: Any]) {
        self.disabled = dict["disabled"] as? Bool
        self.role = dict["role"] as? String
        self.notifications = dict["notifications"] as? String
        self.hideEmail = dict["hide_email"] as? Bool
        self.joinedAt = dict["joined_at"] as? Int
    }
    
    
}
