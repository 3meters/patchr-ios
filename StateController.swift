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
    
    let db = FIRDatabase.database().reference()

    fileprivate(set) internal var groupId: String?
    fileprivate(set) internal var channelId: String?
    
    fileprivate var groupQuery: GroupQuery!
    fileprivate var channelQuery: ChannelQuery!
    
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
                self.setGroupId(groupId: UserDefaults.standard.string(forKey: "groupId"), next: next)
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

    func setGroupId(groupId: String?, channelId: String? = nil, next: ((Any?) -> Void)? = nil) {

        /* Setting to nil */
        if groupId == nil {
            Log.d("Current group: nothing")
            self.groupId = nil
            self.group = nil
            UserDefaults.standard.removeObject(forKey: "groupId")
            if self.groupQuery != nil {
                self.groupQuery.remove()
            }
            self.groupQuery = nil
            setChannelId(channelId: nil)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.GroupDidChange), object: self, userInfo: nil)
            if next != nil { next!(nil) }
            return
        }
            
        /* Changing */
        if self.groupId != groupId {
            
            Log.d("Current group: \(groupId!)")
            
            /* Validate first */
            self.db.child("groups/\(groupId!)").observeSingleEvent(of: .value, with: { snap in
                if !(snap.value is NSNull) {
                    
                    self.groupId = groupId
                    UserDefaults.standard.set(groupId, forKey: "groupId")
                    if self.groupQuery != nil {
                        self.groupQuery.remove()
                    }
                    let userId = UserController.instance.userId
                    self.groupQuery = GroupQuery(groupId: groupId!, userId: userId!)
                    self.groupQuery.observe(with: { group in
                        self.group = group
                    })
                    
                    if channelId != nil {
                        self.setChannelId(channelId: channelId, notify: false)
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.GroupDidChange), object: self, userInfo: nil)
                        /* group exists and using specified channel */
                        if next != nil { next!(nil) }
                    }
                    else {
                        /* Set last channel or first accessible channel */
                        if let lastChannelId = UserDefaults.standard.string(forKey: groupId!) {
                            self.setChannelId(channelId: lastChannelId, notify: false)
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.GroupDidChange), object: self, userInfo: nil)
                            /* group exists and using last channel */
                            if next != nil { next!(nil) }
                        }
                        else {
                            let userId = UserController.instance.userId
                            let query = self.db.child("member-channels/\(userId!)/\(groupId!)").queryOrdered(byChild: "sort_priority")
                            query.observeSingleEvent(of: .childAdded, with: { snap in
                                if !(snap.value is NSNull) {
                                    self.setChannelId(channelId: snap.key, notify: false)
                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.GroupDidChange), object: self, userInfo: nil)
                                    /* group exists and using first channel */
                                    if next != nil { next!(nil) }
                                }
                            })
                        }
                    }
                }
                else {
                    /* group no longer exists */
                    self.groupId = nil
                    self.channelId = nil
                    if next != nil { next!(nil) }
                }
            })
        }
        else {
            /* group unchanged */
            if next != nil { next!(nil) }
        }
    }

    func setChannelId(channelId: String?, notify: Bool = true) {
        self.channelId = channelId
        if channelId == nil {
            if self.channelQuery != nil {
                self.channelQuery.remove()
            }
            self.channelQuery = nil
            self.channel = nil
        }
        
        if self.groupId != nil {
            if channelId == nil {
                UserDefaults.standard.removeObject(forKey: self.groupId!)
            }
            else {
                UserDefaults.standard.set(channelId, forKey: self.groupId!)
                if self.channelQuery != nil {
                    self.channelQuery.remove()
                }
                let userId = UserController.instance.userId
                self.channelQuery = ChannelQuery(groupId: groupId!, channelId: channelId!, userId: userId!)
                self.channelQuery.observe(with: { channel in
                    self.channel = channel
                })
            }
        }
        if notify {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.ChannelDidChange), object: self, userInfo: nil)
        }
    }
}
