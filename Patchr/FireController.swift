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
    let testToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE0ODY3NTQzNjUsImRlYnVnIjp0cnVlLCJ2IjowLCJkIjp7InVpZCI6InVzLW01ZDZrdzZvMyJ9LCJpYXQiOjE0ODY3NTA3NjV9.jA4i3_FpDfym-jwxVUtJNwW-ILMgLhwGqp7R_MLlcIg"

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
    
    func sendAdminMessage(channelId: String, groupId: String, userId: String, text: String, then: ((Bool) -> Void)? = nil) {
        
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
        
        ref.setValue(messageMap) { error, ref in
            then?(error == nil)
        }
    }
    
    func addUser(userId: String, username: String, email: String, then: ((Bool) -> Void)? = nil) {
        let userMap: [String: Any] = [
            "created_at": FIRServerValue.timestamp(),
            "created_by": userId,
            "modified_at": FIRServerValue.timestamp(),
            "username": username,
            "email": email
        ]
        FireController.db.child("users/\(userId)").setValue(userMap) { error, ref in
            then?(error == nil)
        }
    }
    
    func addGroup(groupId: String, title: String, then: ((Bool) -> Void)? = nil) {
        
        let userId = UserController.instance.userId!
        let timestamp = getServerTimestamp()
        let groupPriority = 3   // owner
        let membership = self.groupMemberMap(userId: userId, timestamp: timestamp, priorityIndex: groupPriority, role: "owner")
        
        let generalId = "ch-\(Utils.genRandomId())"
        let generalName = "general"
        let chatterId = "ch-\(Utils.genRandomId())"
        let chatterName = "chatter"
        
        let queue = TaskQueue()
        
        /* Add group */
        queue.tasks += { _, next in
            var groupMap = [String: Any]()
            groupMap["title"] = title
            groupMap["created_at"] = Int(timestamp)
            groupMap["created_by"] = userId
            groupMap["modified_at"] = Int(timestamp)
            groupMap["modified_by"] = userId
            groupMap["owned_by"] = userId
            groupMap["default_channels"] = [generalId, chatterId]
            FireController.db.child("groups/\(groupId)").setValue(groupMap) { error, ref in
                if error != nil {
                    queue.cancel()
                    then?(false)
                }
                next(nil)
            }
        }
        
        /* Add creator as member of group with owner role */
        queue.tasks += { _, next in
            FireController.db.child("group-members/\(groupId)/\(userId)").setValue(membership) { error, ref in
                if error != nil {
                    queue.cancel()
                    then?(false)
                }
                next(nil)
            }
        }
        
        /* Add creator as member of group with owner role */
        queue.tasks += { _, next in
            FireController.db.child("member-groups/\(userId)/\(groupId)").setValue(membership) { error, ref in
                if error != nil {
                    queue.cancel()
                    then?(false)
                }
                next(nil)
            }
        }
        
        /* Add default general channel */
        queue.tasks += { _, next in
            
            let generalMap: [String: Any] = [
                "archived": false,
                "created_at": Int(timestamp),
                "created_by": userId,
                "general": true,
                "group_id": groupId,
                "name": generalName,
                "owned_by": userId,
                "purpose": "This channel is for messaging and announcements to the whole group. All group members are in this channel.",
                "type": "channel",
                "visibility": "open"]
            
            self.addChannelToGroup(channelId: generalId, channelMap: generalMap, groupId: groupId) { success in
                if !success {
                    queue.cancel()
                    then?(false)
                }
                next(nil)
            }
        }
        
        /* Add default chatter channel */
        queue.tasks += { _, next in
            
            let chatterMap: [String: Any] = [
                "archived": false,
                "created_at": Int(timestamp),
                "created_by": userId,
                "general": false,
                "group_id": groupId,
                "name": chatterName,
                "owned_by": userId,
                "purpose": "The perfect place for crazy talk that you\'d prefer to keep off the other channels.",
                "type": "channel",
                "visibility": "open"]
            
            self.addChannelToGroup(channelId: chatterId, channelMap: chatterMap, groupId: groupId) { success in
                if !success {
                    queue.cancel()
                    then?(false)
                }
                next(nil)
            }
        }
        
        queue.run() {
            then?(true)
        }
    }
    
    func addChannelToGroup(channelId: String, channelMap: [String: Any], groupId: String, then: ((Bool) -> Void)? = nil) {
        
        let userId = UserController.instance.userId!
        let channelName = channelMap["name"] as! String
        let visibility = channelMap["visibility"] as! String
        
        FireController.db.child("group-channels/\(groupId)/\(channelId)").setValue(channelMap) { error, ref in
            if error == nil {
                /* Add creator as first member of channel (open or private) */
                self.addUserToChannel(userId: userId, groupId: groupId, channelId: channelId, channelName: channelName, role: "owner") { success in
                    if visibility == "open", let generalId = StateController.instance.groupGeneralId {
                        let text = "created the #\(channelName) channel."
                        self.sendAdminMessage(channelId: generalId, groupId: groupId, userId: userId, text: text)
                    }
                    then?(success)
                }
                return
            }
            then?(false)
        }
    }
    
    func addUserToChannel(userId: String, groupId: String, channelId: String, channelName: String?, role: String! = "member",
                          invite: [String: Any]? = nil, inviterName: String? = nil, adminId: String? = nil,
                          then: ((Bool) -> Void)? = nil) {
        
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

        let queue = TaskQueue()
        
        /* Add creator as member of group with owner role */
        queue.tasks += { _, next in
            FireController.db.child("group-channel-members/\(groupId)/\(channelId)/\(userId)").setValue(membership) { error, ref in
                if error != nil {
                    queue.cancel()
                    then?(false)
                }
                next(nil)
            }
        }
        
        /* Add creator as member of group with owner role */
        queue.tasks += { _, next in
            FireController.db.child("member-channels/\(userId)/\(groupId)/\(channelId)").setValue(membership) { error, ref in
                if error != nil {
                    queue.cancel()
                    then?(false)
                }
                next(nil)
            }
        }
        
        queue.tasks += { _, next in
            var text = channelName != nil ? "joined #\(channelName!)." : "joined."
            if invite != nil {
                text = channelName != nil ? "joined #\(channelName!) by invitation from @\(inviterName!)." : "joined by invitation from @\(inviterName!)."
            }
            let adminId = adminId ?? userId
            self.sendAdminMessage(channelId: channelId, groupId: groupId, userId: adminId, text: text) { success in
                if !success {
                    queue.cancel()
                    then?(false)
                }
                next(nil)
            }
        }

        queue.run() {
            then?(true)
        }
    }
    
    func addUserToChannels(userId: String, groupId: String, channels: [String: Any],
                           invite: [String: Any]? = nil, inviterName: String? = nil,
                           then: ((Bool) -> Void)? = nil) {
        /* Fires and doesn't wait to check success for each channel */
        let dispGroup = DispatchGroup()
        for channelId in channels.keys {
            dispGroup.enter()
            let channelName = channels[channelId] as! String
            addUserToChannel(userId: userId, groupId: groupId, channelId: channelId, channelName: channelName,
                             invite: invite, inviterName: inviterName) { success in
                dispGroup.leave()
            }
        }
        dispGroup.notify(queue: DispatchQueue.main) {
            then?(true)
        }
    }
    
    func addUserToGroupTask(groupId: String, channels: [String: Any]?, role: String,
                            inviteId: String?, invitedBy: String?, then: @escaping ([String: Any]?, Any?) -> Void) {
        let userId = UserController.instance.userId!
        let timestamp = getServerTimestamp()
        let ref = FireController.db.child("queue/join-group").childByAutoId()
        var task: [String: Any] = [
            "created_at": Int(timestamp),
            "created_by": userId,
            "user_id": userId,
            "group_id": groupId,
            "id": ref.key,
            "retain": true,
            "role": role,
            "state": "waiting"
        ]
        if inviteId != nil {
            task["invite_id"] = inviteId
            task["invited_by"] = invitedBy
        }
        if channels != nil {
            task["channels"] = channels
        }
        
        var handle: UInt = 0
        ref.setValue(task) { error, ref in
            if error == nil {
                handle = ref.observe(.value, with: { snap in
                    if let task = snap.value as? [String: Any], let state = task["state"] as? String {
                        Log.d("Task state: \(state)")
                        let error = task["error"] as? [String: Any]
                        let result = task["result"] as Any?
                        if error != nil || result != nil {
                            FireController.db.removeObserver(withHandle: handle)
                            ref.removeValue()
                            if error != nil {
                                let code = error!["code"] as! Int
                                let message = error!["message"] as! String
                                Log.d("Error code: \(code): \(message)")
                            }
                            then(error, result)
                        }
                    }
                })
                return
            }
            then([:], nil)  // permission denied
        }
    }

    func addUserToGroup(groupId: String, channels: [String: Any]?, role: String,
                        invite: [String: Any]? = nil, email: String, then: ((Bool) -> Void)? = nil) {
        /*
         * Standard member is added to group membership and all default channels.
         * Guest member is added to group and to targeted channel.
         */
        let userId = UserController.instance.userId!
        let timestamp = getServerTimestamp()
        let groupPriority = (role == "guest") ? 5 : 4
        var membership = groupMemberMap(userId: userId, timestamp: timestamp, priorityIndex: groupPriority, role: role)
        
        if invite != nil {
            let inviteId = invite!["id"] as! String
            let inviter = invite!["inviter"] as! [String: Any]
            let inviterId = inviter["id"] as! String
            membership["invite_id"] = inviteId
            membership["invited_by"] = inviterId
        }
        
        let queue = TaskQueue()
        
        /* Add user as member of group */
        queue.tasks += { _, next in
            FireController.db.child("group-members/\(groupId)/\(userId)").setValue(membership) { error, ref in
                if error != nil {
                    queue.cancel()
                    then?(false)
                }
                next(nil)
            }
        }
        
        queue.tasks += { _, next in
            FireController.db.child("member-groups/\(userId)/\(groupId)").setValue(membership) { error, ref in
                if error != nil {
                    queue.cancel()
                    then?(false)
                }
                next(nil)
            }
        }
        
        /* Add to channels if provided */
        queue.tasks += { _, next in
            if channels != nil {
                let dispGroup = DispatchGroup()
                for channelId in channels!.keys {
                    dispGroup.enter()
                    let channelName = channels![channelId] as! String
                    self.addUserToChannel(userId: userId, groupId: groupId, channelId: channelId, channelName: channelName, invite: invite) { success in
                        dispGroup.leave()
                    }
                }
                dispGroup.notify(queue: DispatchQueue.main) {
                    next(nil)
                }
            }
            else {
                next(nil)
            }
        }
        
        /* Add to default channels if not guest */
        queue.tasks += { _, next in
            if role != "guest" {
                let path = "groups/\(groupId)/default_channels"
                FireController.db.child(path).observeSingleEvent(of: .value, with: { snap in
                    if let channelIds = snap.value as? [String] {
                        let dispGroup = DispatchGroup()
                        for channelId in channelIds {
                            dispGroup.enter()
                            self.addUserToChannel(userId: userId, groupId: groupId, channelId: channelId, channelName: nil) { success in
                                dispGroup.leave()
                            }
                        }
                        dispGroup.notify(queue: DispatchQueue.main) {
                            next(nil)
                        }
                    }
                    else {
                        next(nil)
                    }
                }, withCancel: { error in
                    queue.cancel()
                    then?(false)
                    next(nil)
                })
            }
            else {
                next(nil)
            }
        }
        
        /* Process invite */
        queue.tasks += { _, next in
            if invite != nil {
                let inviteId = invite!["id"] as! String
                let inviter = invite!["inviter"] as! [String: Any]
                let inviterId = inviter["id"] as! String
                
                FireController.db.child("invites/\(groupId)/\(inviterId)/\(inviteId)")
                    .observeSingleEvent(of: .value, with: { snap in
                        if let _ = snap.value as? [String: Any] {
                            FireController.db.child("invites/\(groupId)/\(inviterId)/\(inviteId)/accepted_at").setValue(Int(timestamp))
                            FireController.db.child("invites/\(groupId)/\(inviterId)/\(inviteId)/accepted_by").setValue(userId)
                            FireController.db.child("invites/\(groupId)/\(inviterId)/\(inviteId)/status").setValue("accepted")
                        }
                        next(nil)
                    }, withCancel: { error in
                        queue.cancel()
                        then?(false)
                        next(nil)
                    })
            }
            else {
                next(nil)
            }
        }
        
        queue.run() {
            then?(true)
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
                        
                        let ref = FireController.db.child("queue/clear-unreads").childByAutoId()
                        let timestamp = FireController.instance.getServerTimestamp()
                        
                        var task: [String: Any] = [:]
                        task["created_at"] = Int(timestamp)
                        task["created_by"] = userId
                        task["group_id"] = groupId
                        task["id"] = ref.key
                        task["state"] = "waiting"
                        task["target"] = "group"
                        ref.setValue(task)
                        
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
                let ref = FireController.db.child("queue/clear-unreads").childByAutoId()
                let timestamp = FireController.instance.getServerTimestamp()
                
                var task: [String: Any] = [:]
                task["channel_id"] = channelId
                task["created_at"] = Int(timestamp)
                task["created_by"] = userId
                task["group_id"] = groupId
                task["id"] = ref.key
                task["state"] = "waiting"
                task["target"] = "channel"
                
                ref.setValue(task)
                
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
        let ref = FireController.db.child("queue/deletes").childByAutoId()
        let timestamp = getServerTimestamp()
        let task: [String: Any] = [
            "created_at": Int(timestamp),
            "created_by": userId,
            "target": "group",
            "group_id": groupId,
            "id": ref.key,
            "state": "waiting"
        ]
        ref.setValue(task) { error, ref in
            then?([:])
        }
    }
    
    func deleteChannel(channelId: String, groupId: String, then: (([String: Any]?) -> Void)? = nil) {
        let userId = UserController.instance.userId!
        let ref = FireController.db.child("queue/deletes").childByAutoId()
        let timestamp = getServerTimestamp()
        let task: [String: Any] = [
            "channel_id": channelId,
            "created_at": Int(timestamp),
            "created_by": userId,
            "target": "channel",
            "group_id": groupId,
            "id": ref.key,
            "state": "waiting"
        ]
        ref.setValue(task) { error, ref in
            then?([:])
        }
    }
    
    func deleteMessage(messageId: String, channelId: String, groupId: String, then: ((Bool) -> Void)? = nil) {
        
        let path = "group-messages/\(groupId)/\(channelId)/\(messageId)"
        FireController.db.child(path).setValue(NSNull()) { error, ref in
            if error == nil {
                Log.d("Message deleted: \(messageId)")
                let userId = UserController.instance.userId!
                let ref = FireController.db.child("queue/clear-unreads").childByAutoId()
                let timestamp = FireController.instance.getServerTimestamp()
                
                var task: [String: Any] = [:]
                task["channel_id"] = channelId
                task["created_at"] = Int(timestamp)
                task["created_by"] = userId
                task["group_id"] = groupId
                task["id"] = ref.key
                task["message_id"] = messageId
                task["state"] = "waiting"
                task["target"] = "message"
                ref.setValue(task)
                
                then?(true)
                return
            }            
            then?(false)
        }
    }
    
    func deleteInvite(groupId: String, inviterId: String, inviteId: String) {
        FireController.db.child("invites/\(groupId)/\(inviterId)/\(inviteId)").removeValue()
    }
    
    func clearChannelUnreads(channelId: String, groupId: String) {
        let userId = UserController.instance.userId!
        let unreadPath = "unreads/\(userId)/\(groupId)/\(channelId)"
        FireController.db.child(unreadPath).setValue(NSNull()) { err, ref in
            if err != nil {
                Log.d("No unreads to clear for current channel")
            }
        }
    }
    
    func clearMessageUnread(messageId: String, channelId: String, groupId: String) {
        let userId = UserController.instance.userId!
        let unreadPath = "unreads/\(userId)/\(groupId)/\(channelId)/\(messageId)"
        FireController.db.child(unreadPath).setValue(NSNull()) { err, ref in
            if err != nil {
                Log.d("No unread to clear for message")
            }
        }
    }
    
    func findFirstChannel(groupId: String, next: @escaping (String?) -> Void) {
        let userId = UserController.instance.userId!
        let path = "member-channels/\(userId)/\(groupId)"
        let query = FireController.db.child(path).queryOrdered(byChild: "index_priority_joined_at_desc").queryLimited(toFirst: 1)
        
        query.observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) && snap.hasChildren() {
                let channelId = (snap.children.nextObject() as! FIRDataSnapshot).key
                next(channelId)
                return
            }
            next(nil)
        }, withCancel: { error in
            Log.w("Permission denied trying to find first channel: \(path)")
            next(nil)
        })
    }
    
    func findGeneralChannel(groupId: String, next: @escaping (String?) -> Void) {
        let path = "group-channels/\(groupId)"
        let query = FireController.db.child(path).queryOrdered(byChild: "general").queryEqual(toValue: true)
        
        query.observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) && snap.hasChildren() {
                let channelId = (snap.children.nextObject() as! FIRDataSnapshot).key
                next(channelId)
                return
            }
            next(nil)
        }, withCancel: { error in
            next(nil)
        })
    }
    
    func findFirstGroup(userId: String, next: @escaping (String?) -> Void) {
        let query = FireController.db.child("member-groups/\(userId)")
            .queryOrdered(byChild: "index_priority_joined_at_desc")
            .queryLimited(toFirst: 1)
        
        query.observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                next(snap.key)
                return
            }
            next(nil)
        })
    }
    
    func autoPickGroupAndChannel(userId: String, next: @escaping (String?, String?) -> Void) {
        self.findFirstGroup(userId: userId) { groupId in
            if groupId == nil { next(nil, nil) }
            if let settings = UserDefaults.standard.dictionary(forKey: groupId!),
                let lastChannelId = settings["currentChannelId"] as? String {
                let validateQuery = ChannelQuery(groupId: groupId!, channelId: lastChannelId, userId: userId)
                validateQuery.once(with: { error, channel in
                    if channel == nil {
                        Log.w("Last channel invalid: \(lastChannelId): trying first channel")
                        FireController.instance.findFirstChannel(groupId: groupId!) { channelId in
                            if channelId != nil {
                                next(groupId, channelId)
                            }
                        }
                    }
                    else {
                        next(groupId, lastChannelId)
                    }
                })
            }
            else {
                FireController.instance.findFirstChannel(groupId: groupId!) { channelId in
                    if channelId != nil {
                        next(groupId, channelId)
                    }
                    else {
                        FireController.instance.findGeneralChannel(groupId: groupId!) { channelId in
                            next(groupId, channelId)
                        }
                    }
                }
            }
        }
    }

    func channelRoleCount(groupId: String, channelId: String, role: String, then: @escaping ((Int?) -> Void)) {
        let path = "group-channel-members/\(groupId)/\(channelId)"
        FireController.db.child(path)
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
            }, withCancel: { error in
                Log.w("Permission denied: \(path)")
                then(nil)
            })
    }
    
    func isChannelMember(userId: String, channelId: String, groupId: String, next: @escaping ((Bool?) -> Void)) {
        let path = "group-channel-members/\(groupId)/\(channelId)/\(userId)"
        FireController.db.child(path)
            .observeSingleEvent(of: .value, with: { snap in
                next(!(snap.value is NSNull))
            }, withCancel: { error in
                Log.w("Permission denied: \(path)")
                next(nil)
            })
    }
    
    func channelNameExists(groupId: String, channelName: String, next: @escaping ((Bool?) -> Void)) {
        let path = "group-channels/\(groupId)"
        FireController.db.child(path)
            .queryOrdered(byChild: "name")
            .queryEqual(toValue: channelName)
            .observeSingleEvent(of: .value, with: { snap in
                next(!(snap.value is NSNull))
            }, withCancel: { error in
                Log.w("Permission denied: \(path)")
                next(nil)
            })
    }
    
    func channelNameExistsTask(groupId: String, channelName: String, then: @escaping (([String: Any]?, Any?) -> Void)) {
        let userId = UserController.instance.userId!
        let timestamp = getServerTimestamp()
        let ref = FireController.db.child("queue/channel-name-exists").childByAutoId()
        let task: [String: Any] = [
            "channelName": channelName,
            "created_at": Int(timestamp),
            "created_by": userId,
            "group_id": groupId,
            "id": ref.key,
            "retain": true,
            "state": "waiting"
        ]
        
        var handle: UInt = 0
        ref.setValue(task) { error, ref in
            if error == nil {
                handle = ref.observe(.value, with: { snap in
                    if let task = snap.value as? [String: Any], let state = task["state"] as? String {
                        Log.d("Task state: \(state)")
                        let error = task["error"] as? [String: Any]
                        let result = task["result"] as Any?
                        if error != nil || result != nil {
                            FireController.db.removeObserver(withHandle: handle)
                            ref.removeValue()
                            if error != nil {
                                let code = error!["code"] as! Int
                                let message = error!["message"] as! String
                                Log.d("Error code: \(code): \(message)")
                            }
                            then(error, result)
                        }
                    }
                })
                return
            }
            then([:], nil)  // permission denied
        }
    }
    
    func usernameExists(username: String, next: @escaping ((Bool?) -> Void)) {
        FireController.db.child("users")
            .queryOrdered(byChild: "username")
            .queryEqual(toValue: username)
            .observeSingleEvent(of: .value, with: { snap in
                next(!(snap.value is NSNull))
            }, withCancel: { error in
                Log.w("Permission denied: users")
                next(nil)
            })
    }
    
    func emailExists(email: String, next: @escaping ((Bool?) -> Void)) {
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
            }, withCancel: { error in
                next(nil)
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
    
    func isConnected(then: @escaping ((Bool?) -> Void)) {
        FireController.db.child(".info/connected").observeSingleEvent(of: .value, with: { snap in
            if let connected = snap.value as? Bool {
                then(connected)
                return
            }
            then(nil)
        }, withCancel: { error in
            then(nil)
        })
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
