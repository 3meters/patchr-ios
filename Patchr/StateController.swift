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
                
                if let settings = UserDefaults.standard.dictionary(forKey: groupId),
                    let lastChannelId = settings["currentChannelId"] as? String {
                    let validateQuery = ChannelQuery(groupId: groupId, channelId: lastChannelId, userId: userId)
                    validateQuery.once(with: { channel in
                        if channel == nil {
                            Log.w("Last channel invalid: \(lastChannelId): trying first channel")
                            FireController.instance.findFirstChannel(groupId: groupId) { firstChannelId in
                                if firstChannelId != nil {
                                    self.setChannelId(channelId: firstChannelId!, groupId: groupId, next: next)
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
                            self.setChannelId(channelId: lastChannelId, groupId: groupId, next: next)
                        }
                    })
                }
                else {
                    FireController.instance.findFirstChannel(groupId: groupId) { firstChannelId in
                        if firstChannelId != nil {
                            self.setChannelId(channelId: firstChannelId!, groupId: groupId, next: next)
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
    
    func setChannelId(channelId: String, groupId: String, bundle: [String: Any]? = nil, next: ((Any?) -> Void)? = nil) {
        
        var userInfo: [String: Any] = [:]
        userInfo["fromGroupId"] = bundle?["fromGroupId"] ?? self.groupId
        userInfo["toGroupId"] = bundle?["toGroupId"] ?? groupId
        
        if groupId != self.groupId {
            
            if NotificationController.instance.groupBadgeCounts[groupId] != nil {
                NotificationController.instance.groupBadgeCounts[groupId] = 0
            }

            Log.d("Current group: \(groupId)")
            
            self.groupId = groupId
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.GroupDidSwitch), object: self, userInfo: userInfo)
            UserDefaults.standard.set(groupId, forKey: "groupId")
            
            setChannelId(channelId: channelId, groupId: groupId, bundle: userInfo, next: next)
            
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
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.GroupDidChange), object: self, userInfo: ["groupId": groupId])
            })
        }
        else {
            
            guard UserController.instance.userId != nil else {
                assertionFailure("userId, groupId and channelId must be set")
                return
            }
            
            if NotificationController.instance.channelBadgeCounts[channelId] != nil {
                NotificationController.instance.channelBadgeCounts[channelId] = 0
            }
            
            guard channelId != self.channelId else {
                next?(nil)
                return
            }
            
            Log.d("Current channel: \(channelId)")
            
            userInfo["fromChannelId"] = self.channelId
            userInfo["toChannelId"] = channelId
            self.channelId = channelId
            
            var groupSettings: [String: Any] = (UserDefaults.standard.dictionary(forKey: groupId) ?? [:])!
            groupSettings["currentChannelId"] = channelId
            UserDefaults.standard.set(groupSettings, forKey: groupId)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.ChannelDidSwitch), object: self, userInfo: userInfo)
            
            next?(nil)
        }
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
