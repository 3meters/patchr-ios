//
//  Location.swift
//  Patchr
//
//  Created by Jay Massena on 11/11/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import Foundation
import FirebaseAuth


class FirePatch: NSObject, DictionaryConvertible {
    
    var id: String!
    var name: String?
    var title: String?
    var desc: String?
    var photo: FirePhoto?
    var ownedBy: String?
    var createdAt: Int?
    var createdBy: String?
    var modifiedAt: Int?
    var modifiedBy: String?
    
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
}
