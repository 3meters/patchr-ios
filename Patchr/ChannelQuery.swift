//
// Created by Jay Massena on 11/13/16.
// Copyright (c) 2016 3meters. All rights reserved.
//

import Foundation

class ChannelQuery: NSObject {

    var channelPath: String!
    var channelHandle: UInt!
    var channel: FireChannel!

    var linkPath: String!
    var linkHandle: UInt!
    var linkMap: [String: Any]!

    init(groupId: String, channelId: String, userId: String?) {
        super.init()
        self.channelPath = "group-channels/\(groupId)/\(channelId)"
        if userId != nil {
            self.linkPath = "member-channels/\(userId!)/\(groupId)/\(channelId)"
        }
    }

    func observe(with block: @escaping (FireChannel?) -> Swift.Void) {

        self.channelHandle = FireController.db.child(self.channelPath).observe(.value, with: { snap in
            if !(snap.value is NSNull) {
                self.channel = FireChannel.from(dict: snap.value as? [String: Any], id: snap.key)
                if self.linkPath == nil {
                    block(self.channel)  // May or may not have link info
                }
                else if self.linkMap != nil {
                    self.channel!.membershipFrom(dict: self.linkMap)
                    block(self.channel)  // May or may not have link info
                }
            }
            else {
                Log.w("Channel snapshot is null: \(self.channelPath!)")
                block(nil)
            }
        })

        if self.linkPath != nil {
            self.linkHandle = FireController.db.child(self.linkPath).observe(.value, with: { snap in
                if !(snap.value is NSNull) {
                    self.linkMap = snap.value as! [String: Any]
                    if self.channel != nil {
                        self.channel!.membershipFrom(dict: self.linkMap)
                        block(self.channel)
                    }
                }
                else {
                    Log.w("Channel link snapshot is null: \(self.linkPath!)")
                    block(nil)
                }
            })
        }
    }

    func once(with block: @escaping (FireChannel?) -> Swift.Void) {

        FireController.db.child(self.channelPath).observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                self.channel = FireChannel.from(dict: snap.value as? [String: Any], id: snap.key)
                if self.linkPath == nil {
                    block(self.channel)  // May or may not have link info
                }
                else if self.linkMap != nil {
                    self.channel!.membershipFrom(dict: self.linkMap)
                    block(self.channel)  // May or may not have link info
                }
            }
            else {
                Log.w("Channel snapshot is null: \(self.channelPath!)")
                block(nil)
            }
        })
        
        if self.linkPath != nil {
            FireController.db.child(self.linkPath).observeSingleEvent(of: .value, with: { snap in
                if !(snap.value is NSNull) {
                    self.linkMap = snap.value as! [String: Any]
                    if self.channel != nil {
                        self.channel!.membershipFrom(dict: self.linkMap)
                        block(self.channel)
                    }
                }
                else {
                    Log.w("Channel link snapshot is null: \(self.linkPath!)")
                    block(nil)
                }
            })
        }
    }

    func remove() {
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
