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
    
    func delete(channelId: String, groupId: String) {
        
        let pathChannelMessages = "channel-messages/\(channelId)"
        let pathChannelMembers = "channel-members/\(channelId)"
        let pathGroupChannels = "group-channels/\(groupId)/\(channelId)"
        let updates: [String: Any] = [
            pathGroupChannels: NSNull(),
            pathChannelMessages: NSNull(),
            pathChannelMembers: NSNull()
        ]
        
        /* UNDONE: Need to walk the users that are members of the channel */
        
        FireController.db.child(pathGroupChannels).updateChildValues(updates)
    }

    func delete(messageId: String, channelId: String) {
        
        let pathChannelMessages = "channel-messages/\(channelId)"
        let updates: [String: Any] = [messageId: NSNull()]
        FireController.db.child(pathChannelMessages).updateChildValues(updates)
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
