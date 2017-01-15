/*
 * Firebase controller
 *
 * Provide convenience functionality when interacting with the Firebase database.
 */
import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth

class FireController: NSObject {

    static let instance = FireController()
    
    class var db: FIRDatabaseReference {
        return FIRDatabase.database().reference()
    }
    
    var serverOffset: Int?
    let priorities = [1, 2, 3, 4, 5, 6, 7, 8, 9]

    private override init() { }
    
    func prepare() {
        FireController.db.child(".info/serverTimeOffset").observe(.value, with: { snap in
            if !(snap.value is NSNull) {
                self.serverOffset = snap.value as! Int!
            }
        })
        /* So email lookups will work right */
        FireController.db.child("users").keepSynced(true)
    }
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Methods
     *--------------------------------------------------------------------------------------------*/
    
    func addUser(userId: String, username: String, email: String, then: ((Bool) -> Void)? = nil) {
        
        let timestamp = Utils.now() + (FireController.instance.serverOffset ?? 0)
        var updates: [String: Any] = [:]
        
        let userMap: [String: Any] = [
            "created_at": Int(timestamp),
            "modified_at": Int(timestamp),
            "username": username,
            "email": email
        ]

        updates["users/\(userId)"] = userMap
        
        FireController.db.updateChildValues(updates) { error, ref in
            then?(error == nil)
        }
    }
    
    func addGroup(groupId: String, groupMap: inout [String: Any], then: ((Bool) -> Void)? = nil) {
        
        let userId = UserController.instance.userId!
        let timestamp = Utils.now() + (FireController.instance.serverOffset ?? 0)
        var updates: [String: Any] = [:]
        
        /* Add group */
        
        groupMap["created_at"] = Int(timestamp)
        groupMap["created_by"] = userId
        groupMap["modified_at"] = Int(timestamp)
        groupMap["modified_by"] = userId
        groupMap["owned_by"] = userId
        
        /* Add creator as admin member */
        
        let groupPriority = 3   // admin
        let groupLink = groupMemberMap(timestamp: timestamp, priorityIndex: groupPriority, role: "owner")
        updates["member-groups/\(userId)/\(groupId)"] = groupLink
        updates["group-members/\(groupId)/\(userId)"] = groupLink
        
        /* Add default channels */
        
        let generalId = "ch-\(Utils.genRandomId())"
        let chatterId = "ch-\(Utils.genRandomId())"
        
        let generalMap: [String: Any] = [
            "group": groupId,
            "type": "channel",
            "name": "general",
            "purpose": "This channel is for messaging and announcements to the whole group. All group members are in this channel.",
            "general": true,
            "archived": false,
            "visibility": "open",
            "created_at": Int(timestamp),
            "created_by": userId ]
        
        let chatterMap: [String: Any] = [
            "group": groupId,
            "type": "channel",
            "name": "chatter",
            "purpose": "The perfect place for crazy talk that you\'d prefer to keep off the other channels.",
            "general": false,
            "archived": false,
            "visibility": "open",
            "created_at": Int(timestamp),
            "created_by": userId ]
        
        groupMap["default_channels"] = [generalId, chatterId]
        updates["group-channels/\(groupId)/\(generalId)"] = generalMap
        updates["group-channels/\(groupId)/\(chatterId)"] = chatterMap
        
        updates["groups/\(groupId)"] = groupMap
        
        /* Add creator as member of default channels */
        
        let generalLink = self.channelMemberMap(timestamp: timestamp, priorityIndex: 2, role: "owner" /* general */)
        updates["channel-members/\(generalId)/\(userId)"] = true
        updates["member-channels/\(userId)/\(groupId)/\(generalId)"] = generalLink
        
        let chatterLink = self.channelMemberMap(timestamp: timestamp, priorityIndex: 3, role: "owner" /* general */)
        updates["channel-members/\(chatterId)/\(userId)"] = true
        updates["member-channels/\(userId)/\(groupId)/\(chatterId)"] = chatterLink
        
        FireController.db.updateChildValues(updates) { error, ref in
            then?(error == nil)
        }
    }
    
