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
    var isGeneral: Bool?
    var isDefault: Bool?
    var isArchived: Bool?
    var createdAt: Int?
    var createdBy: String?
    
    /* Link properties for the current user */
    var starred: Bool?
    var muted: Bool?
    var archived: Bool?
    
    static func from(dict: [String: Any]?, id: String?) -> FireChannel? {
        if dict != nil {
            let channel = FireChannel()
            channel.id = id
            channel.name = dict!["name"] as? String
            channel.group = dict!["group"] as? String
            channel.purpose = dict!["purpose"] as? String
            channel.type = dict!["type"] as? String
            channel.visibility = dict!["visibility"] as? String
            channel.isDefault = dict!["default"] as? Bool
            channel.isGeneral = dict!["general"] as? Bool
            channel.isArchived = dict!["archived"] as? Bool
            channel.createdAt = dict!["created_at"] as? Int
            channel.createdBy = dict!["created_by"] as? String
            channel.photo = FirePhoto.from(dict: dict!["photo"] as! [String : Any]?)
            return channel
        }
        return nil
    }

    internal var dict: [String : Any] {
        return [
            "name": self.name,
            "patch": self.name,
            "photo": self.photo?.dict,
            "purpose": self.name,
            "type": self.type,
            "visibility": self.visibility,
            "general": self.isGeneral,
            "default": self.isDefault,
            "archived": self.isArchived,
            "created_at": self.createdAt,
            "created_by": self.name
        ]
    }
    
    func membershipFrom(dict: [String: Any]) {
        self.starred = dict["starred"] as? Bool
        self.muted = dict["muted"] as? Bool
        self.archived = dict["archived"] as? Bool
    }
    
    func star(on: Bool) {
        let userId = UserController.instance.userId
        let path = "member-channels/\(userId!)/\(self.group!)/\(self.id!)"
        let updates: [String: Any] = [
            "starred": on,
            "sort_priority": on ? 100 : 250]
        
        FireController.db.child(path).updateChildValues(updates)
    }
    
    func mute(on: Bool) {
        let userId = UserController.instance.userId
        let path = "member-channels/\(userId!)/\(self.group!)/\(self.id!)/muted"
        FireController.db.child(path).setValue(on)
    }
    
    func delete() {
        let channelMessagesPath = "channel-messages/\(self.id!)"
        let channelMembersPath = "channel-members/\(self.id!)"
        let updates: [String: Any] = [
            self.path: NSNull(),
            channelMessagesPath: NSNull(),
            channelMembersPath: NSNull()
        ]
        /* Need to walk the users that are members of the channel */
        FireController.db.child(self.path).updateChildValues(updates)
    }
}
