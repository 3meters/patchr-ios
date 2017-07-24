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
        return "channel-messages/\(self.channelId!)/\(self.id!)"
    }
    
    var attachments: [String: FireAttachment]?
    var channelId: String?
    var messageId: String?
    var createdAt: Int64?
    var createdBy: String?
    var modifiedAt: Int64?
    var modifiedBy: String?
    var reactions: [String: [String: Bool]]?
    var text: String?
    
    // Local
    var creator: FireUser?
    var id: String?
    
    init(dict: [String: Any], id: String?) {
        if let attachments = dict["attachments"] as? [String: Any], attachments.keys.count > 0 {
            self.attachments = [:]
            for attachmentKey in attachments.keys {
                let attachment = FireAttachment(dict: attachments[attachmentKey] as! [String : Any], id: attachmentKey)
                self.attachments![attachmentKey] = attachment
            }
        }
        self.channelId = dict["channel_id"] as? String
        self.messageId = dict["message_id"] as? String
        self.createdAt = dict["created_at"] as? Int64
        self.createdBy = dict["created_by"] as? String
        self.id = id
        self.modifiedAt = dict["modified_at"] as? Int64
        self.modifiedBy = dict["modified_by"] as? String
        if let reactions = dict["reactions"] as? [String:[String: Bool]] {
            self.reactions = reactions
        }
        self.text = dict["text"] as? String
    }
    
    func getCreator(with block: @escaping (FireUser) -> Swift.Void) {
        FireController.db.child("users/\(self.createdBy!)").observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                let user = FireUser(dict: snap.value as! [String: Any], id: snap.key)
                block(user)
            }
        })
    }
    
    func addReaction(emoji: String) {
        let userId = UserController.instance.userId!
        let path = "channel-messages/\(self.channelId!)/\(self.id!)/reactions/\(emoji)/\(userId)"
        FireController.db.child(path).setValue(true) { error, ref in
            if error != nil {
                Log.w("Permission denied: \(path)")
            }
        }
    }
    
    func removeReaction(emoji: String) {
        let userId = UserController.instance.userId!
        let path = "channel-messages/\(self.channelId!)/\(self.id!)/reactions/\(emoji)/\(userId)"
        FireController.db.child(path).removeValue() { error, ref in
            if error != nil {
                Log.w("Permission denied: \(path)")
            }
        }
    }
    
    func getReactionCount(emoji: String) -> Int {
        let reaction = self.reactions?[emoji]
        return (reaction?.count ?? 0)
    }

    func getReactionsCount() -> Int {
        return self.reactions?.count ?? 0
    }

    func getReaction(emoji: String, userId: String) -> Bool {
        let reaction = self.reactions?[emoji]?[userId]
        return (reaction ?? false)
    }
}