    func addChannelToGroup(channelId: String, channelMap: [String: Any], groupId: String, then: ((Bool) -> Void)? = nil) {
        
        var updates: [String: Any] = [:]
        updates["group-channels/\(groupId)/\(channelId)"] = channelMap
        
        /* Make all non-guests members of public channels */
        if (channelMap["visibility"] as? String) == "open" {
            FireController.db.child("group-members/\(groupId)").observeSingleEvent(of: .value, with: { snap in
                if !(snap.value is NSNull) {
                    let membersMap = snap.value as! [String: Any]
                    for (memberId, membership) in membersMap {
                        let membershipMap = membership as! [String: Any]
                        if (membershipMap["role"] as? String) != "guest" {
                            let role = (memberId == UserController.instance.userId) ? "owner" : "member"
                            let channelLink = self.channelMemberMap(timestamp: Utils.now(), priorityIndex: 4, role: role /* neutral */)
                            updates["channel-members/\(channelId)/\(memberId)"] = true
                            updates["member-channels/\(memberId)/\(groupId)/\(channelId)"] = channelLink
                        }
                    }
                    FireController.db.updateChildValues(updates) { error, ref in
                        then?(error == nil)
                    }
                }
                then?(false)
            })
        }
        else {
            /* Add creator as first member of private channel */
            let userId = UserController.instance.userId
            let channelLink = channelMemberMap(timestamp: Utils.now(), priorityIndex: 4, role: "owner" /* neutral */)
            updates["channel-members/\(channelId)/\(userId!)"] = true
            updates["member-channels/\(userId!)/\(groupId)/\(channelId)"] = channelLink

            FireController.db.updateChildValues(updates) { error, ref in
                then?(error == nil)
            }
        }
    }
    
    func addUserToChannel(userId: String, groupId: String, channelId: String, then: ((Bool) -> Void)? = nil) {
        
        let channelLink = channelMemberMap(timestamp: Utils.now(), priorityIndex: 4, role: "member" /* neutral */)
        var updates: [String: Any] = [:]
        updates["channel-members/\(channelId)/\(userId)"] = true
        updates["member-channels/\(userId)/\(groupId)/\(channelId)"] = channelLink
        FireController.db.updateChildValues(updates) { error, ref in
            then?(error == nil)
        }
    }
    
    func addUserToChannels(userId: String, groupId: String, channels: [String: Any], then: ((Bool) -> Void)? = nil) {
        
        let channelLink = channelMemberMap(timestamp: Utils.now(), priorityIndex: 4, role: "member" /* neutral */)
        var updates: [String: Any] = [:]
        for channelId in channels.keys {
            updates["channel-members/\(channelId)/\(userId)"] = true
            updates["member-channels/\(userId)/\(groupId)/\(channelId)"] = channelLink
        }
        FireController.db.updateChildValues(updates) { error, ref in
            then?(error == nil)
        }
    }

