//
// Created by Jay Massena on 11/13/16.
// Copyright (c) 2016 3meters. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth

class UserQuery: NSObject {
    
    var authHandle: FIRAuthStateDidChangeListenerHandle!

    var onlineHandle: UInt!

    var userPath: String!
    var userHandle: UInt!
    var userId: String!
    var user: FireUser!

    var linkPath: String!
    var linkHandle: UInt!
    var linkMap: [String: Any]!
    var linkMapMiss = false
    
    var block: ((Error?, FireUser?) -> ())?

    init(userId: String, groupId: String?, channelId: String? = nil, trackPresence: Bool = false) {
        super.init()
        self.userId = userId
        self.userPath = "users/\(userId)"
        if channelId != nil {
            self.linkPath = "group-channel-members/\(groupId!)/\(channelId!)/\(userId)"
        }
        else if groupId != nil {
            self.linkPath = "group-members/\(groupId!)/\(userId)"
        }
        
        if trackPresence {
            self.onlineHandle = FireController.db.child(".info/connected").observe(.value, with: { [weak self] snap in
                if !(snap.value is NSNull) {
                    let timestamp = FireController.instance.getServerTimestamp()
                    FireController.db.child((self?.userPath)!).onDisconnectUpdateChildValues(["presence": timestamp])
                    FireController.db.child((self?.userPath)!).updateChildValues(["presence": true])
                }
            })
        }
    }

    func observe(with block: @escaping (Error?, FireUser?) -> ()) {
        
        self.authHandle = FIRAuth.auth()?.addStateDidChangeListener() { [weak self] auth, user in
            if auth.currentUser == nil {
                self?.remove()
            }
        }
        
        self.block = block
        self.userHandle = FireController.db.child(self.userPath).observe(.value, with: { [weak self] snap in
            if !(snap.value is NSNull) {
                self?.user = FireUser(dict: snap.value as! [String: Any], id: snap.key)
                if self?.linkPath == nil || (self?.linkMapMiss)! {
                    self?.block?(nil, self?.user)  // May or may not have link info
                }
                else if self?.linkMap != nil {
                    self?.user!.membershipFrom(dict: (self?.linkMap)!)
                    self?.block?(nil, self?.user)  // May or may not have link info
                }
            }
            else {
                self?.block?(nil, nil)
            }
        }, withCancel: { error in
            Log.v("Permission denied trying to read user: \(self.userPath!)")
            block(error, nil)
        })
        
        if self.linkPath != nil {
            self.linkHandle = FireController.db.child(self.linkPath).observe(.value, with: { [weak self] snap in
                if !(snap.value is NSNull) {
                    self?.linkMap = snap.value as! [String: Any]
                    if self?.user != nil {
                        self?.user!.membershipFrom(dict: (self?.linkMap)!)
                        self?.block?(nil, self?.user)
                    }
                }
                else {
                    /* User might be fine but group was deleted */
                    self?.linkMapMiss = true
                    if self?.user != nil {
                        self?.user!.membershipClear()
                        self?.block?(nil, self?.user)
                    }
                }
            }, withCancel: { error in
                Log.v("Permission denied trying to read user membership: \(self.linkPath!)")
                block(error, nil)
            })
        }
    }

    func once(with block: @escaping (Error?, FireUser?) -> ()) {
        
        self.block = block
        var fired = false
        
        FireController.db.child(self.userPath).observeSingleEvent(of: .value, with: { [weak self] snap in
            if !fired {
                if !(snap.value is NSNull) {
                    self?.user = FireUser(dict: snap.value as! [String: Any], id: snap.key)
                    if self?.linkPath == nil || (self?.linkMapMiss)! {
                        fired = true
                        self?.block?(nil, self?.user)  // May or may not have link info
                    }
                    else if self?.linkMap != nil {
                        fired = true
                        self?.user!.membershipFrom(dict: (self?.linkMap)!)
                        self?.block?(nil, self?.user)  // May or may not have link info
                    }
                }
                else {
                    fired = true
                    self?.block?(nil, nil)
                }
            }
        }, withCancel: { error in
            Log.v("Permission denied trying to read user: \(self.userPath!)")
            block(error, nil)
        })
        
        if self.linkPath != nil {
            FireController.db.child(self.linkPath).observeSingleEvent(of: .value, with: { [weak self] snap in
                if !fired {
                    if !(snap.value is NSNull) {
                        self?.linkMap = snap.value as! [String: Any]
                        if self?.user != nil {
                            fired = true
                            self?.user!.membershipFrom(dict: (self?.linkMap)!)
                            self?.block?(nil, self?.user)
                        }
                    }
                    else {
                        self?.linkMapMiss = true
                        if self?.user != nil {
                            fired = true
                            self?.block?(nil, self?.user)
                        }
                    }
                }
            }, withCancel: { error in
                Log.v("Permission denied trying to read user membership: \(self.linkPath!)")
                block(error, nil)
            })
        }
    }

    func remove() {
//        self.user?.profile?.photo = nil
//        self.user?.profile = nil
//        self.user = nil
        if self.authHandle != nil {
            FIRAuth.auth()?.removeStateDidChangeListener(self.authHandle)
        }
        if self.userHandle != nil {
            FireController.db.child(self.userPath).removeObserver(withHandle: self.userHandle)
        }
        if self.linkHandle != nil {
            FireController.db.child(self.linkPath).removeObserver(withHandle: self.linkHandle)
        }
        if self.onlineHandle != nil {
            FireController.db.child(".info/connected").removeObserver(withHandle: self.onlineHandle)
        }
    }

    deinit {
        remove()
    }
}
