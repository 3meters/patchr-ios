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

    init(groupId: String, userId: String?) {
        super.init()
        self.groupPath = "groups/\(groupId)"
        if userId != nil {
            self.linkPath = "member-groups/\(userId!)/\(groupId)"
        }
    }

    func observe(with block: @escaping (FireGroup?) -> Swift.Void) {

        self.groupHandle = FireController.db.child(self.groupPath).observe(.value, with: { snap in
            if !(snap.value is NSNull) {
                self.group = FireGroup.from(dict: snap.value as? [String: Any], id: snap.key)
                if self.linkPath == nil {
                    block(self.group)
                }
                else if self.linkMap != nil {
                    self.group!.membershipFrom(dict: self.linkMap)
                    block(self.group)
                }
            }
            else {
                Log.w("Group snapshot is null")
                block(nil)
            }
        })
        
        if self.linkPath != nil {
            self.linkHandle = FireController.db.child(self.linkPath).observe(.value, with: { snap in
                if !(snap.value is NSNull) {
                    self.linkMap = snap.value as! [String: Any]
                    if self.group != nil {
                        self.group!.membershipFrom(dict: self.linkMap)
                        block(self.group)
                    }
                }
                else {
                    /* Group might be fine but user is not member of group anymore */
                    if self.group != nil {
                        self.group!.membershipClear()
                        block(self.group)
                    }
                    else {
                        Log.w("Group link snapshot is null: \(self.linkPath!)")
                        block(nil)
                    }
                }
            })
        }
    }

    func once(with block: @escaping (FireGroup?) -> Swift.Void) {
        
        var fired = false

        FireController.db.child(self.groupPath).observeSingleEvent(of: .value, with: { snap in
            if !fired {
                if !(snap.value is NSNull) {
                    self.group = FireGroup.from(dict: snap.value as? [String: Any], id: snap.key)
                    if self.linkPath == nil {
                        fired = true
                        block(self.group)
                    }
                    else if self.linkMap != nil {
                        fired = true
                        self.group!.membershipFrom(dict: self.linkMap)
                        block(self.group)  // May or may not have link info
                    }
                }
                else {
                    fired = true
                    Log.w("Group snapshot is null")
                    block(nil)
                }
            }
        })

        if self.linkPath != nil {
            FireController.db.child(self.linkPath).observeSingleEvent(of: .value, with: { snap in
                if !fired {
                    if !(snap.value is NSNull) {
                        self.linkMap = snap.value as! [String: Any]
                        if self.group != nil {
                            fired = true
                            self.group!.membershipFrom(dict: self.linkMap)
                            block(self.group)
                        }
                    }
                    else {
                        fired = true
                        Log.w("Group link snapshot is null")
                        block(nil)
                    }
                }
            })
        }
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
