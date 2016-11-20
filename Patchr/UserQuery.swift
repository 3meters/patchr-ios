//
// Created by Jay Massena on 11/13/16.
// Copyright (c) 2016 3meters. All rights reserved.
//

import Foundation
import Firebase

class UserQuery: NSObject {

    var onlineHandle: UInt!
    
    var userPath: String!
    var userHandle: UInt!
    var user: FireUser!

    var linkPath: String!
    var linkHandle: UInt!
    var linkMap: [String: Any]!

    init(userId: String, groupId: String?, trackPresence: Bool = false) {
        super.init()
        self.userPath = "users/\(userId)"
        if groupId != nil {
            self.linkPath = "group-members/\(groupId!)/\(userId)"
        }
        if trackPresence {
            self.onlineHandle = FireController.db.child(".info/connected").observe(.value, with: { snap in
                if !(snap.value is NSNull) {
                    FireController.db.child(self.userPath).onDisconnectUpdateChildValues(["presence": FIRServerValue.timestamp()])
                    FireController.db.child(self.userPath).updateChildValues(["presence": true])
                }
            })
        }
    }

    func observe(with block: @escaping (FireUser?) -> Swift.Void) {
        
        self.userHandle = FireController.db.child(self.userPath).observe(.value, with: { snap in
            if !(snap.value is NSNull) {
                self.user = FireUser.from(dict: snap.value as? [String: Any], id: snap.key)
                if self.linkPath == nil {
                    block(self.user)  // May or may not have link info
                }
                else if self.linkMap != nil {
                    self.user!.membershipFrom(dict: self.linkMap)
                    block(self.user)  // May or may not have link info
                }
            }
            else {
                Log.w("User snapshot is null")
                block(nil)
            }
        })
        
        if self.linkPath != nil {
            self.linkHandle = FireController.db.child(self.linkPath).observe(.value, with: { snap in
                if !(snap.value is NSNull) {
                    self.linkMap = snap.value as! [String: Any]
                    if self.user != nil {
                        self.user!.membershipFrom(dict: self.linkMap)
                        block(self.user)
                    }
                }
                else {
                    /* User might be fine but group was deleted */
                    if self.user != nil {
                        self.user!.membershipClear()
                        block(self.user)
                    }
                    else {
                        Log.w("User link snapshot is null: \(self.linkPath!)")
                        block(nil)
                    }
                }
            })
        }
    }

    func once(with block: @escaping (FireUser?) -> Swift.Void) {
        
        var fired = false
        
        FireController.db.child(self.userPath).observeSingleEvent(of: .value, with: { snap in
            if !fired {
                if !(snap.value is NSNull) {
                    self.user = FireUser.from(dict: snap.value as? [String: Any], id: snap.key)
                    if self.linkPath == nil {
                        fired = true
                        block(self.user)  // May or may not have link info
                    }
                    else if self.linkMap != nil {
                        fired = true
                        self.user!.membershipFrom(dict: self.linkMap)
                        block(self.user)  // May or may not have link info
                    }
                }
                else {
                    fired = true
                    Log.w("User snapshot is null")
                    block(nil)
                }
            }
        })
        
        if self.linkPath != nil {
            FireController.db.child(self.linkPath).observeSingleEvent(of: .value, with: { snap in
                if !fired {
                    if !(snap.value is NSNull) {
                        self.linkMap = snap.value as! [String: Any]
                        if self.user != nil {
                            fired = true
                            self.user!.membershipFrom(dict: self.linkMap)
                            block(self.user)
                        }
                    }
                    else {
                        fired = true
                        Log.w("User link snapshot is null: \(self.linkPath!)")
                        block(nil)
                    }
                }
            })
        }
    }

    func remove() {
        if self.userHandle != nil {
            FireController.db.child(self.userPath).removeObserver(withHandle: self.userHandle)
        }
        if self.onlineHandle != nil {
            FireController.db.child(".info/connected").removeObserver(withHandle: self.onlineHandle)
        }
    }

    deinit {
        remove()
    }
}
