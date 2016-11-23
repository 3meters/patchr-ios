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
        if userTitle == nil, let username = StateController.instance.group.username {
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
                if error == nil {
                    self.setUserId(userId: user.uid)
                }
                else {
                    /* User account could have been deleted */
                    try! FIRAuth.auth()!.signOut()
                    StateController.instance.clearGroup() // Also clears channel
                    Log.w((error?.localizedDescription)!)
                }
                then?(error == nil)
            })
        }
        else {
            then?(true)
        }
    }

    func setUserId(userId: String, next: ((Any?) -> Void)? = nil) {
        
        guard userId != self.userId else {
            next?(nil)
            return
        }
        
        Log.i("User logged in: \(userId)")
        
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
            next?(nil)
            
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
