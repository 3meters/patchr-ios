//
// Created by Jay Massena on 11/13/16.
// Copyright (c) 2016 3meters. All rights reserved.
//

import Foundation

class PresenceQuery: NSObject {
    
    var path: String!
    var handle: UInt!
    
    init(userId: String) {
        super.init()
        self.path = "presence/\(userId)"
    }
    
    func observe(with block: @escaping (Any?) -> Void) {
        self.handle = FireController.db.child(self.path).observe(.value, with: { snap in
            if !(snap.value is NSNull) {
                block(snap.value)
                return
            }
            block(nil)
        })
    }
    
    func once(with block: @escaping (Any?) -> Void) {
        FireController.db.child(self.path).observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                block(snap.value)
                return
            }
            block(nil)
        })
    }
    
    func remove() {
        if self.handle != nil {
            FireController.db.child(self.path).removeObserver(withHandle: self.handle)
        }
    }
    
    deinit {
        remove()
    }
}
