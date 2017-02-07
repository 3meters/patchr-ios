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
    }
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Methods
     *--------------------------------------------------------------------------------------------*/
    
    func sendAdminMessage(channelId: String, groupId: String, userId: String, text: String) {
        
        let ref = FireController.db.child("group-messages/\(groupId)/\(channelId)").childByAutoId()
        let timestamp = getServerTimestamp()
        let timestampReversed = -1 * timestamp
        
        var messageMap: [String: Any] = [:]
        messageMap["created_at"] = Int(timestamp)
        messageMap["created_at_desc"] = Int(timestampReversed)
        messageMap["created_by"] = userId
        messageMap["modified_at"] = Int(timestamp)
        messageMap["modified_by"] = userId
        messageMap["source"] = "system"
        messageMap["group_id"] = groupId
        messageMap["channel_id"] = channelId
        messageMap["text"] = text
        
        ref.setValue(messageMap)
    }
    
    func addUser(userId: String, username: String, email: String, then: ((Bool) -> Void)? = nil) {
        
        var updates: [String: Any] = [:]
        
        let userMap: [String: Any] = [
            "created_at": FIRServerValue.timestamp(),
            "created_by": userId,
            "modified_at": FIRServerValue.timestamp(),
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
        let timestamp = getServerTimestamp()
        var updates: [String: Any] = [:]
        
        /* Add group */
        
        groupMap["created_at"] = Int(timestamp)
        groupMap["created_by"] = userId
        groupMap["modified_at"] = Int(timestamp)
        groupMap["modified_by"] = userId
        groupMap["owned_by"] = userId
        
        /* Add creator as admin member */
        
        let groupPriority = 3   // admin
        let membership = groupMemberMap(userId: userId, timestamp: timestamp, priorityIndex: groupPriority, role: "owner")
        
        updates["member-groups/\(userId)/\(groupId)"] = membership
        updates["group-members/\(groupId)/\(userId)"] = membership
        
        /* Add default channels */
        
        let generalId = "ch-\(Utils.genRandomId())"
        let chatterId = "ch-\(Utils.genRandomId())"
        
        let generalMap: [String: Any] = [
            "archived": false,
            "created_at": Int(timestamp),
            "created_by": userId,
            "general": true,
            "group_id": groupId,
            "name": "general",
            "owned_by": userId,
            "purpose": "This channel is for messaging and announcements to the whole group. All group members are in this channel.",
            "type": "channel",
            "visibility": "open",
        ]
        
        let chatterMap: [String: Any] = [
            "archived": false,
            "created_at": Int(timestamp),
            "created_by": userId,
            "general": false,
            "group_id": groupId,
            "name": "chatter",
            "owned_by": userId,
            "purpose": "The perfect place for crazy talk that you\'d prefer to keep off the other channels.",
            "type": "channel",
            "visibility": "open",
        ]
        
        groupMap["default_channels"] = [generalId, chatterId]
        updates["group-channels/\(groupId)/\(generalId)"] = generalMap
        updates["group-channels/\(groupId)/\(chatterId)"] = chatterMap
        
        updates["groups/\(groupId)"] = groupMap
        
        FireController.db.updateChildValues(updates) { error, ref in
            if error == nil {
                /* Add creator as member of default channels */
                self.addUserToChannel(userId: userId, groupId: groupId, channelId: generalId, channelName: generalMap["name"] as! String?)
                self.addUserToChannel(userId: userId, groupId: groupId, channelId: chatterId, channelName: chatterMap["name"] as! String?)
            }
            then?(error == nil)
        }
    }
    
    func addChannelToGroup(channelId: String, channelMap: [String: Any], groupId: String, then: ((Bool) -> Void)? = nil) {
        
        let userId = UserController.instance.userId!
        let channelName = channelMap["name"] as! String
        let visibility = channelMap["visibility"] as! String
        var updates: [String: Any] = [:]
        updates["group-channels/\(groupId)/\(channelId)"] = channelMap
        
        FireController.db.updateChildValues(updates) { error, ref in
            if error == nil {
                /* Add creator as first member of channel */
                self.addUserToChannel(userId: userId, groupId: groupId, channelId: channelId, channelName: channelName, role: "owner")
                if visibility == "open",
                    let generalId = StateController.instance.groupGeneralId {
                    let text = "created the #\(channelName) channel."
                    self.sendAdminMessage(channelId: generalId, groupId: groupId, userId: userId, text: text)
                }
            }
            then?(error == nil)
        }
    }
    
    func addUserToChannel(userId: String, groupId: String, channelId: String, channelName: String?, role: String! = "member",
                          invite: [String: Any]? = nil, inviterName: String? = nil, adminId: String? = nil,
                          then: ((Bool) -> Void)? = nil) {
        
        var updates: [String: Any] = [:]
        let timestamp = getServerTimestamp()
        var membership = channelMemberMap(userId: userId, timestamp: timestamp, priorityIndex: 4, role: role /* neutral */)
        
        var inviterName: String!
        if invite != nil {
            let inviteId = invite!["id"] as! String
            let inviter = invite!["inviter"] as! [String: Any]
            let inviterId = inviter["id"] as! String
            inviterName = inviter["username"] as! String?
            membership["invite_id"] = inviteId
            membership["invited_by"] = inviterId
        }
        
        updates["group-channel-members/\(groupId)/\(channelId)/\(userId)"] = membership
        updates["member-channels/\(userId)/\(groupId)/\(channelId)"] = membership   // Security checks channel membership
        
        FireController.db.updateChildValues(updates) { error, ref in
            if error == nil {
                var text = channelName != nil ? "joined #\(channelName!)." : "joined."
                if invite != nil {
                    text = channelName != nil ? "joined #\(channelName!) by invitation from @\(inviterName!)." : "joined by invitation from @\(inviterName!)."
                }
                let adminId = adminId ?? userId
                self.sendAdminMessage(channelId: channelId, groupId: groupId, userId: adminId, text: text)
            }
            then?(error == nil)
        }
    }
    
    func addUserToChannels(userId: String, groupId: String, channels: [String: Any],
                           invite: [String: Any]? = nil, inviterName: String? = nil,
                           then: ((Bool) -> Void)? = nil) {
        
        for channelId in channels.keys {
            let channelName = channels[channelId] as! String
            addUserToChannel(userId: userId, groupId: groupId, channelId: channelId, channelName: channelName,
                             invite: invite, inviterName: inviterName)
        }
        then?(true)
    }

    func addUserToGroup(userId: String, groupId: String, channels: [String: Any]?, role: String,
                        invite: [String: Any]? = nil, email: String, then: ((Bool) -> Void)? = nil) {
        /*
         * Standard member is added to group membership and all default channels.
         * Guest member is added to group and to targeted channel.
         */
        var updates: [String: Any] = [:]
        let timestamp = getServerTimestamp()
        
        if channels != nil {
            for channelId in channels!.keys {
                let channelName = channels![channelId] as! String
                addUserToChannel(userId: userId, groupId: groupId, channelId: channelId, channelName: channelName, invite: invite)
            }
        }
        
        let groupPriority = (role == "guest") ? 5 : 4
        var membership = groupMemberMap(userId: userId, timestamp: timestamp, priorityIndex: groupPriority, role: role)
        
        if invite != nil {
            
            let inviteId = invite!["id"] as! String
            let inviter = invite!["inviter"] as! [String: Any]
            let inviterId = inviter["id"] as! String
            membership["invite_id"] = inviteId
            membership["invited_by"] = inviterId
            
            updates["member-groups/\(userId)/\(groupId)"] = membership
            updates["group-members/\(groupId)/\(userId)"] = membership
            
            FireController.db.child("invites/\(groupId)/\(inviterId)/\(inviteId)")
                .observeSingleEvent(of: .value, with: { snap in
                    if !(snap.value is NSNull) {
                        if let mapInvite = snap.value as? [String: Any] {
                            let inviteId = mapInvite.first!.key
                            FireController.db.child("invites/\(groupId)/\(inviteId)/accepted_at").setValue(Int(timestamp))
                            FireController.db.child("invites/\(groupId)/\(inviteId)/accepted_by").setValue(userId)
                            FireController.db.child("invites/\(groupId)/\(inviteId)/status").setValue("accepted")
                        }
                    }
                    if role != "guest" {
                        let pathDefaults = "groups/\(groupId)/default_channels"
                        FireController.db.child(pathDefaults).observeSingleEvent(of: .value, with: { snap in
                            if let channelIds = snap.value as? [String] {
                                for channelId in channelIds {
                                    FireController.instance.addUserToChannel(userId: userId, groupId: groupId, channelId: channelId, channelName: nil)
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
        else {
            updates["member-groups/\(userId)/\(groupId)"] = membership
            updates["group-members/\(groupId)/\(userId)"] = membership
            
            if role != "guest" {
                let pathDefaults = "groups/\(groupId)/default_channels"
                FireController.db.child(pathDefaults).observeSingleEvent(of: .value, with: { snap in
                    if let channelIds = snap.value as? [String] {
                        for channelId in channelIds {
                            FireController.instance.addUserToChannel(userId: userId, groupId: groupId, channelId: channelId, channelName: nil)
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
        }
    }
    
    func removeUserFromGroup(userId: String, groupId: String, then: ((Bool) -> Void)? = nil) {
        /*
         * - remove from member-groups and group-members
         * - remove from all channel indexes
         */
        var updates: [String: Any] = [:]
        
        updates["member-groups/\(userId)/\(groupId)"] = NSNull()
        updates["group-members/\(groupId)/\(userId)"] = NSNull()
        
        FireController.db.updateChildValues(updates) { error, ref in
            if error == nil {
                FireController.db.child("member-channels/\(userId)/\(groupId)")
                    .observeSingleEvent(of: .value, with: { snap in
                    
                        if !(snap.value is NSNull) && snap.hasChildren() {
                            for channelSnap in snap.children  {
                                let channelFoo = channelSnap as! FIRDataSnapshot
                                let channelId = channelFoo.key
                                self.removeUserFromChannel(userId: userId, groupId: groupId, channelId: channelId, channelName: nil)
                            }
                        }
                        
                        var task: [String: Any] = [:]
                        task["target"] = "group"
                        task["group_id"] = groupId
                        let queueRef = FireController.db.child("queue/clear-unreads").childByAutoId()
                        queueRef.setValue(task)
                        
                        then?(error == nil)
                })
            }
            else {
                then?(error == nil)
            }
        }
    }

    func removeUserFromChannel(userId: String, groupId: String, channelId: String, channelName: String?, then: ((Bool) -> Void)? = nil) {
        var updates: [String: Any] = [:]
        updates["member-channels/\(userId)/\(groupId)/\(channelId)"] = NSNull()
        updates["group-channel-members/\(groupId)/\(channelId)/\(userId)"] = NSNull()
        FireController.db.updateChildValues(updates) { error, ref in
            if error == nil {
                var task: [String: Any] = [:]
                task["target"] = "channel"
                task["group_id"] = groupId
                task["channel_id"] = channelId
                let queueRef = FireController.db.child("queue/clear-unreads").childByAutoId()
                queueRef.setValue(task)
                
                let text = channelName != nil ? "left #\(channelName!)." : "left."
                self.sendAdminMessage(channelId: channelId, groupId: groupId, userId: userId, text: text)
            }
            then?(error == nil)
        }
    }

    func channelMemberMap(userId: String, timestamp: Int64, priorityIndex: Int, role: String) -> [String: Any] {
        
        let priority = self.priorities[priorityIndex]
        let priorityReversed = self.priorities.reversed()[priorityIndex]
        let joinedAt = Int(floorf(Float(timestamp / 1000))) // shorten to 10 digits
        let index = Int("\(priority)\(joinedAt)")
        let indexReversed = Int("-\(priorityReversed)\(joinedAt)")
        
        let link: [String: Any] = [
            "archived": false,
            "created_at": Int(timestamp),
            "created_by": userId,
            "joined_at": joinedAt,  // Not a real unix epoch timestamp, only 10 digits instead of 13
            "joined_at_desc": joinedAt * -1,
            "index_priority_joined_at": index!,
            "index_priority_joined_at_desc": indexReversed!,
            "muted": false,
            "priority": priority,
            "role": role,
            "starred": false,
        ]
        
        return link
    }
    
    func groupMemberMap(userId: String, timestamp: Int64, priorityIndex: Int, role: String) -> [String: Any] {
        
        let priority = self.priorities[priorityIndex]
        let priorityReversed = self.priorities.reversed()[priorityIndex]
        let joinedAt = Int(floorf(Float(timestamp / 1000)))// shorten to 10 digits
        let index = Int("\(priority)\(joinedAt)")
        let indexReversed = Int("-\(priorityReversed)\(joinedAt)")
        
        let link: [String: Any] = [
            "created_at": Int(timestamp),
            "created_by": userId,
            "disabled": false,
            "hide_email": false,
            "joined_at": joinedAt, // Not a real unix epoch timestamp, only 10 digits instead of 13
            "joined_at_desc": joinedAt * -1,
            "index_priority_joined_at": index!,
            "index_priority_joined_at_desc": indexReversed!,
            "notifications": "all",
            "priority": priority,
            "role": role,
        ]
        
        return link
    }
    
    func deleteGroup(groupId: String, then: (([String: Any]?) -> Void)? = nil) {
        let userId = UserController.instance.userId!
        let task = [
            "target": "group",
            "group_id": groupId,
            "user_id": userId
        ]
        let ref = FireController.db.child("queue/deletes").childByAutoId()
        ref.setValue(task) { error, ref in
            then?([:])
        }
    }
    
    func deleteChannel(channelId: String, groupId: String, then: (([String: Any]?) -> Void)? = nil) {
        let userId = UserController.instance.userId!
        let task = [
            "target": "channel",
            "group_id": groupId,
            "channel_id": channelId,
            "user_id": userId
        ]
        let ref = FireController.db.child("queue/deletes").childByAutoId()
        ref.setValue(task) { error, ref in
            then?([:])
        }
    }
    
    func deleteMessage(messageId: String, channelId: String, groupId: String, then: (([String: Any]?) -> Void)? = nil) {
        
        let path = "group-messages/\(groupId)/\(channelId)"
        let updates: [String: Any] = [messageId: NSNull()]
        
        FireController.db.child(path).updateChildValues(updates) { error, ref in
            if error == nil {
                Log.d("Message deleted: \(messageId)")
                
                var task: [String: Any] = [:]
                task["target"] = "message"
                task["group_id"] = groupId
                task["channel_id"] = channelId
                task["message_id"] = messageId
                let queueRef = FireController.db.child("queue/clear-unreads").childByAutoId()
                queueRef.setValue(task)
                
                then?(updates)
                return
            }            
            then?(nil)
        }
    }
    
    func deleteInvite(groupId: String, inviterId: String, inviteId: String) {
        FireController.db.child("invites/\(groupId)/\(inviterId)/\(inviteId)").removeValue()
    }
    
    func clearChannelUnreads(channelId: String, groupId: String) {
        let userId = UserController.instance.userId!
        let unreadPath = "unreads/\(userId)/\(groupId)/\(channelId)"
        FireController.db.child(unreadPath).removeValue()
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
    
    func autoPickGroupAndChannel(userId: String, next: ((String?, String?) -> Void)? = nil) {
        self.findFirstGroup(userId: userId) { groupId in
            if groupId == nil { next?(nil, nil) }
            if let settings = UserDefaults.standard.dictionary(forKey: groupId!),
                let lastChannelId = settings["currentChannelId"] as? String {
                let validateQuery = ChannelQuery(groupId: groupId!, channelId: lastChannelId, userId: userId)
                validateQuery.once(with: { channel in
                    if channel == nil {
                        Log.w("Last channel invalid: \(lastChannelId): trying first channel")
                        FireController.instance.findFirstChannel(groupId: groupId!) { channelId in
                            if channelId != nil {
                                next?(groupId, channelId)
                            }
                        }
                    }
                    else {
                        next?(groupId, lastChannelId)
                    }
                })
            }
            else {
                FireController.instance.findFirstChannel(groupId: groupId!) { channelId in
                    if channelId != nil {
                        next?(groupId, channelId)
                    }
                    else {
                        FireController.instance.findGeneralChannel(groupId: groupId!) { channelId in
                            next?(groupId, channelId)
                        }
                    }
                }
            }
        }
    }

    func channelRoleCount(groupId: String, channelId: String, role: String, then: @escaping ((Int?) -> Void)) {
        FireController.db.child("group-channel-members/\(groupId)/\(channelId)")
            .observeSingleEvent(of: .value, with: { snap in
                if let members = snap.value as? [String: Any] {
                    var roleCount = 0
                    for value in members.values {
                        let member = value as! [String: Any]
                        if let memberRole = member["role"] as? String {
                            if memberRole == role {
                                roleCount += 1
                            }
                        }
                    }
                    then(roleCount)
                }
                else {
                    then(nil)
                }
        })
    }
    
    func isChannelMember(userId: String, channelId: String, groupId: String, next: @escaping ((Bool) -> Void)) {
        FireController.db.child("group-channel-members/\(groupId)/\(channelId)/\(userId)")
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
        /* 
         * Currently unused
         * Can't access users unless authenticated which we might not
         * be if user is logging in.
         */
        FireController.db.child("users")
            .queryOrdered(byChild: "email")
            .queryEqual(toValue: email)
            .observeSingleEvent(of: .value, with: { snap in
                next(!(snap.value is NSNull))
        })
    }
    
    func emailProviderExists(email: String, next: @escaping ((Bool?) -> Void)) {
        /*
         * Can be accessed even if user is not authenticated.
         */
        if FIRAuth.auth() != nil {
            FIRAuth.auth()!.fetchProviders(forEmail: email, completion: { providers, error in
                next(error == nil && providers != nil && providers!.count > 0)
            })
        }
        else {
            next(nil)
        }
    }
    
    func getServerTimestamp() -> Int64 {
        return (Utils.now() + (FireController.instance.serverOffset ?? 0))
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
