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
    
    var path: String {
        return "channel-messages/\(self.channel!)/\(self.id!)"
    }
    
    var id: String?
    var channel: String?
    var event: String?
    var text: String?
    var attachments: [FireAttachment]?
    var createdAt: Int?
    var createdBy: String?
    var modifiedAt: Int?
    var modifiedBy: String?
    var timestamp: Int?
    var creator: FireUser?
    var reactions: [String: [String: Bool]]?
    
    static func from(dict: [String: Any]?, id: String?) -> FireMessage? {
        if dict != nil {
            let message = FireMessage()
            message.id = id
            message.channel = dict!["channel"] as? String
            message.event = dict!["event"] as? String
            message.text = dict!["text"] as? String
            
            if let attachments = dict!["attachments"] as? [[String:Any]], attachments.count > 0 {
                message.attachments = [FireAttachment]()
                for attachment in attachments {
                    message.attachments?.append(FireAttachment.from(dict: attachment)!)
                }
            }
            
            if let reactions = dict!["reactions"] as? [String:[String: Bool]] {
                message.reactions = reactions
            }
            
            message.createdAt = dict!["created_at"] as? Int
            message.createdBy = dict!["created_by"] as? String
            message.modifiedAt = dict!["modified_at"] as? Int
            message.modifiedBy = dict!["modified_by"] as? String
            message.timestamp = dict!["timestamp"] as? Int
            return message
        }
        return nil
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
    
    func getCreator(with block: @escaping (FireUser) -> Swift.Void) {
        FireController.db.child("users/\(self.createdBy!)").observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                let user = FireUser.from(dict: snap.value as? [String: Any], id: snap.key)
                block(user!)
            }
        })
    }
    
    func addReaction(emoji: Emoji) {
        let userId = UserController.instance.userId
        let path = "channel-messages/\(self.channel!)/\(self.id!)/reactions/\(emoji.rawValue)/\(userId!)"
        FireController.db.child(path).setValue(true)
    }
    
    func removeReaction(emoji: Emoji) {
        let userId = UserController.instance.userId
        let path = "channel-messages/\(self.channel!)/\(self.id!)/reactions/\(emoji.rawValue)/\(userId!)"
        FireController.db.child(path).removeValue()
    }
    
    func getReactionCount(emoji: Emoji) -> Int {
        let reaction = self.reactions?[emoji.rawValue]
        return (reaction?.count ?? 0)
    }
    
    func getReaction(emoji: Emoji, userId: String) -> Bool {
        let reaction = self.reactions?[emoji.rawValue]?[userId]
        return (reaction ?? false)
    }
}
