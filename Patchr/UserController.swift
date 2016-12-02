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

    fileprivate var userQuery: UserQuery?
    fileprivate(set) internal var userId: String?
    fileprivate(set) internal var user: FireUser?

    var authenticated: Bool {
        return (self.userId != nil)
    }
    
    var userTitle: String? {
        var userTitle: String?
        if let profile = self.user?.profile, profile.fullName != nil {
            userTitle = profile.fullName
        }
        if userTitle == nil, let username = StateController.instance.group?.username {
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

    private override init() { }

    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/

    func prepare(then: ((Bool) -> Void)? = nil) {
        if let user = FIRAuth.auth()?.currentUser {
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
                        then?(false)
                        return
                    }
                }
                self.setUserId(userId: user.uid)
                then?(error == nil)
            })
        }
        else {
            then?(true)
        }
    }

    func setUserId(userId: String, next: ((Any?) -> Void)? = nil) {
        
        var calledBack = false
        
        guard userId != self.userId else {
            next?(nil)
            return
        }
        
        Log.i("User logged in: \(userId)")
        
        if let token = FIRInstanceID.instanceID().token() {
            FireController.db.child("installs/\(userId)/\(token)").setValue(true)
        }
        
        self.userId = userId
        self.userQuery?.remove()
        self.userQuery = UserQuery(userId: userId, groupId: nil, trackPresence: true)
        self.userQuery!.observe(with: { user in
            
            guard user != nil else {
                assertionFailure("user not found or no longer exists")
                return
            }
            
            if self.user != nil {
                Log.d("User updated: \(user!.id!)")
            }
            
            self.user = user
            
            if !calledBack {
                next?(nil)
                calledBack = true
            }
            
            Reporting.updateUser(user: FIRAuth.auth()?.currentUser)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.UserStateDidChange), object: nil, userInfo: nil)
        })
    }

    func logout() {
        try! FIRAuth.auth()!.signOut()
        clearUser()
        StateController.instance.clearGroup() // Also clears channel
        MainController.instance.route()
        Reporting.track("Logged Out")
        Log.i("User logged out")
    }
    
    func clearUser() {
        self.userQuery?.remove()
        self.userQuery = nil
        self.userId = nil
        self.user = nil
        UserDefaults.standard.removeObject(forKey: PatchrUserDefaultKey(subKey: "userEmail"))
        Reporting.updateUser(user: nil)
    }
}
