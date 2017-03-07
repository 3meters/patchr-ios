//
// Created by Jay Massena on 11/13/16.
// Copyright (c) 2016 3meters. All rights reserved.
//

import Foundation
import FirebaseAuth

class MessageQuery: NSObject {

    var authHandle: FIRAuthStateDidChangeListenerHandle!

    var messagePath: String!
    var messageHandle: UInt!
    var message: FireMessage!
    
    init(channelId: String, groupId: String, messageId: String) {
        super.init()
        self.messagePath = "group-messages/\(groupId)/\(channelId)/\(messageId)"
    }
    
    func observe(with block: @escaping (Error?, FireMessage?) -> Swift.Void) {        
        self.authHandle = FIRAuth.auth()?.addStateDidChangeListener() { [weak self] auth, user in
            if auth.currentUser == nil {
                self?.remove()
            }
        }
        self.messageHandle = FireController.db.child(self.messagePath).observe(.value, with: { snap in
            if !(snap.value is NSNull) {
                self.message = FireMessage.from(dict: snap.value as? [String: Any], id: snap.key)
                block(nil, self.message)
            }
            else {
                Log.w("Message snapshot is null")
            }
        }, withCancel: { error in
            Log.w("Permission denied trying to read message: \(self.messagePath!)")
            block(error, nil)
        })
    }
    
    func once(with block: @escaping (Error?, FireMessage?) -> Swift.Void) {
        FireController.db.child(self.messagePath).observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                self.message = FireMessage.from(dict: snap.value as? [String: Any], id: snap.key)
                block(nil, self.message)
            }
            else {
                Log.w("Message snapshot is null")
            }
        }, withCancel: { error in
            Log.w("Permission denied trying to read message: \(self.messagePath!)")
            block(error, nil)
        })
    }
    
    func remove() {
        if self.authHandle != nil {
            FIRAuth.auth()?.removeStateDidChangeListener(self.authHandle)
        }
        if self.messageHandle != nil {
            FireController.db.child(self.messagePath).removeObserver(withHandle: self.messageHandle)
        }
    }
    
    deinit {
        remove()
    }
}
