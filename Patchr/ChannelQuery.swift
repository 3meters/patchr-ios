//
// Created by Jay Massena on 11/13/16.
// Copyright (c) 2016 3meters. All rights reserved.
//

import Foundation
import FirebaseAuth

class ChannelQuery: NSObject {
    
    var authHandle: FIRAuthStateDidChangeListenerHandle!
    
    var block: ((Error?, FireChannel?) -> Swift.Void)!
    var fired = false

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
        
        self.block = block
        
        self.authHandle = FIRAuth.auth()?.addStateDidChangeListener() { [weak self] auth, user in
            guard let strongSelf = self else { return }
            if auth.currentUser == nil {
                strongSelf.remove()
            }
        }

        self.channelHandle = FireController.db.child(self.channelPath).observe(.value, with: { [weak self] snap in
            guard let strongSelf = self else { return }
            if let dict = snap.value as? [String: Any] {
                strongSelf.channel = FireChannel(dict: dict, id: snap.key)
                if strongSelf.linkPath == nil || strongSelf.linkMapMiss {
                    strongSelf.block(nil, strongSelf.channel)  // May or may not have link info
                }
                else if strongSelf.linkMap != nil {
                    strongSelf.channel!.membershipFrom(dict: (strongSelf.linkMap)!)
                    strongSelf.block(nil, strongSelf.channel)  // May or may not have link info
                }
            }
        }, withCancel: { [weak self] error in
            guard let strongSelf = self else { return }
            Log.v("Permission denied trying to read channel: \(strongSelf.channelPath!)")
            strongSelf.block(error, nil)
        })

        if self.linkPath != nil {
            self.linkHandle = FireController.db.child(self.linkPath).observe(.value, with: { [weak self] snap in
                guard let strongSelf = self else { return }
                if let dict = snap.value as? [String: Any] {
                    strongSelf.linkMap = dict
                    if strongSelf.channel != nil {
                        strongSelf.channel!.membershipFrom(dict: dict)
                        strongSelf.block(nil, strongSelf.channel)
                    }
                }
                else {
                    strongSelf.linkMapMiss = true
                    if strongSelf.channel != nil {
                        strongSelf.channel!.membershipClear()
                        strongSelf.block(nil, strongSelf.channel)
                    }
                }
            }, withCancel: { [weak self] error in
                guard let strongSelf = self else { return }
                Log.v("Permission denied trying to read channel membership: \(strongSelf.linkPath!)")
                strongSelf.block(error, nil)
            })
        }
    }

    func once(with block: @escaping (Error?, FireChannel?) -> Swift.Void) {
        
        self.block = block

        FireController.db.child(self.channelPath).observeSingleEvent(of: .value, with: { [weak self] snap in
            guard let strongSelf = self else { return }
            if !strongSelf.fired {
                if let dict = snap.value as? [String: Any] {
                    strongSelf.channel = FireChannel(dict: dict, id: snap.key)
                    if strongSelf.linkPath == nil || strongSelf.linkMapMiss {
                        strongSelf.fired = true
                        strongSelf.block(nil, strongSelf.channel)  // May or may not have link info
                    }
                    else if strongSelf.linkMap != nil {
                        strongSelf.fired = true
                        strongSelf.channel!.membershipFrom(dict: (strongSelf.linkMap)!)
                        strongSelf.block(nil, strongSelf.channel)  // May or may not have link info
                    }
                }
                else {
                    strongSelf.fired = true
                    strongSelf.block(nil, nil)
                }
            }
        }, withCancel: { [weak self] error in
            guard let strongSelf = self else { return }
            Log.v("Permission denied trying to read channel: \(strongSelf.channelPath!)")
            strongSelf.block(error, nil)
        })
        
        if self.linkPath != nil {
            FireController.db.child(self.linkPath).observeSingleEvent(of: .value, with: { [weak self] snap in
                guard let strongSelf = self else { return }
                if !strongSelf.fired {
                    if let dict = snap.value as? [String: Any] {
                        strongSelf.linkMap = dict
                        if strongSelf.channel != nil {
                            strongSelf.fired = true
                            strongSelf.channel!.membershipFrom(dict: dict)
                            strongSelf.block(nil, strongSelf.channel)
                        }
                    }
                    else {
                        /* User might not be a member so send the channel without link info */
                        strongSelf.linkMapMiss = true
                        if strongSelf.channel != nil {
                            strongSelf.fired = true
                            strongSelf.block(nil, strongSelf.channel)
                        }
                    }
                }
            }, withCancel: { [weak self] error in
                guard let strongSelf = self else { return }
                Log.v("Permission denied trying to read channel membership: \(strongSelf.linkPath!)")
                strongSelf.block(error, nil)
            })
        }
    }

    func remove() {
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
