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
    
    var serverOffset: Int?

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
    
    func delete(channelId: String, groupId: String, then: ((Any?) -> Void)? = nil) {
        
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
                
                FireController.db.updateChildValues(updates) { error, ref in
                    if error == nil {
                        Log.d("Channel deleted: \(channelId)")
                    }
                    then?(error == nil)
                }
            })
        })
    }

    func delete(messageId: String, channelId: String, then: ((Any?) -> Void)? = nil) {
        let pathChannelMessages = "channel-messages/\(channelId)"
        let updates: [String: Any] = [messageId: NSNull()]
        FireController.db.child(pathChannelMessages).updateChildValues(updates) { error, ref in
            then?(error == nil)
        }
    }
    
    func findFirstChannel(groupId: String?, next: ((Any?) -> Void)? = nil) {
        let userId = UserController.instance.userId
        let query = FireController.db.child("member-channels/\(userId!)/\(groupId!)").queryOrdered(byChild: "index_priority_joined_at_desc").queryLimited(toFirst: 1)
        
        query.observeSingleEvent(of: .childAdded, with: { snap in
            if !(snap.value is NSNull) {
                next?(nil)
                return
            }
            next?(snap.key)
        })
    }
    
    func addChannelToGroup(channelId: String, channelMap: [String: Any], groupId: String, then: ((Any?) -> Void)? = nil) {
        
        var updates: [String: Any] = [:]
        updates["group-channels/\(groupId)/\(channelId)"] = channelMap
        
        /* Make all non-guests members of public channels */
        if (channelMap["visibility"] as? String) == "public" {
            FireController.db.child("group-members/\(groupId)").observeSingleEvent(of: .value, with: { snap in
                if !(snap.value is NSNull) {
                    let membersMap = snap.value as! [String: Any]
                    for (memberId, membership) in membersMap {
                        let membershipMap = membership as! [String: Any]
                        if (membershipMap["role"] as? String) != "guest" {
                            
                            let priority = 250
                            let priorityReversed = 210
                            let joinedAt = Int(floor(Double(Utils.now() / 1000)))
                            let index = Int("\(priority)\(joinedAt)")
                            let indexReversed = Int("-\(priorityReversed)\(joinedAt)")

                            updates["channel-members/\(channelId)/\(memberId)"] = true
                            updates["member-channels/\(memberId)/\(groupId)/\(channelId)"] = [
                                "archived": false,
                                "muted": false,
                                "starred": false,
                                "priority": priority,
                                "joined_at": joinedAt,
                                "joined_at_desc": joinedAt * -1,
                                "index_priority_joined_at": index!,
                                "index_priority_joined_at_desc": indexReversed!
                            ]
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
            /* TODO: Still need to auto add the creator as a member for private channels. */
            FireController.db.updateChildValues(updates) { error, ref in
                then?(error == nil)
            }
        }
    }
    
    func addUserToChannel(groupId: String, channelId: String?, then: ((Any?) -> Void)? = nil) {
        
        let userId = UserController.instance.userId
        var updates: [String: Any] = [:]
        
        let priority = 250
        let priorityReversed = 210
        let joinedAt = floor(Double(Utils.now() / 1000))
        let index = Int("\(priority)\(joinedAt)")
        let indexReversed = Int("-\(priorityReversed)\(joinedAt)")
        
        let channelLink: [String: Any] = [
            "archived": false,
            "muted": false,
            "starred": false,
            "priority": priority,
            "joined_at": joinedAt,
            "joined_at_desc": joinedAt * -1,
            "index_priority_joined_at": index!,
            "index_priority_joined_at_desc": indexReversed!
        ]
        
        updates["channel-members/\(channelId)/\(userId!)"] = true
        updates["member-channels/\(userId!)/\(groupId)/\(channelId)"] = channelLink
        
        FireController.db.updateChildValues(updates) { error, ref in
            then?(error == nil)
        }
    }
    
    func addUserToGroup(groupId: String, channelId: String?, guest: Bool, then: ((Any?) -> Void)? = nil) {
        /*
         * Standard member is added to group membership and all default channels.
         * Guest member is added to group and to targeted channel.
         *
         * Guard: Check and pass if user is already a member of the group. What if being
         * re-invited as a member instead of a guest?
         */
        let userId = UserController.instance.userId
        var updates: [String: Any] = [:]
        
        let priority = 250
        let priorityReversed = 210
        let joinedAt = floor(Double(Utils.now() / 1000))
        let index = Int("\(priority)\(joinedAt)")
        let indexReversed = Int("-\(priorityReversed)\(joinedAt)")
        
        let channelLink: [String: Any] = [
            "archived": false,
            "muted": false,
            "starred": false,
            "priority": priority,
            "joined_at": joinedAt,
            "joined_at_desc": joinedAt * -1,
            "index_priority_joined_at": index!,
            "index_priority_joined_at_desc": indexReversed!
        ]
        
        let groupPriority = guest ? 350 : 250
        let groupPriorityReversed = guest ? 150 : 250
        let groupIndex = Int("\(groupPriority)\(joinedAt)")
        let groupIndexReversed = Int("-\(groupPriorityReversed)\(joinedAt)")
        
        let groupLink: [String: Any] = [
            "disabled": false,
            "hide_email": false,
            "notifications": "all",
            "role": guest ? "guest" : "member",
            "priority": groupPriority,
            "joined_at": joinedAt,
            "joined_at_desc": joinedAt * -1,
            "index_priority_joined_at": groupIndex!,
            "index_priority_joined_at_desc": groupIndexReversed!
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
        
        FireController.db.updateChildValues(updates) { error, ref in
            then?(error == nil)
        }
    }
}
