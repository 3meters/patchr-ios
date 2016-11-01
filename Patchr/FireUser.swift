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
    
    required convenience init?(dict: [String: Any], id: String?) {
        guard let id = id else { return nil }
        self.init()
        self.id = id
        self.createdAt = dict["created_at"] as? Int
        self.modifiedAt = dict["modified_at"] as? Int
        self.username = dict["username"] as? String
        self.presence = dict["presence"]
        if (dict["profile"] as? NSDictionary) != nil {
            self.profile = FireProfile(dict: dict["profile"] as! [String: Any], id: nil)
        }
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
