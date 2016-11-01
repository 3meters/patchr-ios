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
    
    static let path = "/group-channels"
    
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
    var favorite: Bool?
    var muted: Bool?
    var archived: Bool?

    required convenience init?(dict: [String: Any], id: String?) {
        guard let id = id else { return nil }
        self.init()
        self.id = id
        self.name = dict["name"] as? String
        self.group = dict["group"] as? String
        if (dict["photo"] as? NSDictionary) != nil {
            self.photo = FirePhoto(dict: dict["photo"] as! [String: Any], id: nil)
        }
        self.purpose = dict["purpose"] as? String
        self.type = dict["type"] as? String
        self.visibility = dict["visibility"] as? String
        self.isDefault = dict["default"] as? Bool
        self.isGeneral = dict["general"] as? Bool
        self.isArchived = dict["archived"] as? Bool
        self.createdAt = dict["created_at"] as? Int
        self.createdBy = dict["created_by"] as? String
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
        self.favorite = dict["favorite"] as? Bool
        self.muted = dict["muted"] as? Bool
        self.archived = dict["archived"] as? Bool
    }
}
