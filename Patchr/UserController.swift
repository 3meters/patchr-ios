//
//  UserController.swift
//  Patchr
//
//  Created by Jay Massena on 5/11/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//
import Firebase
import FirebaseAuth

class UserController: NSObject {
    
    static let instance = UserController()

    fileprivate var queryUser: UserQuery?
    fileprivate var queryUnread: UnreadQuery?

    fileprivate(set) internal var userId: String?
    fileprivate(set) internal var user: FireUser?
    fileprivate(set) internal var unreads = 0

    fileprivate var refCounter: FIRDatabaseReference?
    fileprivate var handleCounter: UInt?

    var authenticated: Bool {
        return (self.userId != nil)
    }
    
    var userTitle: String? {
        var userTitle: String?
        if let profile = self.user?.profile, profile.fullName != nil {
            userTitle = profile.fullName
        }
        if userTitle == nil, let username = UserController.instance.user?.username {
            userTitle = username
        }
        if userTitle == nil, let username = self.user?.username {
            userTitle = username
        }
        if userTitle == nil, let displayName = FIRAuth.auth()?.currentUser?.displayName {
            userTitle = displayName
        }
        return userTitle
    }
    
    var userEmail: String? {
        var userEmail: String?
        if let email = UserController.instance.user?.email {
            userEmail = email
        }
        if userEmail == nil, let authEmail = FIRAuth.auth()?.currentUser?.email {
            userEmail = authEmail
        }
        return userEmail
    }

    private override init() {
    }

    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/

    func prepare(then: ((Bool) -> Void)? = nil) {
        
        FIRAuth.auth()?.addStateDidChangeListener() { auth, user in
            if user != nil {
                let userId = user!.uid
                FireController.db.child("unreads/\(userId)").keepSynced(true)
                FireController.db.child("member-groups/\(userId)").keepSynced(true)
                FireController.db.child("member-channels/\(userId)").keepSynced(true)
            }
            else if let userId = self.userId {
                FireController.db.child("unreads/\(userId)").keepSynced(false)
                FireController.db.child("member-groups/\(userId)").keepSynced(false)
                FireController.db.child("member-channels/\(userId)").keepSynced(false)
            }
        }
        
        if let user = FIRAuth.auth()?.currentUser {
            
            /* Verify user account */
            user.reload(completion: { error in
                if let error = error as? NSError {
                    Log.w(error.localizedDescription)
                    Log.w("error code: \(error.code)")
                    if let networkError = error.userInfo["NSUnderlyingError"] as? NSError {
                        /* Network error: code = -1009, domain = NSURLErrorDomain */
                        Log.w(networkError.localizedDescription)
                        Log.w("internal error code: \(networkError.code)")
                    }
                    /* Network error: code = 17020, domain = FIRAuthErrorDomain */
                    if error.code != 17020 {
                        /* User account could have been deleted */
                        try! FIRAuth.auth()!.signOut()
                        StateController.instance.clearGroup() // Also clears channel
                        return
                    }
                }
            })
            
            self.setUserId(userId: user.uid)
            then?(true)
        }
        else {
            then?(true)
        }
    }

    func setUserId(userId: String, then: ((Any?) -> Swift.Void)? = nil) {
        
        var calledBack = false
        
        if userId != self.userId {
            
            Log.i("User logged in: \(userId)")
            
            if let token = FIRInstanceID.instanceID().token() {
                Log.i("UserController: setting firebase messaging token: \(token)")
                FireController.db.child("installs/\(userId)/\(token)").setValue(true)
            }
            else {
                Log.w("No firebase messaging token - device not registered for remote notifications")
            }
            
            self.userId = userId
            Reporting.updateUser(user: FIRAuth.auth()?.currentUser)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.UserDidSwitch), object: nil, userInfo: nil)
            
            /* Per user defaults */
            if UserDefaults.standard.string(forKey: PerUserKey(key: Prefs.soundEffects)) == nil {
                UserDefaults.standard.setValue(true, forKey: PerUserKey(key: Prefs.soundEffects))
            }
            
            self.queryUser?.remove()
            self.queryUser = UserQuery(userId: userId, groupId: nil, trackPresence: true)
            self.queryUser!.observe(with: { error, user in
                
                guard user != nil && error == nil else {
                    assertionFailure("User not found, no longer exists or permission denied")
                    then?(nil)
                    return
                }
                
                if self.user != nil {
                    Log.d("User updated: \(user!.id!)")
                }
                
                self.user = user
                
                if !calledBack {
                    then?(nil)
                    calledBack = true
                }
                
            })
            
            self.refCounter = FireController.db.child("counters/\(userId)")
            self.handleCounter = self.refCounter!.observe(.value, with: { [weak self] snap in
                var count = 0
                if let unreads = snap.value as? [String: Any] {
                    count = unreads["unreads"] as! Int
                }
                self?.unreads = count
                UIApplication.shared.applicationIconBadgeNumber = count
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.UnreadChange), object: self, userInfo: nil)
            })
        }
        else {
            then?(nil)
            return
        }
    }

    func logout() {
        let userId = UserController.instance.userId!
        
        if let token = FIRInstanceID.instanceID().token() {
            Log.i("Removing messaging token for user: \(userId)")
            FireController.db.child("installs/\(userId)/\(token)").removeValue()
        }
        
        self.refCounter?.removeObserver(withHandle: self.handleCounter!)
        
        try! FIRAuth.auth()!.signOut()  // Triggers cleanup by canned queries
        
        Reporting.updateUser(user: nil)
        StateController.instance.clearGroup() // Also clears channel
        self.user = nil
        self.userId = nil
        
        MainController.instance.route() // Showing lobby also clears group and channel
        Reporting.track("Logged Out")
        Log.i("User logged out")
    }
}
