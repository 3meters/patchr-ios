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
    
    var createdAt: Int64?
    var createdBy: String?
    var defaultChannels: [String]?
    var modifiedAt: Int64?
    var modifiedBy: String?
    var ownedBy: String?
    var photo: FirePhoto?
    var title: String?
    
    /* Local */
    var id: String?
    
    /* Link properties for the current user */
    var disabled: Bool?
    var email: String?
    var joinedAt: Int?
    var notifications: String?
    var role: String?
    
    init(dict: [String: Any], id: String?) {
        self.createdAt = dict["created_at"] as? Int64
        self.createdBy = dict["created_by"] as? String
        self.defaultChannels = dict["default_channels"] as? [String]
        self.id = id
        self.modifiedAt = dict["modified_at"] as? Int64
        self.modifiedBy = dict["modified_by"] as? String
        self.ownedBy = dict["owned_by"] as? String
        if (dict["photo"] as? [String : Any]) != nil {
            self.photo = FirePhoto(dict: dict["photo"] as! [String : Any])
        }
        self.title = dict["title"] as? String
    }
    
    func membershipClear() {
        self.disabled = nil
        self.email = nil
        self.role = nil
        self.notifications = nil
        self.joinedAt = nil
    }
    
    func membershipFrom(dict: [String: Any]) {
        self.disabled = dict["disabled"] as? Bool
        self.email = dict["email"] as? String
        self.role = dict["role"] as? String
        self.notifications = dict["notifications"] as? String
        self.joinedAt = dict["joined_at"] as? Int
    }
}
