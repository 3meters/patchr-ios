//
// Created by Jay Massena on 11/13/16.
// Copyright (c) 2016 3meters. All rights reserved.
//

import Foundation
import FirebaseAuth

class UnreadQuery: NSObject {
    
    var authHandle: FIRAuthStateDidChangeListenerHandle!
    
    var path: String!
    var handle: UInt!
    var total: Int!
    var level: UnreadLevel!
    
    init(level: UnreadLevel, userId: String, groupId: String? = nil, channelId: String? = nil) {
        super.init()
        self.level = level
        self.path = "unreads/\(userId)"
        if level == .group {
            self.path = "unreads/\(userId)/\(groupId!)"
        }
        else if level == .channel {
            self.path = "unreads/\(userId)/\(groupId!)/\(channelId!)"
        }
    }
    
    func observe(with block: @escaping (Error?, Int?) -> Void) {
        
        self.authHandle = FIRAuth.auth()?.addStateDidChangeListener() { [weak self] auth, user in
            if auth.currentUser == nil {
                self?.remove()
            }
        }

        self.handle = FireController.db.child(self.path).observe(.value, with: { snap in
            var total = 0
            if !(snap.value is NSNull) {
                if self.level == .channel  {
                    if let messages = snap.value as? [String: Any] {
                        total = messages.count
                    }
                }
                else if self.level == .group {
                    let channels = snap.value as! [String: Any]
                    for channelId in channels.keys {
                        if let messages = channels[channelId] as? [String: Any] {
                            total += messages.count
                        }
                    }
                }
                else if self.level == .user {
                    let groups = snap.value as! [String: Any]
                    for groupId in groups.keys {
                        let channels = groups[groupId] as! [String: Any]
                        for channelId in channels.keys {
                            if let messages = channels[channelId] as? [String: Any] {
                                total += messages.count
                            }
                        }
                    }
                }
                self.total = total
            }
            block(nil, total)
        }, withCancel: { error in
            Log.w("Permission denied trying to read unreads: \(self.path!)")
            block(error, nil)
        })
    }
    
    func remove() {
        if self.authHandle != nil {
            FIRAuth.auth()?.removeStateDidChangeListener(self.authHandle)
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
    case group
    case channel
}
