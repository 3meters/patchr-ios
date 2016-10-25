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

class FireUser: NSObject {

    static let path = "/users"

    var id: String?
    var createdAt: Int?
    var modifiedAt: Int?
    var username: String?
    var profile: FireProfile?
    
    var pathInstance: String {
        return "\(FireUser.path)/\(self.id!)"
    }
    
    @discardableResult static func observe(id: String, eventType: FIRDataEventType, with block: @escaping (FIRDataSnapshot) -> Swift.Void) -> UInt {
        let db = FIRDatabase.database().reference()
        return db.child("\(FireUser.path)/\(id)").observe(eventType, with: block)
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
        self.createdAt = dict["created_at"] as? Int
        self.modifiedAt = dict["modified_at"] as? Int
        self.username = dict["username"] as? String
        if (dict["profile"] as? NSDictionary) != nil {
            self.profile = FireProfile(dict: dict["profile"] as! [String: Any], id: nil)
        }
    }
    
    internal var dict: [String : Any] {
        return [
            "created_at": self.createdAt,
            "modified_at": self.modifiedAt,
            "username": self.username,
            "profile": self.profile?.dict
        ]
    }
}
