/*
 * Firebase controller
 *
 * Provide convenience functionality when interacting with the Firebase database.
 */
import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth
import FirebaseDatabaseUI

class FireController: NSObject {

    static let instance = FireController()
    
    class var db: DatabaseReference {
        return Database.database().reference()
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
     * MARK: - Create
     *--------------------------------------------------------------------------------------------*/
    
    func addUser(userId: String, username: String, then: @escaping ((ServiceError?, Any?) -> Void)) {
        let timestamp = getServerTimestamp()
        let ref = FireController.db.child("tasks/create-user").childByAutoId()
        let request: [String: Any] = [
            "user_id": userId,
            "username": username,
        ]
        let task: [String: Any] = [
            "created_at": timestamp,
            "created_by": userId,
            "request": request,
        ]
        submitTask(task: task, ref: ref, then: then) // Error used, result ignored
    }
    
    func addGroup(groupId: String, title: String, then: ((Bool) -> Void)? = nil) {
        let userId = UserController.instance.userId!
        let timestamp = getServerTimestamp()
        var groupMap = [String: Any]()
        groupMap["title"] = title
        groupMap["created_at"] = timestamp
        groupMap["created_by"] = userId
        groupMap["modified_at"] = timestamp
        groupMap["modified_by"] = userId
        groupMap["owned_by"] = userId
        FireController.db.child("groups/\(groupId)").setValue(groupMap) { error, ref in
            if error != nil {
                Log.w("Error creating group: \(error!.localizedDescription)")
            }
            then?(error == nil)
        }
    }
    
    func addChannelToGroup(channelId: String, channelMap: [String: Any], groupId: String, then: ((Bool) -> Void)? = nil) {
        FireController.db.child("group-channels/\(groupId)/\(channelId)").setValue(channelMap) { error, ref in
            if error != nil {
                Log.w("Error creating channel: \(error!.localizedDescription)")
            }
            then?(error == nil)
        }
    }
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Update
     *--------------------------------------------------------------------------------------------*/
    
    func updateUsername(userId: String, username: String, then: ((Error?) -> Void)? = nil) {
        let userId = UserController.instance.userId!
        let path = "users/\(userId)/username"
        FireController.db.child(path).setValue(username) { error, ref in
            if error == nil {
                Log.d("Username changed to: \(username)")
            }
            then?(error)
        }
    }

    func updateEmail(userId: String, email: String, then: ((Error?) -> Void)? = nil) {
        var updates: [String: Any] = [:]
        let path = "member-groups/\(userId)"
        FireController.db.child(path).observeSingleEvent(of: .value, with: { snap in
            if let groups = snap.value as? [String: Any] {
                for groupId in groups.keys {
                    if let group = groups[groupId] as? [String: Any],
                        let _ = group["email"] as? String {
                        updates["member-groups/\(userId)/\(groupId)/email"] = email
                        updates["group-members/\(groupId)/\(userId)/email"] = email
                    }
                }
                FireController.db.updateChildValues(updates) { error, ref in
                    if error != nil {
                        Log.w("Permission denied updating email in memberships")
                    }
                    then?(error)
                }
            }
        }, withCancel: { error in
            Log.w("Permission denied: \(path)")
            then?(error)
        })
    }
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Membership
     *--------------------------------------------------------------------------------------------*/

    func addUserToChannel(userId: String, groupId: String, channelId: String, role: String! = "member",
                          inviteId: String? = nil, invitedBy: String? = nil,
                          then: ((ServiceError?, Any?) -> Void)? = nil) {
        
        let timestamp = getServerTimestamp()
        var membership = channelMemberMap(userId: userId, timestamp: timestamp, priorityIndex: 4, role: role /* neutral */)
        
        if inviteId != nil {
            membership["invite_id"] = inviteId
            membership["invited_by"] = invitedBy
        }
        
        FireController.db.child("group-channel-members/\(groupId)/\(channelId)/\(userId)").setValue(membership) { error, ref in
            if error != nil {
                Log.w("Permission denied adding group member")
                then?(ServiceError(code: 403, message: "Permission denied"), nil)  // permission denied
                return
            }
            then?(nil, true)
        }
    }
    
