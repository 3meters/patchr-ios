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
        return "group-channels/\(self.group!)/\(self.id!)"
    }
    
    var id: String?
    var name: String?
    var group: String?
    var photo: FirePhoto?
    var purpose: String?
    var type: String?
    var visibility: String?
    var general: Bool?
    var archived: Bool?
    var createdAt: Int?
    var createdBy: String?
    
    /* Channel link properties for the current user */
    var starred: Bool?
    var muted: Bool?
    var role: String?
    var joinedAt: Int?
    
    static func from(dict: [String: Any]?, id: String?) -> FireChannel? {
        if dict != nil {
            let channel = FireChannel()
            channel.id = id
            channel.name = dict!["name"] as? String
            channel.group = dict!["group"] as? String
            channel.purpose = dict!["purpose"] as? String
            channel.type = dict!["type"] as? String
            channel.visibility = dict!["visibility"] as? String
            channel.general = dict!["general"] as? Bool
            channel.archived = dict!["archived"] as? Bool
            channel.createdAt = dict!["created_at"] as? Int
            channel.createdBy = dict!["created_by"] as? String
            channel.photo = FirePhoto.from(dict: dict!["photo"] as! [String : Any]?)
            return channel
        }
        return nil
    }
    
    func membershipClear() {
        self.starred = nil
        self.muted = nil
        self.archived = nil
        self.role = nil
        self.joinedAt = nil
    }

    func membershipFrom(dict: [String: Any]) {
        self.starred = dict["starred"] as? Bool
        self.muted = dict["muted"] as? Bool
        self.archived = dict["archived"] as? Bool
        self.role = dict["role"] as? String
        self.joinedAt = dict["joined_at"] as? Int
    }
    
    func star(on: Bool) {
        let userId = UserController.instance.userId
        let path = "member-channels/\(userId!)/\(self.group!)/\(self.id!)"
        let priority = on ? 1 : 4
        let index = Int("\(FireController.instance.priorities[priority])\(self.joinedAt!)")
        let indexReversed = Int("-\(FireController.instance.priorities.reversed()[priority])\(self.joinedAt!)")
        let updates: [String: Any] = [
            "starred": on,
            "priority": priority,
            "index_priority_joined_at": index!,
            "index_priority_joined_at_desc": indexReversed!
        ]
        
        FireController.db.child(path).updateChildValues(updates)
    }
    
    func mute(on: Bool) {
        let userId = UserController.instance.userId
        let path = "member-channels/\(userId!)/\(self.group!)/\(self.id!)/muted"
        FireController.db.child(path).setValue(on)
    }
}
