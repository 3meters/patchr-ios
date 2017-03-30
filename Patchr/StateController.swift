/*
 * Firebase controller
 *
 * Provide convenience functionality when interacting with the Firebase database.
 */

import UIKit
import Keys
import AFNetworking
import iRate
import SlideMenuControllerSwift
import Firebase
import FirebaseDatabase
import FirebaseAuth

class StateController: NSObject {

    static let instance = StateController()
    
    var handleAuth: FIRAuthStateDidChangeListenerHandle!

    fileprivate(set) internal var groupId: String?
    fileprivate(set) internal var groupGeneralId: String?
    fileprivate(set) internal var group: FireGroup! // Used by FireController, invite links

    fileprivate var queryGroup: GroupQuery?

    fileprivate(set) internal var channelId: String?
    fileprivate(set) internal var stateIntialized = false
    
    private override init() {
        super.init()
        FIRAuth.auth()?.addStateDidChangeListener() { auth, user in
            if user == nil {
                if let groupId = self.groupId {
                    FireController.db.child("group-members/\(groupId)").keepSynced(false)
                    FireController.db.child("channel-names/\(groupId)").keepSynced(false)
                    if let userId = UserController.instance.userId {
                        FireController.db.child("invites/\(groupId)/\(userId)").keepSynced(false)
                    }
                    if let channelId = self.channelId {
                        FireController.db.child("group-channel-members/\(groupId)/\(channelId)").keepSynced(false)
                    }
                }
            }
        }
    }

    /*--------------------------------------------------------------------------------------------
     * MARK: - Methods
     *--------------------------------------------------------------------------------------------*/

    func prepare() {

        let queue = TaskQueue()
        
        /* Init user */
        queue.tasks += { _, next in
            /* We wait until user is resolved */
            UserController.instance.prepare() { success in
                next(nil)
            }
        }
        
        /* Init state */
        queue.tasks += { [weak self] _, next in
            
            guard UserController.instance.authenticated else {
                next(nil)
                return
            }
            
            if let strongSelf = self {
                if let groupId = UserDefaults.standard.string(forKey: PerUserKey(key: Prefs.lastGroupId)),
                    let userId = UserController.instance.userId {
                    
                    if let lastChannelIds = UserDefaults.standard.dictionary(forKey: PerUserKey(key: Prefs.lastChannelIds)),
                        let lastChannelId = lastChannelIds[groupId] as? String {
                        let channelQuery = ChannelQuery(groupId: groupId, channelId: lastChannelId, userId: userId)
                        channelQuery.once(with: { error, channel in
                            if channel == nil {
                                Log.w("Last channel invalid: \(lastChannelId): trying auto pick channel")
                                FireController.instance.autoPickChannel(groupId: groupId) { channelId in
                                    if channelId != nil {
                                        strongSelf.setChannelId(channelId: channelId!, groupId: groupId) { error in
                                            next(nil)
                                        }
                                    }
                                    else {
                                        /* Start from scratch */
                                        strongSelf.clearGroup()
                                        strongSelf.clearChannel()
                                        next(nil)
                                    }
                                }
                            }
                            else {
                                strongSelf.setChannelId(channelId: lastChannelId, groupId: groupId) { error in
                                    next(nil)
                                }
                            }
                        })
                    }
                    else {
                        FireController.instance.autoPickChannel(groupId: groupId) { channelId in
                            if channelId != nil {
                                strongSelf.setChannelId(channelId: channelId!, groupId: groupId) { error in
                                    next(nil)
                                }
                            }
                            else {
                                /* Start from scratch */
                                strongSelf.clearGroup()
                                strongSelf.clearChannel()
                                next(nil)
                            }
                        }
                    }
                }
                else {
                    next(nil)
                }
            }
        }

        queue.tasks += { [weak self] in
            if let strongSelf = self {
                strongSelf.stateIntialized = true
                NotificationCenter.default.post(
                    name: NSNotification.Name(rawValue: Events.StateInitialized),
                    object: strongSelf, userInfo: nil)
            }
        }
        
        queue.run()
    }
    
