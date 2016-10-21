//
//  Location.swift
//  Patchr
//
//  Created by Jay Massena on 11/11/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import Foundation
import FirebaseAuth


class FireChannel: NSObject, DictionaryConvertible {
    
    var id: String!
    var name: String?
    var patch: String?
    var photo: FirePhoto?
    var purpose: String?
    var type: String?
    var visibility: String?
    var isGeneral: Bool?
    var isDefault: Bool?
    var createdAt: Int?
    var createdBy: String?
    
    required convenience init?(dict: [String: Any], id: String?) {
        guard let id = id else { return nil }
        self.init()
        self.id = id
        self.name = dict["name"] as? String
        self.patch = dict["patch"] as? String
        if (dict["photo"] as? NSDictionary) != nil {
            self.photo = FirePhoto(dict: dict["photo"] as! [String: Any], id: nil)
        }
        self.purpose = dict["purpose"] as? String
        self.type = dict["type"] as? String
        self.visibility = dict["visibility"] as? String
        self.isDefault = dict["is_default"] as? Bool
        self.isGeneral = dict["is_general"] as? Bool
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
            "is_general": self.isGeneral,
            "is_default": self.isDefault,
            "created_at": self.createdAt,
            "created_by": self.name
        ]
    }
}
