/*
 * Firebase controller
 *
 * Provide convenience functionality when interacting with the Firebase database.
 */
import UIKit
import Firebase
import FirebaseDatabase

class FireController: NSObject {

    static let instance = FireController()
    
    class var db: FIRDatabaseReference {
        return FIRDatabase.database().reference()
    }

    private override init() {}
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Methods
     *--------------------------------------------------------------------------------------------*/
    
    func getUserOnce(userId: String, with block: @escaping (FireUser) -> Swift.Void) {
        let path = "users/\(userId)"
        FireController.db.child(path).observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                let user = FireUser.from(dict: snap.value as? [String: Any], id: snap.key)
                block(user!)
            }
        })
    }
    
    func getMessageOnce(channelId: String, messageId: String, with block: @escaping (FireMessage) -> Swift.Void) {
        let path = "channel-messages/\(channelId)/\(messageId)"
        FireController.db.child(path).observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                let message = FireMessage.from(dict: snap.value as? [String: Any], id: snap.key)
                block(message!)
            }
        })
    }
    
    func getServerTimeOffset(with block: @escaping (Int) -> Swift.Void) {
        FireController.db.child(".info/serverTimeOffset").observeSingleEvent(of: .value, with: { snap in
            if snap.value != nil {
                block(snap.value as! Int!)
            }
        })
    }
}

class ChannelQuery: NSObject {
    
    var channelPath: String!
    var channelHandle: UInt!
    var channel: FireChannel!
    
    var linkPath: String!
    var linkHandle: UInt!
    var linkMap: [String: Any]!
    
    init(groupId: String, channelId: String, userId: String) {
        super.init()
        self.channelPath = "group-channels/\(groupId)/\(channelId)"
        self.linkPath = "member-channels/\(userId)/\(groupId)/\(channelId)"
    }
    
    func observe(with block: @escaping (FireChannel) -> Swift.Void) {
        
        self.channelHandle = FireController.db.child(self.channelPath).observe(.value, with: { snap in
            if !(snap.value is NSNull) {
                self.channel = FireChannel.from(dict: snap.value as? [String: Any], id: snap.key)
                if self.linkMap != nil {
                    self.channel!.membershipFrom(dict: self.linkMap)
                    block(self.channel)  // May or may not have link info
                }
            }
        })
        
        self.linkHandle = FireController.db.child(self.linkPath).observe(.value, with: { snap in
            if !(snap.value is NSNull) {
                self.linkMap = snap.value as! [String: Any]
                if self.channel != nil {
                    self.channel!.membershipFrom(dict: self.linkMap)
                    block(self.channel)
                }
            }
        })
    }
    
    func once(with block: @escaping (FireChannel) -> Swift.Void) {
        
        FireController.db.child(self.channelPath).observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                self.channel = FireChannel.from(dict: snap.value as? [String: Any], id: snap.key)
                if self.linkMap != nil {
                    self.channel!.membershipFrom(dict: self.linkMap)
                    block(self.channel)  // May or may not have link info
                }
            }
        })
        
        FireController.db.child(self.linkPath).observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                self.linkMap = snap.value as! [String: Any]
                if self.channel != nil {
                    self.channel!.membershipFrom(dict: self.linkMap)
                    block(self.channel)
                }
            }
        })
    }
    
    func remove() {
        if self.channelHandle != nil {
            FireController.db.child(self.channelPath).removeObserver(withHandle: self.channelHandle)
        }
        if self.linkHandle != nil {
            FireController.db.child(self.linkPath).removeObserver(withHandle: self.linkHandle)
        }
    }
    
    deinit {
        remove()
    }
}
