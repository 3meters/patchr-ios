//
// Created by Jay Massena on 11/13/16.
// Copyright (c) 2016 3meters. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase

class UnreadQuery: NSObject {
    
    var authHandle: AuthStateDidChangeListenerHandle!
    
    var block: ((Error?, Int?) -> Swift.Void)!

    var path: String!
    var handle: UInt!
    var total: Int!
    var level: UnreadLevel!
    
    init(level: UnreadLevel, userId: String, channelId: String? = nil, messageId: String? = nil, commentId: String? = nil) {
        super.init()
        self.level = level
        if level == .user {
            self.path = "unreads/\(userId)"
        }
        else if level == .channel {
            self.path = "unreads/\(userId)/\(channelId!)"
        }
        else if level == .message {
            self.path = "unreads/\(userId)/\(channelId!)/\(messageId!)/message"
        }
        else if level == .comment {
            self.path = "unreads/\(userId)/\(channelId!)/\(messageId!)/comments/\(commentId!)"
        }
        else if level == .comments {
            self.path = "unreads/\(userId)/\(channelId!)/\(messageId!)/comments"
        }
    }
    
    func observe(event: DataEventType = .value, with block: @escaping (Error?, Int?) -> Void) {
        
        self.block = block
        
        self.authHandle = Auth.auth().addStateDidChangeListener() { [weak self] auth, user in
            guard let this = self else { return }
            if auth.currentUser == nil {
                this.remove()
            }
        }

        self.handle = FireController.db.child(self.path).observe(event, with: { [weak self] snap in
            guard let this = self else { return }
            var total = 0
            if !(snap.value is NSNull) {
                if this.level == .comment  {
                    total = 1
                }
                else if this.level == .message  {
                    total = 1
                }
                else if this.level == .comments  {
                    if let comments = snap.value as? [String: Any] {
                        total = comments.count
                    }
                }
                else if this.level == .channel  {
                    if let messages = snap.value as? [String: Any] {
                        total = messages.count
                    }
                }
                else if this.level == .user {
                    let channels = snap.value as! [String: Any]
                    for channelId in channels.keys {
                        if let messages = channels[channelId] as? [String: Any] {
                            total += messages.count
                        }
                    }
                }
                this.total = total
            }
            this.block(nil, total)
            
        }, withCancel: { [weak self] error in
            guard let this = self else { return }
            Log.v("Permission denied trying to observe unreads: \(this.path!)")
            this.block(error, nil)
        })
    }

    func once(event: DataEventType = .value, with then: @escaping (Error?, Int?) -> Void) {
        
        self.block = then
        
        FireController.db.child(self.path).observeSingleEvent(of: event, with: { [weak self] snap in
            guard let this = self else { return }
            var total = 0
            if !(snap.value is NSNull) {
                if this.level == .comment  {
                    total = 1
                }
                else if this.level == .message  {
                    total = 1
                }
                else if this.level == .comments  {
                    if let comments = snap.value as? [String: Any] {
                        total = comments.count
                    }
                }
                else if this.level == .channel  {
                    if let messages = snap.value as? [String: Any] {
                        total = messages.count
                    }
                }
                else if this.level == .user {
                    let channels = snap.value as! [String: Any]
                    for channelId in channels.keys {
                        if let messages = channels[channelId] as? [String: Any] {
                            total += messages.count
                        }
                    }
                }
                this.total = total
            }
            this.block(nil, total)
            
        }, withCancel: { [weak self] error in
                guard let this = self else { return }
                Log.v("Permission denied trying to read unreads once: \(this.path!)")
                this.block(error, nil)
        })
    }

    func remove() {
        if self.authHandle != nil {
            Auth.auth().removeStateDidChangeListener(self.authHandle)
        }
        if self.handle != nil {
            FireController.db.child(self.path).removeObserver(withHandle: self.handle)
        }
    }
    
    deinit {
        remove()
    }
}

enum UnreadLevel: Int {
    case user
    case channel
    case message
    case comment
    case comments
}
