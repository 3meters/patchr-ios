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
            
            if let lastChannelId = UserDefaults.standard.string(forKey: PerUserKey(key: Prefs.lastChannelId)),
                let userId = UserController.instance.userId {
                channelQuery = ChannelQuery(channelId: lastChannelId, userId: userId)
                channelQuery.once(with: { [weak this] error, channel in
                    guard let this = this else { return }
                    if channel == nil {
                        this.clearChannel()
                        next(nil)
                    }
                    else {
                        this.setChannelId(channelId: lastChannelId) { error in
                            next(nil)
                        }
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
    
    func setChannelId(channelId: String?, bundle: [String: Any]? = nil, next: ((Error?) -> Void)? = nil) {
        
        guard UserController.instance.userId != nil else {
            assertionFailure("userId and channelId must be set")
            return
        }
        
        guard channelId != self.channelId else {
            next?(nil)
            return
        }
        
        Log.d("Current channel: \(channelId!)")
        
        FireController.db.child("channel-members/\(channelId!)").keepSynced(true)
        self.channelId = channelId!
        UserDefaults.standard.set(channelId, forKey: PerUserKey(key: Prefs.lastChannelId))
        
        next?(nil)
    }
    
    func clearChannel() {
        Log.d("Current channel: nothing")
        self.channelId = nil
        UserDefaults.standard.set(nil, forKey: PerUserKey(key: Prefs.lastChannelId))
    }
}
