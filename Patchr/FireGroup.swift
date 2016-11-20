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
    var title: String?
    var desc: String?
    var photo: FirePhoto?
    var defaultChannels: [String]?
    var ownedBy: String?
    var createdAt: Int?
    var createdBy: String?
    var modifiedAt: Int?
    var modifiedBy: String?
    
    /* Link properties for the current user */
    var disabled: Bool?
    var hideEmail: Bool?
    var joinedAt: Int?
    var notifications: String?
    var role: String?
    var username: String?
    
    static func from(dict: [String: Any]?, id: String?) -> FireGroup? {
        if dict != nil {
            let group = FireGroup()
            group.id = id
            group.title = dict!["title"] as? String
            group.desc = dict!["description"] as? String
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
        self.role = dict["role"] as? String
        self.notifications = dict["notifications"] as? String
        self.hideEmail = dict["hide_email"] as? Bool
        self.joinedAt = dict["joined_at"] as? Int
        self.username = dict["username"] as? String
    }
}
