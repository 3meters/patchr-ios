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

class StateController: NSObject {

    static let instance = StateController()
    
    fileprivate(set) internal var groupId: String?
    fileprivate(set) internal var group: FireGroup! // Used by FireController, invite links
    fileprivate var groupQuery: GroupQuery?

    fileprivate(set) internal var channelId: String?
    
    private override init() { }

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
        queue.tasks += { _, next in
            
            guard UserController.instance.authenticated else {
                next(nil)
                return
            }
            
            if let groupId = UserDefaults.standard.string(forKey: "groupId"),
                let userId = UserController.instance.userId {
                
                if let lastChannelId = UserDefaults.standard.string(forKey: groupId)  {
                    let validateQuery = ChannelQuery(groupId: groupId, channelId: lastChannelId, userId: userId)
                    validateQuery.once(with: { channel in
                        if channel == nil {
                            Log.w("Last channel invalid: \(lastChannelId): trying first channel")
                            FireController.instance.findFirstChannel(groupId: groupId) { firstChannelId in
                                if firstChannelId != nil {
                                    self.setGroupId(groupId: groupId, channelId: firstChannelId, next: next)
                                }
                                else {
                                    /* Start from scratch */
                                    self.clearGroup()
                                    self.clearChannel()
                                    next(nil)
                                }
                            }
                        }
                        else {
                            self.setGroupId(groupId: groupId, channelId: lastChannelId, next: next)
                        }
                    })
                }
                else {
                    FireController.instance.findFirstChannel(groupId: groupId) { firstChannelId in
                        if firstChannelId != nil {
                            self.setGroupId(groupId: groupId, channelId: firstChannelId, next: next)
                        }
                        else {
                            /* Start from scratch */
                            self.clearGroup()
                            self.clearChannel()
                            next(nil)
                        }
                    }
                }
            }
            else {
                next(nil)
            }
        }

        queue.tasks += {
            NotificationCenter.default.post(
                name: NSNotification.Name(rawValue: Events.StateInitialized),
                object: self, userInfo: nil)
        }
        
        queue.run()
    }
    
    func setGroupId(groupId: String, channelId: String!, next: ((Any?) -> Void)? = nil) {
        
        if NotificationController.instance.groupBadgeCounts[groupId] != nil {
            NotificationController.instance.groupBadgeCounts[groupId] = 0
        }
        
        guard groupId != self.groupId else {
            next?(nil)
            return
        }
        
        Log.d("Current group: \(groupId)")
        
        self.groupId = groupId
        setChannelId(channelId: channelId)
        
        UserDefaults.standard.set(groupId, forKey: "groupId")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.GroupDidSwitch), object: self, userInfo: nil)
        next?(nil)
        
        /* Convenience for other parts of the code that need quick access to the group object */
        let userId = UserController.instance.userId
        self.groupQuery?.remove()
        self.groupQuery = GroupQuery(groupId: groupId, userId: userId!)
        self.groupQuery!.observe(with: { group in
            
            guard group != nil else {
                Log.w("Requested group invalid: \(groupId)")
                self.clearGroup()
                next?(nil)
                return
            }
            
            if self.group != nil {
                Log.d("Group updated: \(group!.id!)")
            }
            
            self.group = group
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.GroupDidChange), object: self, userInfo: nil)
        })
    }
    
    func setChannelId(channelId: String?, next: ((Any?) -> Void)? = nil) {
        
        guard channelId != nil && self.groupId != nil && UserController.instance.userId != nil else {
            assertionFailure("userId, groupId and channelId must be set")
            return
        }
        
        if NotificationController.instance.channelBadgeCounts[channelId!] != nil {
            NotificationController.instance.channelBadgeCounts[channelId!] = 0
            if let userId = UserController.instance.userId {
                let channelQuery = ChannelQuery(groupId: self.groupId!, channelId: channelId!, userId: userId)
                channelQuery.once(with: { channel in
                    if channel?.priority == 0 {
                        channel?.unread(on: false)
                    }
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.GroupDidChange)
                        , object: self, userInfo: nil)
                })
            }
        }
        
        guard channelId != self.channelId else {
            return
        }

        Log.d("Current channel: \(channelId!)")
        
        self.channelId = channelId
        UserDefaults.standard.set(channelId, forKey: self.groupId!) // channelId keyed on groupId
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.ChannelDidSwitch)
            , object: self, userInfo: nil)
        next?(nil)
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
        self.channelId = nil
        if self.groupId != nil {
            UserDefaults.standard.removeObject(forKey: self.groupId!)   // channelId keyed on groupId
        }
    }    
}