    func addUserToGroup(groupId: String, channelId: String?, role: String,
                        inviteId: String?, invitedBy: String?,
                        then: ((ServiceError?, Any?) -> Void)? = nil) {
        
        let userId = UserController.instance.userId!
        let timestamp = getServerTimestamp()
        var membership = groupMemberMap(userId: userId, timestamp: timestamp, priorityIndex: 4, role: role /* neutral */)
        
        if inviteId != nil {
            membership["invite_id"] = inviteId
            membership["invited_by"] = invitedBy
        }

        FireController.db.child("group-members/\(groupId)/\(channelId)/\(userId)").setValue(membership) { error, ref in
            if error != nil {
                Log.w("Permission denied adding group member")
                then?(ServiceError(code: 403, message: "Permission denied"), nil)  // permission denied
                return
                
                /* If permission failure then check the invite
                 
                 if (req.invite_id) {
                    const path = `invites/${req.group_id}/${req.invited_by}/${req.invite_id}`
                    const snap: DataSnapshot = await shared.database.ref(path).once('value')
                    if (!snap.exists()) {
                        throw new Error(errors.not_found_invite.message)
                    }
                    const invite = snap.val()
                    /* Revalidate */
                    if (invite.status !== 'pending') {
                        throw new Error(errors.invalid_invite.message)
                    }
                    else if (invite.group.id !== req.group_id) {
                        throw new Error(errors.invalid_invite.message)
                    }
                    if (invite.channel) {
                        req.channel_id = invite.channel.id
                    }
                 }*/
            }
            then?(nil, true)
        }
    }

    func removeUserFromGroup(userId: String, groupId: String, then: ((ServiceError?, Any?) -> Void)? = nil) {
        
        var updates: [String: Any] = [:]
        updates["group-members/\(groupId)/\(userId)"] = NSNull() // delete requires group owner or creator
        FireController.db.updateChildValues(updates) { error, ref in
            if error != nil {
                Log.w("Permission denied removing group member")
                then?(ServiceError(code: 403, message: "Permission denied"), nil)  // permission denied
                return
            }
            then?(nil, nil)
        }
    }

    func removeUserFromChannel(userId: String, groupId: String, channelId: String, channelName: String?, then: ((ServiceError?, Any?) -> Void)? = nil) {
        
        var updates: [String: Any] = [:]
        updates["group-channel-members/\(groupId)/\(channelId)/\(userId)"] = NSNull() // delete requires creator or owner (channel or group)
        FireController.db.updateChildValues(updates) { error, ref in
            if error != nil {
                Log.w("Permission denied removing channel member")
                then?(ServiceError(code: 403, message: "Permission denied"), nil)  // permission denied
                return
            }
            then?(nil, nil)
        }
    }
    