    func addUserToGroup(userId: String, groupId: String, channels: [String: Any]?, role: String, email: String, then: ((Bool) -> Void)? = nil) {
        /*
         * Standard member is added to group membership and all default channels.
         * Guest member is added to group and to targeted channel.
         */
        let timestamp = Utils.now()
        let channelLink = channelMemberMap(timestamp: timestamp, priorityIndex: 4, role: "member")
        
        var updates: [String: Any] = [:]
        
        if channels != nil {
            for channelId in channels!.keys {
                updates["channel-members/\(channelId)/\(userId)"] = true
                updates["member-channels/\(userId)/\(groupId)/\(channelId)"] = channelLink
            }
        }
        
        let groupPriority = (role == "guest") ? 5 : 4
        let groupLink = groupMemberMap(timestamp: Utils.now(), priorityIndex: groupPriority, role: role)
        
        updates["member-groups/\(userId)/\(groupId)"] = groupLink
        updates["group-members/\(groupId)/\(userId)"] = groupLink
        
        FireController.db.child("invites/\(groupId)")
            .queryOrdered(byChild: "email")
            .queryEqual(toValue: email)
            .observeSingleEvent(of: .value, with: { snap in
                if !(snap.value is NSNull) {
                    if let mapInvite = snap.value as? [String: Any] {
                        let inviteId = mapInvite.first!.key
                        FireController.db.child("invites/\(groupId)/\(inviteId)/accepted_at").setValue(Int(floorf(Float(timestamp))))
                        FireController.db.child("invites/\(groupId)/\(inviteId)/accepted_by").setValue(userId)
                        FireController.db.child("invites/\(groupId)/\(inviteId)/status").setValue("accepted")
                    }
                }
                if role != "guest" {
                    let pathDefaults = "groups/\(groupId)/default_channels"
                    FireController.db.child(pathDefaults).observeSingleEvent(of: .value, with: { snap in
                        
                        if !(snap.value is NSNull) {
                            let defaultChannelIds = snap.value as! [String]
                            let defaultChannelLink = self.channelMemberMap(timestamp: timestamp, priorityIndex: 3, role: "member")
                            for defaultChannelId in defaultChannelIds {
                                updates["channel-members/\(defaultChannelId)/\(userId)"] = true
                                updates["member-channels/\(userId)/\(groupId)/\(defaultChannelId)"] = defaultChannelLink
                            }
                        }
                        
                        FireController.db.updateChildValues(updates) { error, ref in
                            then?(error == nil)
                        }
                    })
                }
                else {
                    FireController.db.updateChildValues(updates) { error, ref in
                        then?(error == nil)
                    }
                }
        })
    }
    
    func removeUserFromGroup(userId: String, groupId: String, then: ((Bool) -> Void)? = nil) {
        /*
         * - remove from member-groups and group-members
         * - remove from all member-channels and channel-members
         */
        var updates: [String: Any] = [:]
        
        updates["member-groups/\(userId)/\(groupId)"] = NSNull()
        updates["group-members/\(groupId)/\(userId)"] = NSNull()
        
        let query = FireController.db.child("member-channels/\(userId)/\(groupId)")
        query.observeSingleEvent(of: .value, with: { snap in
            
            if !(snap.value is NSNull) && snap.hasChildren() {
                for channelSnap in snap.children  {
                    let channelFoo = channelSnap as! FIRDataSnapshot
                    updates["channel-members/\(channelFoo.key)/\(userId)"] = NSNull()
                }
            }
            
            FireController.db.updateChildValues(updates) { error, ref in
                if error == nil {
                    let updates: [String: Any] = ["member-channels/\(userId)/\(groupId)": NSNull()]
                    FireController.db.updateChildValues(updates) { error, ref in
                        if error == nil {
                            var task: [String: Any] = [:]
                            task["target"] = "group"
                            task["groupId"] = groupId
                            let queueRef = FireController.db.child("queue/clear-unreads").childByAutoId()
                            queueRef.setValue(task)
                        }
                        then?(error == nil)
                    }
                }
                else {
                    then?(error == nil)
                }
            }
        })
    }

    func removeUserFromChannel(userId: String, groupId: String, channelId: String, then: ((Bool) -> Void)? = nil) {
        var updates: [String: Any] = [:]
        updates["member-channels/\(userId)/\(groupId)/\(channelId)"] = NSNull()
        updates["channel-members/\(channelId)/\(userId)"] = NSNull()
        FireController.db.updateChildValues(updates) { error, ref in
            if error == nil {
                var task: [String: Any] = [:]
                task["target"] = "channel"
                task["groupId"] = groupId
                task["channelId"] = channelId
                let queueRef = FireController.db.child("queue/clear-unreads").childByAutoId()
                queueRef.setValue(task)
            }
            then?(error == nil)
        }
    }

