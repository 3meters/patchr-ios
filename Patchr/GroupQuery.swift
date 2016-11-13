//
// Created by Jay Massena on 11/13/16.
// Copyright (c) 2016 3meters. All rights reserved.
//

import Foundation

class GroupQuery: NSObject {

    var groupPath: String!
    var groupHandle: UInt!
    var group: FireGroup!

    var linkPath: String!
    var linkHandle: UInt!
    var linkMap: [String: Any]!

    init(groupId: String, userId: String) {
        super.init()
        self.groupPath = "groups/\(groupId)"
        self.linkPath = "member-groups/\(userId)/\(groupId)"
    }

    func observe(with block: @escaping (FireGroup?) -> Swift.Void) {

        self.groupHandle = FireController.db.child(self.groupPath).observe(.value, with: { snap in
            if !(snap.value is NSNull) {
                self.group = FireGroup.from(dict: snap.value as? [String: Any], id: snap.key)
                if self.linkMap != nil {
                    self.group!.membershipFrom(dict: self.linkMap)
                    block(self.group)  // May or may not have link info
                }
            }
            else {
                Log.w("Group snapshot is null")
            }
        })

        self.linkHandle = FireController.db.child(self.linkPath).observe(.value, with: { snap in
            if !(snap.value is NSNull) {
                self.linkMap = snap.value as! [String: Any]
                if self.group != nil {
                    self.group!.membershipFrom(dict: self.linkMap)
                    block(self.group)
                }
            }
            else {
                Log.w("Group link snapshot is null")
            }
        })
    }

    func once(with block: @escaping (FireGroup?) -> Swift.Void) {

        FireController.db.child(self.groupPath).observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                self.group = FireGroup.from(dict: snap.value as? [String: Any], id: snap.key)
                if self.linkMap != nil {
                    self.group!.membershipFrom(dict: self.linkMap)
                    block(self.group)  // May or may not have link info
                }
            }
            else {
                Log.w("Group snapshot is null")
            }
        })

        FireController.db.child(self.linkPath).observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                self.linkMap = snap.value as! [String: Any]
                if self.group != nil {
                    self.group!.membershipFrom(dict: self.linkMap)
                    block(self.group)
                }
            }
            else {
                Log.w("Group link snapshot is null")
            }
        })
    }

    func remove() {
        if self.groupHandle != nil {
            FireController.db.child(self.groupPath).removeObserver(withHandle: self.groupHandle)
        }
        if self.linkHandle != nil {
            FireController.db.child(self.linkPath).removeObserver(withHandle: self.linkHandle)
        }
    }

    deinit {
        remove()
    }
}