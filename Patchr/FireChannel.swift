//
//  Location.swift
//  Teeny
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
    
    var code: String?
    var createdAt: Int64?
    var createdBy: String?
    var general: Bool?
    var id: String?
    var membership: Membership?
    var name: String?
    var ownedBy: String?
    var photo: FirePhoto?
    var purpose: String?
    var title: String?
    
    init(dict: [String: Any], id: String?) {
        self.createdAt = dict["created_at"] as? Int64
        self.createdBy = dict["created_by"] as? String
        self.general = dict["general"] as? Bool
        self.id = id
        self.code = dict["code"] as? String
        self.name = dict["name"] as? String
        self.title = dict["title"] as? String
        self.ownedBy = dict["owned_by"] as? String
        if (dict["photo"] as? [String : Any]) != nil {
            self.photo = FirePhoto(dict: dict["photo"] as! [String : Any])
        }
        self.purpose = dict["purpose"] as? String
    }
    
    func membershipClear() {
        self.membership?.clear()
        self.membership = nil
    }

    func membershipFrom(dict: [String: Any]) {
        let membership = Membership(dict: dict)
        self.membership = membership
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
