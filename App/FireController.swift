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
    
    func addChannel(channelId: String, channelMap: [String: Any], then: ((Bool) -> Void)? = nil) {
        FireController.db.child("channels/\(channelId)").setValue(channelMap) { error, ref in
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

    /*--------------------------------------------------------------------------------------------
     * MARK: - Membership
     *--------------------------------------------------------------------------------------------*/

    func addUserToChannel(userId: String, channelId: String, code: String, role: String! = "editor",
                          then: ((ServiceError?, Any?) -> Void)? = nil) {
        
        let timestamp = getServerTimestamp()
        let membership = channelMemberMap(userId: userId, timestamp: timestamp, code: code, role: role)
        
        FireController.db.child("channel-members/\(channelId)/\(userId)").setValue(membership) { error, ref in
            if error != nil {
                /* Could be denied because channel is missing or channel secret is bad. */
                Log.w("Permission denied adding channel member")
                then?(ServiceError(code: 403, message: "Permission denied"), nil)  // permission denied
                return
            }
            then?(nil, true)
        }
    }
    
    func channelMemberMap(userId: String, timestamp: Int64, code: String, role: String) -> [String: Any] {
        
        let link: [String: Any] = [
            "activity_at": timestamp,
            "activity_at_desc": timestamp * -1,
            "activity_by": userId,
            "code": code,
            "created_at": timestamp,
            "created_by": userId,
            "notifications": "all",
            "role": role,
            "starred": false,
            ]
        
        return link
    }
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Delete
     *--------------------------------------------------------------------------------------------*/

    func deleteChannel(channelId: String) {
        let path = "channels/\(channelId)"
        FireController.db.child(path).removeValue() { error, ref in
            if error == nil {
                Log.d("Channel deleted: \(channelId)")
            }
        }
    }
    
    func deleteMessage(messageId: String, channelId: String, then: ((Error?) -> Void)? = nil) {
        let path = "channel-messages/\(channelId)/\(messageId)"
        FireController.db.child(path).removeValue() { error, ref in
            if error == nil {
                Log.d("Message deleted: \(messageId)")
            }
            then?(error)
        }
    }
    
    func deleteComment(commentId: String, messageId: String, channelId: String, then: ((Error?) -> Void)? = nil) {
        let path = "message-comments/\(channelId)/\(messageId)/\(commentId)"
        FireController.db.child(path).removeValue() { error, ref in
            if error == nil {
                Log.d("Comment deleted: \(commentId)")
            }
            then?(error)
        }
    }
    
    func deleteMembership(userId: String, channelId: String, then: ((ServiceError?, Any?) -> Void)? = nil) {
        var updates = [String: Any]()
        updates["channel-members/\(channelId)/\(userId)"] = NSNull()
        updates["member-channels/\(userId)/\(channelId)"] = NSNull()
        FireController.db.updateChildValues(updates) { error, ref in
            if error == nil {
                Log.d("Membership deleted: \(channelId)")
                then?(nil, nil)
                return
            }
            Log.w("Permission denied removing channel member")
            then?(ServiceError(code: 403, message: "Permission denied"), nil)  // permission denied
            return
        }
    }
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Move
     *--------------------------------------------------------------------------------------------*/
    
    func moveMessage(message: FireMessage, fromChannelId: String, toChannelId: String, then: ((Error?) -> Void)? = nil) {
        /* activity date is set to created date which doesn't change for the move. That
           means that activity date could be way in the past. Members of the 'to' channel 
           get the standard notification. */
        let messageId = message.id!
        var updates = [String: Any]()
        var messageDict = message.dict!
        updates["moving"] = true
        FireController.db.child("channel-messages/\(fromChannelId)/\(messageId)").updateChildValues(updates) { error, ref in
            if error != nil {
                then?(error)
                return
            }
            
            let ref = FireController.db.child("channel-messages/\(toChannelId)").childByAutoId()
            messageDict["channel_id"] = toChannelId
            messageDict["moving"] = true
            ref.setValue(messageDict) { error, ref in
                if error != nil {
                    then?(error)
                    return
                }
                self.deleteMessage(messageId: message.id!, channelId: fromChannelId) { error in
                    then?(error)
                }
            }
        }
    }
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Clear
     *--------------------------------------------------------------------------------------------*/
    
    func clearMessageUnread(messageId: String, channelId: String) {
        let userId = UserController.instance.userId!
        let unreadPath = "unreads/\(userId)/\(channelId)/\(messageId)"
        FireController.db.child(unreadPath).removeValue()
    }
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Lookups
     *--------------------------------------------------------------------------------------------*/
    
    func isChannelMember(userId: String, channelId: String, next: @escaping ((Bool?) -> Void)) {
        let path = "channel-members/\(channelId)/\(userId)"
        FireController.db.child(path)
            .observeSingleEvent(of: .value, with: { snap in
                next(!(snap.value is NSNull))
            }, withCancel: { error in
                Log.w("Permission denied checking channel membership: \(path)")
                next(nil)
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
