//
// Created by Jay Massena on 11/13/16.
// Copyright (c) 2016 3meters. All rights reserved.
//

import Foundation
import FirebaseAuth

class GroupQuery: NSObject {

    var authHandle: FIRAuthStateDidChangeListenerHandle!
    
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
            self.linkPath = "group-members/\(groupId)/\(userId!)"
        }
    }

    func observe(with block: @escaping (Error?, Trigger?, FireGroup?) -> Swift.Void) {
        
        self.authHandle = FIRAuth.auth()?.addStateDidChangeListener() { [weak self] auth, user in
            if auth.currentUser == nil {
                self?.remove()
            }
        }

        self.groupHandle = FireController.db.child(self.groupPath).observe(.value, with: { [weak self] snap in
            if !(snap.value is NSNull) {
                self?.group = FireGroup(dict: snap.value as! [String: Any], id: snap.key)
                if self?.linkPath == nil || (self?.linkMapMiss)! {
                    block(nil, .object, self?.group)
                }
                else if self?.linkMap != nil {
                    self?.group!.membershipFrom(dict: (self?.linkMap)!)
                    block(nil, .object, self?.group)
                }
            }
        }, withCancel: { error in
            Log.v("Permission denied trying to read group: \(self.groupPath!)")
            block(error, nil, nil)
        })
        
        if self.linkPath != nil {
            self.linkHandle = FireController.db.child(self.linkPath).observe(.value, with: { [weak self] snap in
                if !(snap.value is NSNull) {
                    self?.linkMap = snap.value as! [String: Any]
                    if self?.group != nil {
                        self?.group!.membershipFrom(dict: (self?.linkMap)!)
                        block(nil, .link, self?.group)
                    }
                }
                else {
                    /* Group might be fine but user is not member of group anymore */
                    self?.linkMapMiss = true
                    if self?.group != nil {
                        self?.group!.membershipClear()
                        block(nil, .link, self?.group)
                    }
                }
            }, withCancel: { error in
                Log.v("Permission denied trying to read group membership: \(self.linkPath!)")
                block(error, nil, nil)
            })
        }
    }

    func once(with block: @escaping (Error?, FireGroup?) -> Swift.Void) {
        
        var fired = false

        FireController.db.child(self.groupPath).observeSingleEvent(of: .value, with: { [weak self] snap in
            if !fired {
                if !(snap.value is NSNull) {
                    self?.group = FireGroup(dict: snap.value as! [String: Any], id: snap.key)
                    if self?.linkPath == nil || (self?.linkMapMiss)! {
                        fired = true
                        block(nil, self?.group)
                    }
                    else if self?.linkMap != nil {
                        fired = true
                        self?.group!.membershipFrom(dict: (self?.linkMap)!)
                        block(nil, self?.group)  // May or may not have link info
                    }
                }
                else {
                    fired = true
                    block(nil, nil)
                }
            }
        }, withCancel: { error in
            Log.v("Permission denied trying to read group: \(self.groupPath!)")
            block(error, nil)
        })

        if self.linkPath != nil {
            FireController.db.child(self.linkPath).observeSingleEvent(of: .value, with: { [weak self] snap in
                if !fired {
                    if !(snap.value is NSNull) {
                        self?.linkMap = snap.value as! [String: Any]
                        if self?.group != nil {
                            fired = true
                            self?.group!.membershipFrom(dict: (self?.linkMap)!)
                            block(nil, self?.group)
                        }
                    }
                    else {
                        /* User might not be a member so send the channel without link info */
                        self?.linkMapMiss = true
                        if self?.group != nil {
                            fired = true
                            block(nil, self?.group)
                        }
                    }
                }
            }, withCancel: { error in
                Log.v("Permission denied trying to read group membership: \(self.linkPath!)")
                block(error, nil)
            })
        }
    }

    func remove() {
        if self.authHandle != nil {
            FIRAuth.auth()?.removeStateDidChangeListener(self.authHandle)
        }
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
