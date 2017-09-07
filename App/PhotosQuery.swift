//
// Created by Jay Massena on 11/13/16.
// Copyright (c) 2016 3meters. All rights reserved.
//

import Foundation
import FirebaseAuth
import Firebase

class PhotosQuery: NSObject {
    
    var block: ((Error?, FirePhoto?) -> Swift.Void)!
    var limit: UInt!
    var path: String!
    var handle: UInt!
    
    init(channelId: String, limit: Int = 1) {
        super.init()
        self.limit = UInt(limit)
        self.path = "channel-messages/\(channelId)"
    }
    
    func observe(with block: @escaping (Error?, FirePhoto?) -> Void) {
        
        self.block = block
        
        self.handle = FireController.db.child(self.path)
            .queryOrdered(byChild: "attachments")
            .queryStarting(atValue: "")
            .queryLimited(toLast: self.limit)
            .observe(.childAdded, with: { [weak self] snap in
                
            guard let this = self else { return }
            if let dict = snap.value as? [String: Any] {
                let message = FireMessage(dict: dict, id: snap.key)
                if let photo = message.attachments?.values.first?.photo {
                    this.block(nil, photo)
                }
            }
        }, withCancel: { [weak self] error in
            guard let this = self else { return }
            Log.v("Permission denied trying to observe message photos: \(this.path!)")
            this.block(error, nil)
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
