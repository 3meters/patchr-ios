//
// Created by Jay Massena on 11/13/16.
// Copyright (c) 2016 3meters. All rights reserved.
//

import Foundation
import Firebase

class UserQuery: NSObject {

    var userPath: String!
    var userHandle: UInt!
    var user: FireUser!
    var onlineHandle: UInt!

    init(userId: String, trackPresence: Bool = false) {
        super.init()
        self.userPath = "users/\(userId)"
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
                block(self.user)
            }
            else {
                Log.w("User snapshot is null")
            }
        })
    }

    func once(with block: @escaping (FireUser?) -> Swift.Void) {
        FireController.db.child(self.userPath).observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                self.user = FireUser.from(dict: snap.value as? [String: Any], id: snap.key)
                block(self.user)
            }
            else {
                Log.w("User snapshot is null")
            }
        })
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