    func channelMemberMap(userId: String, timestamp: Int64, priorityIndex: Int, role: String) -> [String: Any] {
        
        let priority = self.priorities[priorityIndex]
        let priorityReversed = self.priorities.reversed()[priorityIndex]
        let joinedAt = Int(floorf(Float(timestamp / 1000))) // shorten to 10 digits
        let index = Int64("\(priority)\(joinedAt)")
        let indexReversed = Int64("-\(priorityReversed)\(joinedAt)")
        
        let link: [String: Any] = [
            "archived": false,
            "created_at": timestamp,
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
        let index = Int64("\(priority)\(joinedAt)")
        let indexReversed = Int64("-\(priorityReversed)\(joinedAt)")
        let email = (Auth.auth().currentUser?.email!)!
        
        let link: [String: Any] = [
            "created_at": timestamp,
            "created_by": userId,
            "disabled": false,
            "email": email,
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
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Delete
     *--------------------------------------------------------------------------------------------*/

    func deleteGroup(groupId: String) {
        let path = "groups/\(groupId)"
        FireController.db.child(path).setValue(NSNull()) { error, ref in
            if error == nil {
                Log.d("Group deleted: \(groupId)")
            }
        }
    }
    
    func deleteChannel(channelId: String, groupId: String) {
        let path = "group-channels/\(groupId)/\(channelId)"
        FireController.db.child(path).setValue(NSNull()) { error, ref in
            if error == nil {
                Log.d("Channel deleted: \(channelId) from group: \(groupId)")
            }
        }
    }
    
    func deleteMessage(messageId: String, channelId: String, groupId: String) {
        let path = "group-messages/\(groupId)/\(channelId)/\(messageId)"
        FireController.db.child(path).setValue(NSNull()) { error, ref in
            if error == nil {
                Log.d("Message deleted: \(messageId)")
            }
        }
    }
    
    func deleteInvite(groupId: String, inviterId: String, inviteId: String, then: ((Bool) -> Void)? = nil) {
        let path = "invites/\(groupId)/\(inviterId)/\(inviteId)"
        FireController.db.child(path).removeValue() { error, ref in
            if error != nil {
                Log.w("Error deleting invite; \(error!.localizedDescription)")
            }
            then?(error == nil)
        }
    }
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Clear
     *--------------------------------------------------------------------------------------------*/
    
    func clearMessageUnread(messageId: String, channelId: String, groupId: String) {
        let userId = UserController.instance.userId!
        let unreadPath = "unreads/\(userId)/\(groupId)/\(channelId)/\(messageId)"
        FireController.db.child(unreadPath).removeValue()
    }
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Lookups
     *--------------------------------------------------------------------------------------------*/
    
    func autoPickChannel(groupId: String, role: String, next: @escaping (String?) -> Void) {
        if role != "guest" {
            FireController.instance.findGeneralChannel(groupId: groupId) { channelId in
                next(channelId)
            }
        }
        else {
            FireController.instance.findFirstChannel(groupId: groupId) { channelId in
                if channelId != nil {
                    next(channelId)
                }
                else {
                    next(nil)
                }
            }
        }
    }
    
    func findFirstChannel(groupId: String, next: @escaping (String?) -> Void) {
        let userId = UserController.instance.userId!
        let path = "member-channels/\(userId)/\(groupId)"
        let query = FireController.db.child(path).queryOrdered(byChild: "index_priority_joined_at_desc").queryLimited(toFirst: 1)
        
        query.observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) && snap.hasChildren() {
                let channelId = (snap.children.nextObject() as! DataSnapshot).key
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
                let channelId = (snap.children.nextObject() as! DataSnapshot).key
                next(channelId)
                return
            }
            next(nil)
        }, withCancel: { error in
            Log.w("Permission denied trying to find general channel: \(path)")
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
        }, withCancel: { error in
            Log.w("Permission denied trying to find first group: member-groups/\(userId)")
            next(nil)
        })
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
                Log.w("Permission denied getting channel role count: \(path)")
                then(nil)
            })
    }
    
    func isChannelMember(userId: String, channelId: String, groupId: String, next: @escaping ((Bool?) -> Void)) {
        let path = "group-channel-members/\(groupId)/\(channelId)/\(userId)"
        FireController.db.child(path)
            .observeSingleEvent(of: .value, with: { snap in
                next(!(snap.value is NSNull))
            }, withCancel: { error in
                Log.w("Permission denied checking channel membership: \(path)")
                next(nil)
            })
    }
    
    func channelNameExists(groupId: String, channelName: String, next: @escaping ((Error?, Bool) -> Void)) {
        let path = "channel-names/\(groupId)/\(channelName)"
        FireController.db.child(path).observeSingleEvent(of: .value, with: { snap in
            next(nil, !(snap.value is NSNull))
        }, withCancel: { error in
            Log.w("Permission denied: \(path)")
            next(error, false)
        })
    }
    
    func usernameExists(username: String, next: @escaping ((Error?, Bool) -> Void)) {
        let path = "usernames/\(username)"
        FireController.db.child(path).observeSingleEvent(of: .value, with: { snap in
            next(nil, !(snap.value is NSNull))
        }, withCancel: { error in
            Log.w("Permission denied: \(path)")
            next(error, false)
        })
    }
    
    func emailProviderExists(email: String, next: @escaping ((Error?, Bool) -> Void)) {
        /*
         * Can be called when the user is not authenticated.
         */
        Auth.auth().fetchProviders(forEmail: email, completion: { providers, error in
            next(error, (error == nil && providers != nil && providers!.count > 0))
        })
    }
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Utility
     *--------------------------------------------------------------------------------------------*/
    
    func submitTask(task: [String: Any], ref: DatabaseReference, then: ((ServiceError?, Any?) -> Void)? = nil) {
        ref.setValue(task) { error, ref in
            if error == nil {
                var handle: UInt = 0
                handle = ref.child("response").observe(.value, with: { snap in
                    if let response = snap.value as? [String: Any] {
                        
                        snap.ref.removeObserver(withHandle: handle)
                        ref.removeValue()   // Delete task from queue
                        
                        let errorMessage = response["error"] as? String
                        let result = response["result"] as Any?
                        
                        if errorMessage != nil {
                            let error = ServiceError(message: errorMessage!)
                            Log.d("Task error: \(errorMessage!)")
                            then?(error, result)
                            return
                        }
                        then?(nil, result)
                    }
                }
                , withCancel: { error in
                    Log.w("Permission denied observing task response: \(ref.url)")
                    then?(ServiceError(code: 403, message: "Permission denied"), nil)  // permission denied
                })
                return
            }
            /* This can be triggered by an already used invite since the rules check
               if invite status == "pending". Could also be triggered if invite has 
               been revoked (deleted). */
            Log.w("Permission denied submitting task: \(ref.url)")
            then?(ServiceError(code: 403, message: "Permission denied"), nil)  // permission denied
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
        return (DateUtils.now() + (FireController.instance.serverOffset ?? 0))
    }
}