    func channelMemberMap(timestamp: Int64, priorityIndex: Int, role: String) -> [String: Any] {
        
        let priority = self.priorities[priorityIndex]
        let priorityReversed = self.priorities.reversed()[priorityIndex]
        let joinedAt = Int(floorf(Float(timestamp / 1000)))
        let index = Int("\(priority)\(joinedAt)")
        let indexReversed = Int("-\(priorityReversed)\(joinedAt)")
        
        let link: [String: Any] = [
            "archived": false,
            "muted": false,
            "starred": false,
            "priority": priority,
            "role": role,
            "joined_at": joinedAt,
            "joined_at_desc": joinedAt * -1,
            "index_priority_joined_at": index!,
            "index_priority_joined_at_desc": indexReversed!
        ]
        
        return link
    }
    
    func groupMemberMap(timestamp: Int64, priorityIndex: Int, role: String) -> [String: Any] {
        
        let priority = self.priorities[priorityIndex]
        let priorityReversed = self.priorities.reversed()[priorityIndex]
        let joinedAt = Int(floorf(Float(timestamp / 1000)))
        let index = Int("\(priority)\(joinedAt)")
        let indexReversed = Int("-\(priorityReversed)\(joinedAt)")
        
        let link: [String: Any] = [
            "disabled": false,
            "hide_email": false,
            "notifications": "all",
            "role": role,
            "priority": priority,
            "joined_at": joinedAt,
            "joined_at_desc": joinedAt * -1,
            "index_priority_joined_at": index!,
            "index_priority_joined_at_desc": indexReversed!
        ]
        
        return link
    }
    
    func delete(groupId: String, execute: Bool = true, then: (([String: Any]?) -> Void)? = nil) {
        /*
         * - delete group x
         * - delete group-channels x
         * - delete each channel for the group
         * - delete group-members x
         * - delete member-groups for each group member x
         */
        let pathGroup = "groups/\(groupId)"
        let pathGroupChannels = "group-channels/\(groupId)"
        let pathGroupMembers = "group-members/\(groupId)"
        
        var updates: [String: Any] = [:]

        let phaseTwo: [String: Any] = [
            pathGroup: NSNull(),
            pathGroupMembers: NSNull(),
            pathGroupChannels: NSNull()
        ]

        FireController.db.child(pathGroupMembers).observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                let linkMap = snap.value as! [String: Any]
                for userId in linkMap.keys {
                    updates["member-groups/\(userId)/\(groupId)"] = NSNull()
                }
            }
            
