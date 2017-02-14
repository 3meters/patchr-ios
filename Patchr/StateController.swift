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
    fileprivate(set) internal var groupGeneralId: String?
    fileprivate(set) internal var group: FireGroup! // Used by FireController, invite links
    fileprivate var groupQuery: GroupQuery?

    fileprivate(set) internal var channelId: String?
    fileprivate(set) internal var stateIntialized = false
    
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
            
            if let groupId = UserDefaults.standard.string(forKey: "group_id"),
                let userId = UserController.instance.userId {
                
                if let settings = UserDefaults.standard.dictionary(forKey: groupId),
                    let lastChannelId = settings["currentChannelId"] as? String {
                    let channelQuery = ChannelQuery(groupId: groupId, channelId: lastChannelId, userId: userId)
                    channelQuery.once(with: { error, channel in
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
            self.stateIntialized = true
            NotificationCenter.default.post(
                name: NSNotification.Name(rawValue: Events.StateInitialized),
                object: self, userInfo: nil)
        }
        
        queue.run()
    }
    
    func setChannelId(channelId: String?, groupId: String, bundle: [String: Any]? = nil, next: ((Any?) -> Void)? = nil) {
        
        var userInfo: [String: Any] = [:]
        userInfo["fromGroupId"] = bundle?["fromGroupId"] ?? self.groupId
        userInfo["toGroupId"] = bundle?["toGroupId"] ?? groupId
        
        if groupId != self.groupId {
            
            Log.d("Current group: \(groupId)")
            
            self.groupId = groupId
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.GroupDidSwitch), object: self, userInfo: userInfo)
            UserDefaults.standard.set(groupId, forKey: "group_id")

            /* Stash channelId for general channel */
            FireController.instance.findGeneralChannel(groupId: groupId) { channelId in
                self.groupGeneralId = channelId
            }
            
            if channelId != nil {
                setChannelId(channelId: channelId, groupId: groupId, bundle: userInfo, next: next)
            }
            
            /* Convenience for other parts of the code that need quick access to the group object */
            let userId = UserController.instance.userId!
            self.groupQuery?.remove()
            self.groupQuery = GroupQuery(groupId: groupId, userId: userId)
            self.groupQuery!.observe(with: { group in
                
                guard group != nil else {
                    Log.w("Requested group invalid: \(groupId)")
                    self.clearGroup()
                    if next != nil {
                        next?(nil)
                    }
                    else {
                        /* Group has been deleted from under us. Try to switch to something reasonable. */
                        FireController.instance.autoPickGroupAndChannel(userId: userId) { groupId, channelId in
                            if groupId != nil && channelId != nil {
                                StateController.instance.setChannelId(channelId: channelId!, groupId: groupId!)
                                MainController.instance.showChannel(groupId: groupId!, channelId: channelId!)
                            }
                        }
                    }
                    return
                }
                
                if self.group != nil {
                    Log.d("Group updated: \(group!.id!)")
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
            
            userInfo["fromChannelId"] = self.channelId
            userInfo["toChannelId"] = channelId!
            self.channelId = channelId!
            
            var groupSettings: [String: Any] = (UserDefaults.standard.dictionary(forKey: groupId) ?? [:])!
            groupSettings["currentChannelId"] = channelId!
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
        UserDefaults.standard.removeObject(forKey: "group_id")
    }
    
    func clearChannel() {
        Log.d("Current channel: nothing")
        self.channelId = nil
        if self.groupId != nil {
            UserDefaults.standard.removeObject(forKey: self.groupId!)   // channelId keyed on groupId
        }
    }    
}
