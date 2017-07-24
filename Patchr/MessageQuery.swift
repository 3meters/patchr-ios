//
// Created by Jay Massena on 11/13/16.
// Copyright (c) 2016 3meters. All rights reserved.
//

import Foundation
import FirebaseAuth

class MessageQuery: NSObject {

    var authHandle: AuthStateDidChangeListenerHandle!

    var block: ((Error?, FireMessage?) -> Swift.Void)!
    var fired = false

    var messagePath: String!
    var messageHandle: UInt!
    var message: FireMessage!
    
    init(channelId: String, messageId: String) {
        super.init()
        self.messagePath = "channel-messages/\(channelId)/\(messageId)"
    }
    
    func observe(with block: @escaping (Error?, FireMessage?) -> Swift.Void) {
        
        self.block = block
        
        self.authHandle = Auth.auth().addStateDidChangeListener() { [weak self] auth, user in
            guard let this = self else { return }
            if auth.currentUser == nil {
                this.remove()
            }
        }
        self.messageHandle = FireController.db.child(self.messagePath).observe(.value, with: { [weak self] snap in
            guard let this = self else { return }
            if let value = snap.value as? [String: Any] {
                this.message = FireMessage(dict: value, id: snap.key)
                this.block(nil, this.message)
            }
        }, withCancel: { [weak self] error in
            guard let this = self else { return }
            Log.v("Permission denied trying to read message: \(this.messagePath!)")
            this.block(error, nil)
        })
    }
    
    func once(with block: @escaping (Error?, FireMessage?) -> Swift.Void) {
        
        self.block = block

        FireController.db.child(self.messagePath).observeSingleEvent(of: .value, with: { [weak self] snap in
            guard let this = self else { return }
            if let value = snap.value as? [String: Any] {
                this.message = FireMessage(dict: value, id: snap.key)
                this.block(nil, this.message)
            }
        }, withCancel: { [weak self] error in
            guard let this = self else { return }
            Log.v("Permission denied trying to read message: \(this.messagePath!)")
            this.block(error, nil)
        })
    }
    
    func remove() {
        if self.authHandle != nil {
            Auth.auth().removeStateDidChangeListener(self.authHandle)
        }
        if self.messageHandle != nil {
            FireController.db.child(self.messagePath).removeObserver(withHandle: self.messageHandle)
        }
    }
    
    deinit {
        remove()
    }
}
