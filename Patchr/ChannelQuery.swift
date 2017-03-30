//
// Created by Jay Massena on 11/13/16.
// Copyright (c) 2016 3meters. All rights reserved.
//

import Foundation
import FirebaseAuth

class ChannelQuery: NSObject {
    
    var authHandle: FIRAuthStateDidChangeListenerHandle!

    var channelPath: String!
    var channelHandle: UInt!
    var channel: FireChannel!

    var linkPath: String!
    var linkHandle: UInt!
    var linkMap: [String: Any]!
    var linkMapMiss = false

    init(groupId: String, channelId: String, userId: String?) {
        super.init()
        self.channelPath = "group-channels/\(groupId)/\(channelId)"
        if userId != nil {
            self.linkPath = "group-channel-members/\(groupId)/\(channelId)/\(userId!)"
        }
    }

    func observe(with block: @escaping (Error?, FireChannel?) -> Swift.Void) {
        
        self.authHandle = FIRAuth.auth()?.addStateDidChangeListener() { [weak self] auth, user in
            if auth.currentUser == nil {
                self?.remove()
            }
        }

        self.channelHandle = FireController.db.child(self.channelPath).observe(.value, with: { [weak self] snap in
            if !(snap.value is NSNull) {
                self?.channel = FireChannel(dict: snap.value as! [String: Any], id: snap.key)
                if self?.linkPath == nil || (self?.linkMapMiss)! {
                    block(nil, self?.channel)  // May or may not have link info
                }
                else if self?.linkMap != nil {
                    self?.channel!.membershipFrom(dict: (self?.linkMap)!)
                    block(nil, self?.channel)  // May or may not have link info
                }
            }
            else {
                block(nil, nil)
            }
        }, withCancel: { error in
            Log.v("Permission denied trying to read channel: \(self.channelPath!)")
            block(error, nil)
        })

        if self.linkPath != nil {
            self.linkHandle = FireController.db.child(self.linkPath).observe(.value, with: { [weak self] snap in
                if !(snap.value is NSNull) {
                    self?.linkMap = snap.value as! [String: Any]
                    if self?.channel != nil {
                        self?.channel!.membershipFrom(dict: (self?.linkMap)!)
                        block(nil, self?.channel)
                    }
                }
                else {
                    /* User might not be a member so send the channel without link info */
                    self?.linkMapMiss = true
                    if self?.channel != nil {
                        self?.channel!.membershipClear()
                        block(nil, self?.channel)
                    }
                }
            }, withCancel: { error in
                Log.v("Permission denied trying to read channel membership: \(self.linkPath!)")
                block(error, nil)
            })
        }
    }

    func once(with block: @escaping (Error?, FireChannel?) -> Swift.Void) {
        
        var fired = false

        FireController.db.child(self.channelPath).observeSingleEvent(of: .value, with: { [weak self] snap in
            if !fired {
                if !(snap.value is NSNull) {
                    self?.channel = FireChannel(dict: snap.value as! [String: Any], id: snap.key)
                    if self?.linkPath == nil || (self?.linkMapMiss)! {
                        fired = true
                        block(nil, self?.channel)  // May or may not have link info
                    }
                    else if self?.linkMap != nil {
                        fired = true
                        self?.channel!.membershipFrom(dict: (self?.linkMap)!)
                        block(nil, self?.channel)  // May or may not have link info
                    }
                }
                else {
                    fired = true
                    block(nil, nil)
                }
            }
        }, withCancel: { error in
            Log.v("Permission denied trying to read channel: \(self.channelPath!)")
            block(error, nil)
        })
        
        if self.linkPath != nil {
            FireController.db.child(self.linkPath).observeSingleEvent(of: .value, with: { [weak self] snap in
                if !fired {
                    if !(snap.value is NSNull) {
                        self?.linkMap = snap.value as! [String: Any]
                        if self?.channel != nil {
                            fired = true
                            self?.channel!.membershipFrom(dict: (self?.linkMap)!)
                            block(nil, self?.channel)
                        }
                    }
                    else {
                        /* User might not be a member so send the channel without link info */
                        self?.linkMapMiss = true
                        if self?.channel != nil {
                            fired = true
                            block(nil, self?.channel)
                        }
                    }
                    
                }
            }, withCancel: { error in
                Log.v("Permission denied trying to read channel membership: \(self.linkPath!)")
                block(error, nil)
            })
        }
    }

    func remove() {
        self.channel?.photo = nil
        self.channel = nil
        if self.authHandle != nil {
            FIRAuth.auth()?.removeStateDidChangeListener(self.authHandle)
        }
        if self.channelHandle != nil {
            FireController.db.child(self.channelPath).removeObserver(withHandle: self.channelHandle)
        }
        if self.linkHandle != nil {
            FireController.db.child(self.linkPath).removeObserver(withHandle: self.linkHandle)
        }
    }

    deinit {
        remove()
    }
}
