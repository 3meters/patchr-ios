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
    
    static let path = "/groups"
    
    var id: String?
    var name: String?
    var title: String?
    var desc: String?
    var photo: FirePhoto?
    var ownedBy: String?
    var createdAt: Int?
    var createdBy: String?
    var modifiedAt: Int?
    var modifiedBy: String?
    
    /* Link properties for the current user */
    var isDisabled: Bool?
    var role: String?
    var notifications: String?
    var hideEmail: Bool?
    var joinedAt: Int?
    
    required convenience init?(dict: [String: Any], id: String?) {
        guard let id = id else { return nil }
        self.init()
        self.id = id
        self.name = dict["name"] as? String
        self.title = dict["title"] as? String
        self.desc = dict["description"] as? String
        self.ownedBy = dict["owned_by"] as? String
        self.createdAt = dict["created_at"] as? Int
        self.createdBy = dict["created_by"] as? String
        self.modifiedAt = dict["modified_at"] as? Int
        self.modifiedBy = dict["modified_by"] as? String
        if (dict["photo"] as? NSDictionary) != nil {
            self.photo = FirePhoto(dict: dict["photo"] as! [String: Any], id: nil)
        }
    }
    
    internal var dict: [String : Any] {
        return [
            "name": self.name,
            "title": self.title,
            "description": self.desc,
            "photo": self.photo?.dict,
            "owned_by": self.ownedBy,
            "created_at": self.createdAt,
            "created_by": self.createdBy,
            "modified at": self.modifiedAt,
            "modified_by": self.modifiedBy
        ]
    }
    
    func membershipFrom(dict: [String: Any]) {
        self.isDisabled = dict["disabled"] as? Bool
        self.role = dict["role"] as? String
        self.notifications = dict["notifications"] as? String
        self.hideEmail = dict["hide_email"] as? Bool
        self.joinedAt = dict["joined_at"] as? Int
    }
}
