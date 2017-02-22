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
        return "group-messages/\(self.groupId!)/\(self.channelId!)/\(self.id!)"
    }
    
    var attachments: [String: FireAttachment]?
    var channelId: String?
    var createdAt: Int64?
    var createdBy: String?
    var groupId: String?
    var modifiedAt: Int64?
    var modifiedBy: String?
    var reactions: [String: [String: Bool]]?
    var source: String? // 'system' or nil
    var text: String?
    
    // Local
    var creator: FireUser?
    var id: String?
    
    static func from(dict: [String: Any]?, id: String?) -> FireMessage? {
        if dict != nil {
            let message = FireMessage()
            if let attachments = dict!["attachments"] as? [String: Any], attachments.keys.count > 0 {
                message.attachments = [:]
                for attachmentKey in attachments.keys {
                    let attachment = FireAttachment.from(dict: attachments[attachmentKey] as! [String : Any]?, id: attachmentKey)!
                    message.attachments![attachmentKey] = attachment
                }
            }
            message.channelId = dict!["channel_id"] as? String
            message.createdAt = dict!["created_at"] as? Int64
            message.createdBy = dict!["created_by"] as? String
            message.groupId = dict!["group_id"] as? String
            message.id = id
            message.modifiedAt = dict!["modified_at"] as? Int64
            message.modifiedBy = dict!["modified_by"] as? String
            if let reactions = dict!["reactions"] as? [String:[String: Bool]] {
                message.reactions = reactions
            }
            message.source = dict!["source"] as? String
            message.text = dict!["text"] as? String
            
            return message
        }
        return nil
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
        let userId = UserController.instance.userId!
        let path = "group-messages/\(self.groupId!)/\(self.channelId!)/\(self.id!)/reactions/\(emoji.rawValue)/\(userId)"
        FireController.db.child(path).setValue(true)
    }
    
    func removeReaction(emoji: Emoji) {
        let userId = UserController.instance.userId
        let path = "group-messages/\(self.groupId!)/\(self.channelId!)/\(self.id!)/reactions/\(emoji.rawValue)/\(userId)"
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
