/*
 * Firebase controller
 *
 * Provide convenience functionality when interacting with the Firebase database.
 */

import UIKit
import Keys
import AFNetworking
import iRate
import Firebase
import FirebaseDatabase
import FirebaseAuth

class StateController: NSObject {

    static let instance = StateController()
    var handleAuth: AuthStateDidChangeListenerHandle!
    fileprivate(set) internal var channelId: String?
    fileprivate(set) internal var stateIntialized = false
    
    private override init() {
        super.init()
        Auth.auth().addStateDidChangeListener() { auth, user in
            if user == nil {
                if self.channelId != nil {
                    FireController.db.child("channel-members/\(self.channelId!)").keepSynced(false)
                }
            }
        }
    }

    /*--------------------------------------------------------------------------------------------
     * MARK: - Methods
     *--------------------------------------------------------------------------------------------*/

    func prepare() {

        let queue = TaskQueue()
        var channelQuery: ChannelQuery! // released when queue is released
        
        /* Init user */
        queue.tasks += { _, next in
            /* We wait until user is resolved */
            UserController.instance.prepare() { success in
                next(nil)
            }
        }
        
        /* Init state */
        queue.tasks += { [weak self] _, next in
            
            guard let this = self else { return }
            
            guard UserController.instance.authenticated else {
                next(nil)
                return
            }
            
            if let lastChannelId = UserDefaults.standard.string(forKey: PerUserKey(key: Prefs.lastChannelId)) {
                channelQuery = ChannelQuery(channelId: lastChannelId)
                channelQuery.once(with: { [weak this] error, channel in
                    guard let this = this else { return }
                    if error != nil || channel == nil { // Channel was deleted or user was kicked since we last used it
                        this.clearChannel()
                        next(nil)
                    }
                    else {
                        this.setChannelId(channelId: lastChannelId)
                        next(nil)
                    }
                })
            }
            else {
                next(nil)
            }
        }

        queue.tasks += { [weak self] in
            guard let this = self else { return }
            this.stateIntialized = true
            NotificationCenter.default.post(
                name: NSNotification.Name(rawValue: Events.StateInitialized),
                object: this, userInfo: nil)
        }
        
        queue.run()
    }
    
    func setChannelId(channelId: String?) {
        
        guard UserController.instance.userId != nil else {
            assertionFailure("userId and channelId must be set")
            return
        }
        
        guard channelId != self.channelId else {
            return
        }
        
        Log.d("Set current channel: \(channelId!)")
        
        FireController.db.child("channel-members/\(channelId!)").keepSynced(true)
        self.channelId = channelId!
        UserDefaults.standard.set(channelId, forKey: PerUserKey(key: Prefs.lastChannelId))
    }
    
    func clearChannel() {
        if self.channelId != nil {
            Log.d("Set current channel: nothing")
            self.channelId = nil
            UserDefaults.standard.set(nil, forKey: PerUserKey(key: Prefs.lastChannelId))
        }
    }
}
