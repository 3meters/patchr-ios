//
//  Location.swift
//  Patchr
//
//  Created by Jay Massena on 11/11/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import Foundation
import FirebaseAuth

class FireUser: NSObject {
    
    var id: String!
    var createdAt: Int?
    var modifiedAt: Int?
    var username: String?
    var profile: FireProfile?
    
    convenience init(id: String) {
        self.init()
        self.id = id
    }
    
    override init() {
        super.init()
    }
    
    static func setPropertiesFromDictionary(dictionary: NSDictionary, onObject user: FireUser) -> FireUser {
        user.createdAt = dictionary["created_at"] as? Int
        user.modifiedAt = dictionary["modified_at"] as? Int
        user.username = dictionary["username"] as? String
        if let profileMap = dictionary["profile"] as? NSDictionary {
            user.profile = FireProfile.setPropertiesFromDictionary(profileMap, onObject: FireProfile())
        }
        return user
    }
}