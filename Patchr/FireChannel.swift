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
        return "group-channels/\(self.groupId!)/\(self.id!)"
    }
    
    var archived: Bool?
    var createdAt: Int64?
    var createdBy: String?
    var general: Bool?
    var groupId: String?
    var name: String?
    var ownedBy: String?
    var photo: FirePhoto?
    var purpose: String?
    var type: String?
    var visibility: String?
    
    /* Local */
    var id: String?
    
    /* Channel link properties for the current user */
    var priority: Int?
    var starred: Bool?
    var muted: Bool?
    var role: String?
    var joinedAt: Int?
    
    init(dict: [String: Any], id: String?) {
        self.archived = dict["archived"] as? Bool
        self.createdAt = dict["created_at"] as? Int64
        self.createdBy = dict["created_by"] as? String
        self.general = dict["general"] as? Bool
        self.groupId = dict["group_id"] as? String
        self.id = id
        self.name = dict["name"] as? String
        self.ownedBy = dict["owned_by"] as? String
        if (dict["photo"] as? [String : Any]) != nil {
            self.photo = FirePhoto(dict: dict["photo"] as! [String : Any])
        }
        self.purpose = dict["purpose"] as? String
        self.type = dict["type"] as? String
        self.visibility = dict["visibility"] as? String
    }
    
    func membershipClear() {
        self.starred = nil
        self.muted = nil
        self.archived = nil
        self.role = nil
        self.joinedAt = nil
        self.priority = nil
    }

    func membershipFrom(dict: [String: Any]) {
        self.starred = dict["starred"] as? Bool
        self.muted = dict["muted"] as? Bool
        self.archived = dict["archived"] as? Bool
        self.role = dict["role"] as? String
        self.priority = dict["priority"] as? Int
        self.joinedAt = dict["joined_at"] as? Int
    }
    
    func star(on: Bool) {
        let userId = UserController.instance.userId!
        let pathByMember = "member-channels/\(userId)/\(self.groupId!)/\(self.id!)"
        let pathByGroup = "group-channel-members/\(self.groupId!)/\(self.id!)/\(userId)"
        let priority = on ? 1 : 4
        let index = Int64("\(FireController.instance.priorities[priority])\(self.joinedAt!)")
        let indexReversed = Int64("-\(FireController.instance.priorities.reversed()[priority])\(self.joinedAt!)")
        let updates: [String: Any] = [
            "starred": on,
            "priority": priority,
            "index_priority_joined_at": index!,
            "index_priority_joined_at_desc": indexReversed!
        ]
        
        FireController.db.child(pathByMember).updateChildValues(updates)
        FireController.db.child(pathByGroup).updateChildValues(updates)
    }
    
    func clearUnreadSorting() {
        
        /* Reset priority to normal */
        let userId = UserController.instance.userId!
        let pathByMember = "member-channels/\(userId)/\(self.groupId!)/\(self.id!)"
        let pathByGroup = "group-channel-members/\(self.groupId!)/\(self.id!)/\(userId)"
        let priority = self.starred! ? 1 : 4
        let index = Int64("\(FireController.instance.priorities[priority])\(self.joinedAt!)")
        let indexReversed = Int64("-\(FireController.instance.priorities.reversed()[priority])\(self.joinedAt!)")
        let updates: [String: Any] = [
            "priority": priority,
            "index_priority_joined_at": index!,
            "index_priority_joined_at_desc": indexReversed!
        ]
        
        FireController.db.child(pathByMember).updateChildValues(updates)
        FireController.db.child(pathByGroup).updateChildValues(updates)
    }
    
    func mute(on: Bool) {
        let userId = UserController.instance.userId!
        let groupId = self.groupId!
        let channelId = self.id!
        FireController.db.child("member-channels/\(userId)/\(groupId)/\(channelId)/muted").setValue(on)
        FireController.db.child("group-channel-members/\(groupId)/\(channelId)/\(userId)/muted").setValue(on)
    }
}
