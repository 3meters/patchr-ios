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

class FireChannel: NSObject {
    
    var path: String {
        return "channels/\(self.id!)"
    }
    
    var createdAt: Int64?
    var createdBy: String?
    var general: Bool?
    var name: String?
    var title: String?
    var ownedBy: String?
    var photo: FirePhoto?
    var purpose: String?
    
    /* Local */
    var id: String?
    
    /* Channel link properties for the current user */
    var starred: Bool?
    var notifications: String?
    var role: String?
    var joinedAt: Int?

    init(dict: [String: Any], id: String?) {
        self.createdAt = dict["created_at"] as? Int64
        self.createdBy = dict["created_by"] as? String
        self.general = dict["general"] as? Bool
        self.id = id
        self.name = dict["name"] as? String
        self.title = dict["title"] as? String
        self.ownedBy = dict["owned_by"] as? String
        if (dict["photo"] as? [String : Any]) != nil {
            self.photo = FirePhoto(dict: dict["photo"] as! [String : Any])
        }
        self.purpose = dict["purpose"] as? String
    }
    
    func membershipClear() {
        self.starred = nil
        self.notifications = nil
        self.role = nil
        self.joinedAt = nil
    }

    func membershipFrom(dict: [String: Any]) {
        self.starred = dict["starred"] as? Bool
        self.notifications = dict["notifications"] as? String
        self.role = dict["role"] as? String
        self.joinedAt = dict["created_at"] as? Int
    }
    
    func star(on: Bool) {
        let userId = UserController.instance.userId!
        let updates: [String: Any] = [
            "starred": on
        ]
        FireController.db.child("channel-members/\(self.id!)/\(userId)").updateChildValues(updates)
    }
    
    func mute(on: Bool) {
        let userId = UserController.instance.userId!
        let state = on ? "all" : "none"
        let updates: [String: Any] = [
            "notifications": state
        ]
        FireController.db.child("channel-members/\(self.id!)/\(userId)").updateChildValues(updates)
    }
}
