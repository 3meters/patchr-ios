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

    static let path = "/users"

    var id: String?
    var createdAt: Int?
    var modifiedAt: Int?
    var username: String?
    var presence: Any?
    var profile: FireProfile?
    
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
}
