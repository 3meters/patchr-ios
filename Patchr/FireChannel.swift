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
    
    static let path = "/patch-channels"
    
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

    var pathInstance: String {
        return "\(FireChannel.path)/\(self.group!)/\(self.id!)"
    }
    
    @discardableResult static func observe(id: String, groupId: String, eventType: FIRDataEventType, with block: @escaping (FIRDataSnapshot) -> Swift.Void) -> UInt {
        let db = FIRDatabase.database().reference()
        return db.child("\(FireChannel.path)/\(groupId)/\(id)").observe(eventType, with: block)
    }
    
    @discardableResult func observe(eventType: FIRDataEventType, with block: @escaping (FIRDataSnapshot) -> Swift.Void) -> UInt {
        let db = FIRDatabase.database().reference()
        return db.child(pathInstance).observe(eventType, with: block)
    }
    
    func removeObserver(withHandle handle: UInt) {
        let db = FIRDatabase.database().reference()
        db.removeObserver(withHandle: handle)
    }

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
        self.isDefault = dict["is_default"] as? Bool
        self.isGeneral = dict["is_general"] as? Bool
        self.isArchived = dict["is_archived"] as? Bool
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
            "is_archived": self.isArchived,
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