    func setChannelId(channelId: String?, groupId: String, bundle: [String: Any]? = nil, next: ((Error?) -> Void)? = nil) {
        
        var userInfo: [String: Any] = [:]
        userInfo["fromGroupId"] = bundle?["fromGroupId"] ?? self.groupId
        userInfo["toGroupId"] = bundle?["toGroupId"] ?? groupId
        
        if groupId != self.groupId {
            
            Log.d("Current group: \(groupId)")
            
            let userId = UserController.instance.userId!
            
            if self.groupId != nil {
                FireController.db.child("group-members/\(self.groupId!)").keepSynced(false)
                FireController.db.child("channel-names/\(self.groupId!)").keepSynced(false)
                FireController.db.child("invites/\(self.groupId!)/\(userId)").keepSynced(false)
                if self.channelId != nil {
                    FireController.db.child("group-channel-members/\(self.groupId!)/\(self.channelId!)").keepSynced(false)
                }
            }

            FireController.db.child("group-members/\(groupId)").keepSynced(true)
            FireController.db.child("channel-names/\(groupId)").keepSynced(true)
            FireController.db.child("invites/\(groupId)/\(userId)").keepSynced(true)

            self.groupId = groupId
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.GroupDidSwitch), object: self, userInfo: userInfo)
            UserDefaults.standard.set(groupId, forKey: PerUserKey(key: Prefs.lastGroupId))

            if channelId != nil {
                setChannelId(channelId: channelId, groupId: groupId, bundle: userInfo, next: next)
            }
            
            /* Convenience for other parts of the code that need quick access to the group object */
            self.queryGroup?.remove()
            self.queryGroup = GroupQuery(groupId: groupId, userId: userId)
            self.queryGroup!.observe(with: { error, trigger, group in
                
                guard group != nil && error == nil else {
                    Log.w("Requested group invalid: \(groupId)")
                    self.clearGroup()
                    if next != nil {
                        next?(error)
                    }
                    else {
                        /* Group has been deleted from under us. */
                        MainController.instance.route()
                    }
                    return
                }
                
                if self.group != nil {
                    if trigger == .object {
                        Log.d("Group updated: \(group!.id!)")
                    }
                    else if trigger == .link {
                        Log.d("Group membership updated: \(group!.id!)")
                    }
                }
                else { // First callback
                    if let role = group?.role, role != "guest" {
                        /* Stash channelId for general channel if not guest */
                        FireController.instance.findGeneralChannel(groupId: groupId) { channelId in
                            self.groupGeneralId = channelId
                        }
                    }
                }
                
                self.group = group
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.GroupDidUpdate), object: self, userInfo: ["group_id": groupId])
            })
        }
        else {
            
            guard UserController.instance.userId != nil else {
                assertionFailure("userId, groupId and channelId must be set")
                return
            }
            
            guard channelId != self.channelId else {
                next?(nil)
                return
            }
            
            Log.d("Current channel: \(channelId!)")
            
            FireController.db.child("group-channel-members/\(groupId)/\(channelId!)").keepSynced(true)
            
            userInfo["fromChannelId"] = self.channelId
            userInfo["toChannelId"] = channelId!
            self.channelId = channelId!
            
            var lastChannelIds: [String: Any] = (UserDefaults.standard.dictionary(forKey: PerUserKey(key: Prefs.lastChannelIds)) ?? [:])!
            lastChannelIds[groupId] = channelId!
            UserDefaults.standard.set(lastChannelIds, forKey: PerUserKey(key: Prefs.lastChannelIds))
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.ChannelDidSwitch), object: self, userInfo: userInfo)
            
            next?(nil)
        }
    }
    
    func clearGroup() {
        Log.d("Current group: nothing")
        let userId = UserController.instance.userId!
        if self.groupId != nil {
            var userInfo: [String: Any] = [:]
            userInfo["groupId"] = self.groupId!
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.GroupDisconnected), object: self, userInfo: userInfo)
            FireController.db.child("group-members/\(self.groupId!)").keepSynced(false)
            FireController.db.child("channel-names/\(self.groupId!)").keepSynced(false)
            FireController.db.child("invites/\(self.groupId!)/\(userId)").keepSynced(false)
            if self.channelId != nil {
                FireController.db.child("group-channel-members/\(self.groupId!)/\(self.channelId!)").keepSynced(false)
            }
        }
        clearChannel()
        self.queryGroup?.remove() // Clear active observer if one
        self.groupId = nil
        self.group = nil
        self.queryGroup = nil
    }
    
    func clearChannel() {
        Log.d("Current channel: nothing")
        self.channelId = nil
        if self.groupId != nil,
            var lastChannelIds = UserDefaults.standard.dictionary(forKey: PerUserKey(key: Prefs.lastChannelIds)) {
            lastChannelIds.removeValue(forKey: self.groupId!)
            UserDefaults.standard.set(lastChannelIds, forKey: PerUserKey(key: Prefs.lastChannelIds))
        }
    }    
}
