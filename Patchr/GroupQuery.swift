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
    var linkMapMiss = false

    init(groupId: String, userId: String?) {
        super.init()
        self.groupPath = "groups/\(groupId)"
        if userId != nil {
            self.linkPath = "member-groups/\(userId!)/\(groupId)"
        }
    }

    func observe(with block: @escaping (Error?, FireGroup?) -> Swift.Void) {

        self.groupHandle = FireController.db.child(self.groupPath).observe(.value, with: { snap in
            if !(snap.value is NSNull) {
                self.group = FireGroup.from(dict: snap.value as? [String: Any], id: snap.key)
                if self.linkPath == nil || self.linkMapMiss {
                    block(nil, self.group)
                }
                else if self.linkMap != nil {
                    self.group!.membershipFrom(dict: self.linkMap)
                    block(nil, self.group)
                }
            }
            else {
                Log.w("Group snapshot is null")
                block(nil, nil)
            }
        }, withCancel: { error in
            Log.w("Permission denied trying to read group: \(self.groupPath!)")
            block(error, nil)
        })
        
        if self.linkPath != nil {
            self.linkHandle = FireController.db.child(self.linkPath).observe(.value, with: { snap in
                if !(snap.value is NSNull) {
                    self.linkMap = snap.value as! [String: Any]
                    if self.group != nil {
                        self.group!.membershipFrom(dict: self.linkMap)
                        block(nil, self.group)
                    }
                }
                else {
                    /* Group might be fine but user is not member of group anymore */
                    self.linkMapMiss = true
                    if self.group != nil {
                        self.group!.membershipClear()
                        block(nil, self.group)
                    }
                }
            }, withCancel: { error in
                Log.w("Permission denied trying to read group membership: \(self.linkPath!)")
                block(error, nil)
            })
        }
    }

    func once(with block: @escaping (Error?, FireGroup?) -> Swift.Void) {
        
        var fired = false

        FireController.db.child(self.groupPath).observeSingleEvent(of: .value, with: { snap in
            if !fired {
                if !(snap.value is NSNull) {
                    self.group = FireGroup.from(dict: snap.value as? [String: Any], id: snap.key)
                    if self.linkPath == nil || self.linkMapMiss {
                        fired = true
                        block(nil, self.group)
                    }
                    else if self.linkMap != nil {
                        fired = true
                        self.group!.membershipFrom(dict: self.linkMap)
                        block(nil, self.group)  // May or may not have link info
                    }
                }
                else {
                    fired = true
                    Log.w("Group snapshot is null")
                    block(nil, nil)
                }
            }
        }, withCancel: { error in
            Log.w("Permission denied trying to read group: \(self.groupPath!)")
            block(error, nil)
        })

        if self.linkPath != nil {
            FireController.db.child(self.linkPath).observeSingleEvent(of: .value, with: { snap in
                if !fired {
                    if !(snap.value is NSNull) {
                        self.linkMap = snap.value as! [String: Any]
                        if self.group != nil {
                            fired = true
                            self.group!.membershipFrom(dict: self.linkMap)
                            block(nil, self.group)
                        }
                    }
                    else {
                        self.linkMapMiss = true
                        if self.group != nil {
                            fired = true
                            block(nil, self.group)
                        }
                    }
                }
            }, withCancel: { error in
                Log.w("Permission denied trying to read group membership: \(self.linkPath!)")
                block(error, nil)
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
