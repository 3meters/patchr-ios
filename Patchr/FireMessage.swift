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

class FireMessage: NSObject {
    
    static let path = "/channel-messages"
    
    var id: String?
    var channel: String?
    var event: String?
    var text: String?
    var attachments: [FireAttachment]?
    var createdAt: Int?
    var createdBy: String?
    var modifiedAt: Int?
    var modifiedBy: String?
    var creator: FireUser?
    
    var pathInstance: String {
        return "\(FireMessage.path)/\(self.channel!)/\(self.id!)"
    }
    
    @discardableResult static func observe(id: String, channelId: String, eventType: FIRDataEventType, with block: @escaping (FIRDataSnapshot) -> Swift.Void) -> UInt {
        let db = FIRDatabase.database().reference()
        return db.child("\(FireMessage.path)/\(channelId)/\(id)").observe(eventType, with: block)
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
        self.channel = dict["channel"] as? String
        self.event = dict["event"] as? String
        self.text = dict["text"] as? String
        if let attachments = dict["attachments"] as? [[String:Any]], attachments.count > 0 {
            self.attachments = [FireAttachment]()
            for attachment in attachments {
                self.attachments?.append(FireAttachment(dict: attachment, id: nil)!)
            }
        }
        self.createdAt = dict["created_at"] as? Int
        self.createdBy = dict["created_by"] as? String
        self.modifiedAt = dict["modified_at"] as? Int
        self.modifiedBy = dict["modified_by"] as? String
    }
    
    internal var dict: [String : Any] {
        var dict: [String: Any] = [
            "channel": self.channel,
            "event": self.event,
            "text": self.text,
            "created_at": self.createdAt,
            "created_by": self.createdBy,
            "modified at": self.modifiedAt,
            "modified_by": self.modifiedBy
        ]
        
        if self.attachments != nil && (self.attachments?.count)! > 0 {
            var attachments: [[String: Any]] = []
            for attachment in self.attachments! {
                attachments.append(attachment.dict)
            }
            dict["attachments"] = attachments
        }
        
        return dict
    }
}
