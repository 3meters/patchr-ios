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
    
    func getServerTimeOffset(with block: @escaping (Int) -> Swift.Void) {
        FireController.db.child(".info/serverTimeOffset").observeSingleEvent(of: .value, with: { snap in
            if snap.value != nil {
                block(snap.value as! Int!)
            }
        })
    }
    
    func addUserToChannel(groupId: String, channelId: String?, complete block: @escaping (Error?) -> Swift.Void) {
        
        let userId = UserController.instance.userId
        var updates: [String: Any] = [:]
        
        let channelLink: [String: Any] = [
            "sort_priority": 250,
            "muted": false,
            "starred": false,
            "archived": false
        ]
        
        updates["channel-members/\(channelId)/\(userId!)"] = true
        updates["member-channels/\(userId!)/\(groupId)/\(channelId)"] = channelLink
        
        FireController.db.updateChildValues(updates) { (error, ref) in
            block(error)
        }
    }
    
    func addUserToGroup(groupId: String, channelId: String?, guest: Bool, complete block: @escaping (Error?) -> Swift.Void) {
        /*
         * Standard member is added to group membership and all default channels.
         * Guest member is added to group and to targeted channel.
         *
         * Guard: Check and pass if user is already a member of the group. What if being
         * re-invited as a member instead of a guest?
         */
        let userId = UserController.instance.userId
        var updates: [String: Any] = [:]
        
        let channelLink: [String: Any] = [
            "sort_priority": 250,
            "muted": false,
            "starred": false,
            "archived": false
        ]
        
        let groupLink: [String: Any] = [
            "sort_priority": guest ? 350 : 250,
            "disabled": false,
            "role": guest ? "guest" : "member",
            "notifications": "all",
            "hide_email": false,
            "joined_at": FIRServerValue.timestamp()
        ]
        
        updates["member-groups/\(userId!)/\(groupId)"] = groupLink
        updates["group-members/\(groupId)/\(userId!)"] = groupLink
        
        if !guest {
            let defaultChannels = StateController.instance.group.defaultChannels!
            for channelId in defaultChannels {
                updates["channel-members/\(channelId)/\(userId!)"] = true
                updates["member-channels/\(userId!)/\(groupId)/\(channelId)"] = channelLink
            }
        }
        else {
            updates["channel-members/\(channelId)/\(userId!)"] = true
            updates["member-channels/\(userId!)/\(groupId)/\(channelId)"] = channelLink
        }
        
        FireController.db.updateChildValues(updates) { (error, ref) in
            block(error)
        }
    }
}

class MessageQuery: NSObject {
    
    var messagePath: String!
    var messageHandle: UInt!
    var message: FireMessage!

    init(channelId: String, messageId: String) {
        super.init()
        self.messagePath = "channel-messages/\(channelId)/\(messageId)"
    }
    
    func observe(with block: @escaping (FireMessage) -> Swift.Void) {
        self.messageHandle = FireController.db.child(self.messagePath).observe(.value, with: { snap in
            if !(snap.value is NSNull) {
                self.message = FireMessage.from(dict: snap.value as? [String: Any], id: snap.key)
                block(self.message)
            }
        })
    }
    
    func once(with block: @escaping (FireMessage) -> Swift.Void) {
        FireController.db.child(self.messagePath).observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                self.message = FireMessage.from(dict: snap.value as? [String: Any], id: snap.key)
                block(self.message)
            }
        })
    }
    
    func remove() {
        if self.messageHandle != nil {
            FireController.db.child(self.messagePath).removeObserver(withHandle: self.messageHandle)
        }
    }
    
    deinit {
        remove()
    }
}

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
    
    func observe(with block: @escaping (FireUser) -> Swift.Void) {
        self.userHandle = FireController.db.child(self.userPath).observe(.value, with: { snap in
            if !(snap.value is NSNull) {
                self.user = FireUser.from(dict: snap.value as? [String: Any], id: snap.key)
                block(self.user)
            }
        })
    }
    
    func once(with block: @escaping (FireUser) -> Swift.Void) {
        FireController.db.child(self.userPath).observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                self.user = FireUser.from(dict: snap.value as? [String: Any], id: snap.key)
                block(self.user)
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

class GroupQuery: NSObject {
    
    var groupPath: String!
    var groupHandle: UInt!
    var group: FireGroup!
    
    var linkPath: String!
    var linkHandle: UInt!
    var linkMap: [String: Any]!
    
    init(groupId: String, userId: String) {
        super.init()
        self.groupPath = "groups/\(groupId)"
        self.linkPath = "member-groups/\(userId)/\(groupId)"
    }
    
    func observe(with block: @escaping (FireGroup) -> Swift.Void) {
        
        self.groupHandle = FireController.db.child(self.groupPath).observe(.value, with: { snap in
            if !(snap.value is NSNull) {
                self.group = FireGroup.from(dict: snap.value as? [String: Any], id: snap.key)
                if self.linkMap != nil {
                    self.group!.membershipFrom(dict: self.linkMap)
                    block(self.group)  // May or may not have link info
                }
            }
        })
        
        self.linkHandle = FireController.db.child(self.linkPath).observe(.value, with: { snap in
            if !(snap.value is NSNull) {
                self.linkMap = snap.value as! [String: Any]
                if self.group != nil {
                    self.group!.membershipFrom(dict: self.linkMap)
                    block(self.group)
                }
            }
        })
    }
    
    func once(with block: @escaping (FireGroup) -> Swift.Void) {
        
        FireController.db.child(self.groupPath).observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                self.group = FireGroup.from(dict: snap.value as? [String: Any], id: snap.key)
                if self.linkMap != nil {
                    self.group!.membershipFrom(dict: self.linkMap)
                    block(self.group)  // May or may not have link info
                }
            }
        })
        
        FireController.db.child(self.linkPath).observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                self.linkMap = snap.value as! [String: Any]
                if self.group != nil {
                    self.group!.membershipFrom(dict: self.linkMap)
                    block(self.group)
                }
            }
        })
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
