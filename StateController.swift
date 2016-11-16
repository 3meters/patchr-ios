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
import RxSwift

class StateController: NSObject {

    static let instance = StateController()
    
    fileprivate(set) internal var groupId: String?
    fileprivate(set) internal var channelId: String?
    
    fileprivate var groupQuery: GroupQuery?
    fileprivate var channelQuery: ChannelQuery?
    
    fileprivate(set) internal var group: FireGroup!
    fileprivate(set) internal var channel: FireChannel!

    private override init() { }

    /*--------------------------------------------------------------------------------------------
     * MARK: - Methods
     *--------------------------------------------------------------------------------------------*/

    func prepare() {

        let queue = TaskQueue()
        
        /* Init state */
        queue.tasks += { _, next in
            if UserController.instance.authenticated {
                if let groupId = UserDefaults.standard.string(forKey: "groupId") {
                    self.setGroupId(groupId: groupId, next: next)
                    return
                }
            }
            next(nil)
        }

        queue.tasks += {
            NotificationCenter.default.post(
                name: NSNotification.Name(rawValue: Events.StateInitialized),
                object: self, userInfo: nil)
        }
        
        queue.run()
    }
    
    func setGroupId(groupId: String?, channelId: String? = nil, next: ((Any?) -> Void)? = nil) {
        
        guard groupId != nil else {
            assertionFailure("groupId cannot be nil")
            next?(nil)
            return
        }
        
        guard groupId != self.groupId else {
            next?(nil)
            return
        }
        
        /* Changing */
        
        Log.d("Current group: \(groupId!)")
        let userId = UserController.instance.userId
        self.groupQuery?.remove()
        self.groupQuery = GroupQuery(groupId: groupId!, userId: userId!)
        self.groupQuery!.observe(with: { group in
            
            guard group != nil else {
                Log.w("Requested group invalid: \(groupId!)")
                self.clearGroup()
                next?(nil)
                return
            }
            
            if self.group != nil {
                Log.d("Group updated: \(group!.id!)")
            }
            
            self.group = group
            self.groupId = groupId
            UserDefaults.standard.set(groupId, forKey: "groupId")
            
            /* Use specified channel */
            if channelId != nil {
                self.setChannelId(channelId: channelId) { result in
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.GroupDidChange), object: self, userInfo: nil)
                    next?(result)
                }
            }
            else {
                /* User last channel if available */
                if let lastChannelId = UserDefaults.standard.string(forKey: groupId!) {
                    
                    let validateQuery = ChannelQuery(groupId: groupId!, channelId: lastChannelId, userId: userId!)
                    validateQuery.once(with: { channel in
                        if channel == nil {
                            Log.w("Last channel invalid: \(lastChannelId): trying first channel")
                            self.selectFirstChannel(groupId: groupId) { result in
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.GroupDidChange), object: self, userInfo: nil)
                                next?(result)
                            }
                        }
                        else {
                            self.setChannelId(channelId: lastChannelId) { result in
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.GroupDidChange), object: self, userInfo: nil)
                                next?(result)
                            }
                        }
                    })
                }
                /* User first channel available to this user */
                else {
                    self.selectFirstChannel(groupId: groupId) { result in
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.GroupDidChange), object: self, userInfo: nil)
                        next?(true)
                    }
                }
            }
        })
    }
    
    func setChannelId(channelId: String?, next: ((Any?) -> Void)?) {
        
        guard channelId != nil && self.groupId != nil && UserController.instance.userId != nil else {
            assertionFailure("userId, groupId and channelId must be set")
            next?(nil)
            return
        }
        
        guard channelId != self.channelId else {
            next?(nil)
            return
        }

        Log.d("Current channel: \(channelId!)")
        
        /* First we validate */
        let validateQuery = ChannelQuery(groupId: groupId!, channelId: channelId!, userId: UserController.instance.userId!)
        
        validateQuery.once(with: { channel in
            
            guard channel != nil else {
                Log.w("Requested channel invalid: \(channelId!)")
                self.clearChannel()
                return
            }
            
            self.channelId = channelId
            self.channel = channel
            UserDefaults.standard.set(channelId, forKey: self.groupId!) // channelId keyed on groupId
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.ChannelDidSwitch), object: self, userInfo: nil)
            
            next?(nil)
            
            /* Now we observe */
            self.channelQuery?.remove()
            self.channelQuery = ChannelQuery(groupId: self.groupId!, channelId: channelId!, userId: UserController.instance.userId!)
            self.channelQuery!.observe(with: { channel in
                if channel != nil {
                    self.channel = channel
                    Log.d("Channel updated: \(channel!.id!)")
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.ChannelDidChange), object: self, userInfo: nil)
                }
                else {
                    /* Channel has been deleted */
                    self.selectFirstChannel(groupId: self.groupId) { result in
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.GroupDidChange), object: self, userInfo: nil)
                        next?(true)
                    }
                }
            })
        })
    }
    
    func selectFirstChannel(groupId: String?, next: ((Any?) -> Void)? = nil) {
        
        let userId = UserController.instance.userId
        let query = FireController.db.child("member-channels/\(userId!)/\(groupId!)").queryOrdered(byChild: "index_priority_joined_at_desc").queryLimited(toFirst: 1)
        
        query.observeSingleEvent(of: .childAdded, with: { snap in
            
            if !(snap.value is NSNull) {
                self.setChannelId(channelId: snap.key) { result in
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.GroupDidChange), object: self, userInfo: nil)
                    next?(true)
                }
            }
            else {
                /* We totally whiffed on auto picking a channel which is a total fail */
                Log.w("Group does not have a channel accessible by the current user")
                self.clearGroup()
                next?(nil)
            }
        })
    }
    
    func clearGroup() {
        Log.d("Current group: nothing")
        clearChannel()
        self.groupQuery?.remove() // Clear active observer if one
        self.groupId = nil
        self.group = nil
        self.groupQuery = nil
        UserDefaults.standard.removeObject(forKey: "groupId")
    }
    
    func clearChannel() {
        Log.d("Current channel: nothing")
        self.channelQuery?.remove()
        self.channelQuery = nil
        self.channel = nil
        self.channelId = nil
        if self.groupId != nil {
            UserDefaults.standard.removeObject(forKey: self.groupId!)   // channelId keyed on groupId
        }
    }    
}