@objc(DataSourceDelegate)
protocol DataSourceDelegate: class {
    @objc optional func array(_ array: FirebaseArray, didAdd object: Any, at index: UInt)
    @objc optional func array(_ array: FirebaseArray, didChange object: Any, at index: UInt)
    @objc optional func array(_ array: FirebaseArray, didRemove object: Any, at index: UInt)
    @objc optional func array(_ array: FirebaseArray, didMove object: Any, from fromIndex: UInt, to toIndex: UInt)
    @objc optional func array(_ array: FirebaseArray, queryCancelledWithError error: Error)
    @objc optional func arrayDidBeginUpdates(_ array: FirebaseArray)
    @objc optional func arrayDidEndUpdates(_ array: FirebaseArray)
}

class FirebaseArray: NSObject {
    
    weak var delegate: DataSourceDelegate?
    private var snapshots = [DataSnapshot]()
    private var handles = Set<UInt>()
    private let query: FUIDataObservable
    private var isSendingUpdates = false
    
    var items: [Any] {
        get {
            return self.snapshots
        }
    }
    
    init(query: FUIDataObservable) {
        self.query = query
    }
    
    deinit {
        self.invalidate()
    }
    
    func observeQuery() {
        
        if self.handles.count == 5 { return }
        
        var handle = self.query.observe(.childAdded, andPreviousSiblingKeyWith: { snap, previousChildKey in
            self.didUpdate()
            self.insert(snap, withPreviousChildKey: previousChildKey)
        }, withCancel: { error in
            self.raiseError(error: error)
        })
        self.handles.insert(handle)
        
        handle = self.query.observe(.childChanged, andPreviousSiblingKeyWith: { snap, previousChildKey in
            self.didUpdate()
            self.change(snap, withPreviousChildKey: previousChildKey)
        }, withCancel: { error in
            self.raiseError(error: error)
        })
        self.handles.insert(handle)
        
        handle = self.query.observe(.childRemoved, andPreviousSiblingKeyWith: { snap, previousChildKey in
            self.didUpdate()
            self.remove(snap, withPreviousChildKey: previousChildKey)
        }, withCancel: { error in
            self.raiseError(error: error)
        })
        self.handles.insert(handle)
        
        handle = self.query.observe(.childMoved, andPreviousSiblingKeyWith: { snap, previousChildKey in
            self.didUpdate()
            self.move(snap, withPreviousChildKey: previousChildKey)
        }, withCancel: { error in
            self.raiseError(error: error)
        })
        self.handles.insert(handle)
        
        handle = self.query.observe(.value, andPreviousSiblingKeyWith: { snap, previousChildKey in
            self.didFinishUpdates()
        }, withCancel: { error in
            self.raiseError(error: error)
        })
        self.handles.insert(handle)
    }
    
