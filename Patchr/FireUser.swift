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
    var presence: Any?
    var profile: FireProfile?
    
    /* Link properties for the current user */
    var disabled: Bool?
    var hideEmail: Bool?
    var joinedAt: Int?
    var notifications: String?
    var role: String?
    var username: String?
    
    static func from(dict: [String: Any]?, id: String?) -> FireUser? {
        if dict != nil {
            let user = FireUser()
            user.id = id
            user.createdAt = dict!["created_at"] as? Int
            user.modifiedAt = dict!["modified_at"] as? Int
            user.presence = dict!["presence"]
            user.profile = FireProfile.from(dict: dict!["profile"] as! [String : Any]?)
            return user
        }
        return nil
    }
    
    func membershipClear() {
        self.disabled = nil
        self.username = nil
        self.role = nil
        self.notifications = nil
        self.hideEmail = nil
        self.joinedAt = nil
    }
    
    func membershipFrom(dict: [String: Any]) {
        self.disabled = dict["disabled"] as? Bool
        self.username = dict["username"] as? String
        self.role = dict["role"] as? String
        self.notifications = dict["notifications"] as? String
        self.hideEmail = dict["hide_email"] as? Bool
        self.joinedAt = dict["joined_at"] as? Int
    }
}
