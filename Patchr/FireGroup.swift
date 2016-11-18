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

class FireGroup: NSObject {
    
    var path: String {
        return "groups/\(self.id!)"
    }
    
    var id: String?
    var name: String?
    var title: String?
    var desc: String?
    var photo: FirePhoto?
    var general: String?
    var defaultChannels: [String]?
    var ownedBy: String?
    var createdAt: Int?
    var createdBy: String?
    var modifiedAt: Int?
    var modifiedBy: String?
    
    /* Link properties for the current user */
    var disabled: Bool?
    var role: String?
    var username: String?
    var notifications: String?
    var hideEmail: Bool?
    var joinedAt: Int?
    
    static func from(dict: [String: Any]?, id: String?) -> FireGroup? {
        if dict != nil {
            let group = FireGroup()
            group.id = id
            group.name = dict!["name"] as? String
            group.title = dict!["title"] as? String
            group.desc = dict!["description"] as? String
            group.general = dict!["general"] as? String
            group.defaultChannels = dict!["default_channels"] as? [String]
            group.ownedBy = dict!["owned_by"] as? String
            group.createdAt = dict!["created_at"] as? Int
            group.createdBy = dict!["created_by"] as? String
            group.modifiedAt = dict!["modified_at"] as? Int
            group.modifiedBy = dict!["modified_by"] as? String
            group.photo = FirePhoto.from(dict: dict!["photo"] as! [String : Any]?)
            return group
        }
        return nil
    }
    
    internal var dict: [String : Any] {
        return [
            "name": self.name,
            "title": self.title,
            "description": self.desc,
            "photo": self.photo?.dict,
            "general": self.general,
            "default_channels": self.defaultChannels,
            "owned_by": self.ownedBy,
            "created_at": self.createdAt,
            "created_by": self.createdBy,
            "modified at": self.modifiedAt,
            "modified_by": self.modifiedBy
        ]
    }
    
    func membershipFrom(dict: [String: Any]) {
        self.disabled = dict["disabled"] as? Bool
        self.role = dict["role"] as? String
        self.notifications = dict["notifications"] as? String
        self.hideEmail = dict["hide_email"] as? Bool
        self.joinedAt = dict["joined_at"] as? Int
        self.username = dict["username"] as? String
    }
}