    func didUpdate() {
        if self.isSendingUpdates { return }
        self.isSendingUpdates = true
        self.delegate?.arrayDidBeginUpdates?(self)
    }
    
    func didFinishUpdates() {
        if !self.isSendingUpdates { return }
        self.isSendingUpdates = false
        self.delegate?.arrayDidEndUpdates?(self)
    }
    
    func raiseError(error: Error) {
        self.delegate?.array?(self, queryCancelledWithError: error)
    }
    
    func invalidate() {
        for handle in self.handles {
            self.query.removeObserver(withHandle: handle)
        }
    }
    
    func index(forKey key: String) -> Int {
        for (index, snap) in self.snapshots.enumerated() {
            if snap.key == key {
                return index
            }
        }
        return NSNotFound
    }
    
    func insert(_ snap: DataSnapshot, withPreviousChildKey previous: String?) {
        var index: UInt = 0
        if previous != nil {
            index = UInt(self.index(forKey: previous!))
        }
        self.snapshots.insert(snap, at: Int(index))
        self.delegate?.array?(self, didAdd: snap, at: index)
    }
    
    func remove(_ snap: DataSnapshot, withPreviousChildKey previous: String?) {
        let index: UInt = UInt(self.index(forKey: snap.key))
        self.snapshots.remove(at: Int(index))
        self.delegate?.array?(self, didRemove: snap, at: index)
    }
    
    func change(_ snap: DataSnapshot, withPreviousChildKey previous: String?) {
        let index: UInt = UInt(self.index(forKey: snap.key))
        self.snapshots[Int(index)] = snap
        self.delegate?.array?(self, didChange: snap, at: index)
    }
    
    func move(_ snap: DataSnapshot, withPreviousChildKey previous: String?) {
        let fromIndex: UInt = UInt(self.index(forKey: snap.key))
        self.snapshots.remove(at: Int(fromIndex))
        var toIndex: UInt = 0
        if previous != nil {
            let prevIndex: UInt = UInt(self.index(forKey: previous!))
            if prevIndex != UInt(NSNotFound) {
                toIndex = prevIndex + 1
            }
        }
        self.snapshots.insert(snap, at: Int(toIndex))
        self.delegate?.array?(self, didMove: snap, from: fromIndex, to: toIndex)
    }
}

class ServiceError: Error {
    var code: Float!
    var message: String!
    init(code: Float, message: String) {
        self.code = code
        self.message = message
    }
    init(message: String) {
        self.code = 400
        self.message = message
    }
}

enum Trigger: Int {
    case object
    case link
}

struct TaskState {
    static let waiting = "waiting"
    static let processing = "processing"
    static let finished = "finished"
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