            FireController.db.child(pathGroupChannels).observeSingleEvent(of: .value, with: { snap in
                if !(snap.value is NSNull) {
                    let channelMaps = snap.value as! [String: Any]
                    var remaining = channelMaps.keys.count
                    for channelId in channelMaps.keys {
                        self.delete(channelId: channelId, groupId: groupId, execute: false, then: { channelUpdates in
                            if channelUpdates != nil {
                                for key in (channelUpdates!.keys) {
                                    updates[key] = channelUpdates![key]
                                }
                                remaining -= 1
                                if remaining == 0 {
                                    if execute {
                                        FireController.db.updateChildValues(updates) { error, ref in
                                            if error == nil {
                                                FireController.db.updateChildValues(phaseTwo) { error, ref in
                                                    if error == nil {
                                                        Log.d("Group deleted: \(groupId)")
                                                        
                                                        var task: [String: Any] = [:]
                                                        task["target"] = "group"
                                                        task["groupId"] = groupId
                                                        let queueRef = FireController.db.child("queue/clear-unreads").childByAutoId()
                                                        queueRef.setValue(task)

                                                        then?(updates)
                                                        return
                                                    }
                                                    then?(nil)
                                                }
                                            }
                                        }
                                    }
                                    else {
                                        then?(updates)
                                    }
                                }
                            }
                        })
                    }
                }
            })
        })
    }
    
    func deleteInvite(groupId: String, inviteId: String) {
        FireController.db.child("invites/\(groupId)/\(inviteId)").removeValue()
    }
    
    func delete(channelId: String, groupId: String, execute: Bool = true, then: (([String: Any]?) -> Void)? = nil) {
        
        let pathChannelMessages = "channel-messages/\(channelId)"
        let pathChannelMembers = "channel-members/\(channelId)"
        let pathGroupChannels = "group-channels/\(groupId)/\(channelId)"
        
        var updates: [String: Any] = [
            pathGroupChannels: NSNull(),
            pathChannelMessages: NSNull(),
            pathChannelMembers: NSNull()
        ]
        
        FireController.db.child(pathChannelMembers).observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                let linkMap = snap.value as! [String: Any]
                for userId in linkMap.keys {
                    updates["member-channels/\(userId)/\(groupId)/\(channelId)"] = NSNull()
                }
            }
            
            let pathDefaults = "groups/\(groupId)/default_channels"
            FireController.db.child(pathDefaults).observeSingleEvent(of: .value, with: { snap in
                
                if !(snap.value is NSNull) {
                    let defaultChannelIds = snap.value as! [String]
                    var newDefaults: [String] = []
                    for defaultChannelId in defaultChannelIds {
                        if channelId != defaultChannelId {
                            newDefaults.append(defaultChannelId)
                        }
                    }
                    updates[pathDefaults] = newDefaults
                }
                if execute {
                    FireController.db.updateChildValues(updates) { error, ref in
                        if error == nil {
                            Log.d("Channel deleted: \(channelId)")
                            
                            var task: [String: Any] = [:]
                            task["target"] = "channel"
                            task["groupId"] = groupId
                            task["channelId"] = channelId
                            let queueRef = FireController.db.child("queue/clear-unreads").childByAutoId()
                            queueRef.setValue(task)

                            then?(updates)
                            return
                        }
                        then?(nil)
                    }
                }
                else {
                    then?(updates)
                }
            })
        })
    }
    
    func delete(messageId: String, channelId: String, groupId: String, then: (([String: Any]?) -> Void)? = nil) {
        
        let path = "channel-messages/\(channelId)"
        let updates: [String: Any] = [messageId: NSNull()]
        
        FireController.db.child(path).updateChildValues(updates) { error, ref in
            if error == nil {
                Log.d("Message deleted: \(messageId)")
                
                var task: [String: Any] = [:]
                task["target"] = "message"
                task["groupId"] = groupId
                task["channelId"] = channelId
                task["messageId"] = messageId
                let queueRef = FireController.db.child("queue/clear-unreads").childByAutoId()
                queueRef.setValue(task)
                
                then?(updates)
                return
            }            
            then?(nil)
        }
    }
    
    func clearMessageUnread(messageId: String, channelId: String, groupId: String) {
        let userId = UserController.instance.userId!
        let unreadPath = "unreads/\(userId)/\(groupId)/\(channelId)/\(messageId)"
        FireController.db.child(unreadPath).removeValue()
    }
    
    func findFirstChannel(groupId: String, next: ((String?) -> Void)? = nil) {
        let userId = UserController.instance.userId!
        let query = FireController.db.child("member-channels/\(userId)/\(groupId)").queryOrdered(byChild: "index_priority_joined_at_desc").queryLimited(toFirst: 1)
        
        query.observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) && snap.hasChildren() {
                let channelId = (snap.children.nextObject() as! FIRDataSnapshot).key
                next?(channelId)
                return
            }
            next?(nil)
        })
    }
    
    func findGeneralChannel(groupId: String, next: ((String?) -> Void)? = nil) {
        let query = FireController.db.child("group-channels/\(groupId)").queryOrdered(byChild: "general").queryEqual(toValue: true)
        
        query.observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) && snap.hasChildren() {
                let channelId = (snap.children.nextObject() as! FIRDataSnapshot).key
                next?(channelId)
                return
            }
            next?(nil)
        })
    }
    
    func findFirstGroup(userId: String, next: ((String?) -> Void)? = nil) {
        let query = FireController.db.child("member-groups/\(userId)")
            .queryOrdered(byChild: "index_priority_joined_at_desc")
            .queryLimited(toFirst: 1)
        
        query.observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                next?(snap.key)
                return
            }
            next?(nil)
        })
    }
    
    func isChannelMember(userId: String, channelId: String, next: @escaping ((Bool) -> Void)) {
        FireController.db.child("channel-members/\(channelId)/\(userId)")
            .observeSingleEvent(of: .value, with: { snap in
                next(!(snap.value is NSNull))
            })
    }
    
    func channelNameExists(groupId: String, channelName: String, next: @escaping ((Bool) -> Void)) {
        FireController.db.child("group-channels/\(groupId)")
            .queryOrdered(byChild: "name")
            .queryEqual(toValue: channelName)
            .observeSingleEvent(of: .value, with: { snap in
            next(!(snap.value is NSNull))
        })
    }
    
    func usernameExists(username: String, next: @escaping ((Bool) -> Void)) {
        FireController.db.child("users")
            .queryOrdered(byChild: "username")
            .queryEqual(toValue: username)
            .observeSingleEvent(of: .value, with: { snap in
            next(!(snap.value is NSNull))
        })
    }
    
    func emailExists(email: String, next: @escaping ((Bool) -> Void)) {
        FireController.db.child("users")
            .queryOrdered(byChild: "email")
            .queryEqual(toValue: email)
            .observeSingleEvent(of: .value, with: { snap in
                next(!(snap.value is NSNull))
        })
    }
    
    func emailProviderExists(email: String, next: @escaping ((Bool) -> Void)) {
        FIRAuth.auth()?.fetchProviders(forEmail: email, completion: { providers, error in
            next(error == nil && providers != nil && providers!.count > 0)
        })
    }
}

