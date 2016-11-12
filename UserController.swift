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

    fileprivate var userQuery: UserQuery!
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
        self.setUserId(userId: FIRAuth.auth()?.currentUser?.uid)
    }

    func logout() {
        /* Always switches to lobby. Caller should handle UI cleanup in viewWillDisappear() */
        try! FIRAuth.auth()!.signOut()
        Reporting.track("Logged Out")
        Log.i("User logged out")
        setUserId(userId: nil)  // Triggers userStateDidChange with is monitored by MainController
    }

    func setUserId(userId: String?) {

        if userId != nil {
            self.userId = userId
            self.userQuery = UserQuery(userId: userId!, trackPresence: true)
            self.userQuery.observe(with: { user in
                self.user = user
            })
            Reporting.updateUser(user: FIRAuth.auth()?.currentUser)
        }
        else {
            self.userId = nil
            if self.userQuery != nil {
                self.userQuery.remove()
            }
            self.userQuery = nil
            self.user = nil
            Reporting.updateUser(user: nil)
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.UserStateDidChange), object: nil, userInfo: nil)
    }
}
