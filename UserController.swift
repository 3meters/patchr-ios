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

    private override init() { }

    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/

    func prepare() {
        if let userId = FIRAuth.auth()?.currentUser?.uid {
            self.setUserId(userId: userId)
        }
    }

    func logout() {
        try! FIRAuth.auth()!.signOut()
        clearUser()
        Reporting.track("Logged Out")
        Log.i("User logged out")
        StateController.instance.clearGroup() // Also clears channel
        MainController.instance.showLobby()
    }
    
    func clearUser() {
        self.userQuery?.remove()
        self.userQuery = nil
        self.userId = nil
        self.user = nil
        Reporting.updateUser(user: nil)
    }

    func setUserId(userId: String, next: ((Any?) -> Void)? = nil) {
        
        guard userId != self.userId else { return }

        Log.i("User logged in: \(userId)")
        
        self.userId = userId
        self.userQuery?.remove()
        self.userQuery = UserQuery(userId: userId, trackPresence: true)
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
}