/* FIRAuthErrorCode enum
typedef NS_ENUM(NSInteger, FIRAuthErrorCode ) {
    FIRAuthErrorCodeInvalidCustomToken = 17000,
    FIRAuthErrorCodeCustomTokenMismatch = 17002,
    FIRAuthErrorCodeInvalidCredential = 17004,
    FIRAuthErrorCodeUserDisabled = 17005,
    FIRAuthErrorCodeOperationNotAllowed = 17006,
    FIRAuthErrorCodeEmailAlreadyInUse = 17007,
    FIRAuthErrorCodeInvalidEmail = 17008,
    FIRAuthErrorCodeWrongPassword = 17009,
    FIRAuthErrorCodeTooManyRequests = 17010,
    FIRAuthErrorCodeUserNotFound = 17011,
    FIRAuthErrrorCodeAccountExistsWithDifferentCredential = 17012,
    FIRAuthErrorCodeRequiresRecentLogin = 17014,
    FIRAuthErrorCodeProviderAlreadyLinked = 17015,
    FIRAuthErrorCodeNoSuchProvider = 17016,
    FIRAuthErrorCodeInvalidUserToken = 17017,
    FIRAuthErrorCodeNetworkError = 17020,
    FIRAuthErrorCodeUserTokenExpired = 17021,
    FIRAuthErrorCodeInvalidAPIKey = 17023,
    FIRAuthErrorCodeUserMismatch = 17024,
    FIRAuthErrorCodeCredentialAlreadyInUse = 17025,
    FIRAuthErrorCodeWeakPassword = 17026,
    FIRAuthErrorCodeAppNotAuthorized = 17028,
    FIRAuthErrorCodeKeychainError = 17995,
    FIRAuthErrorCodeInternalError = 17999,
} */
