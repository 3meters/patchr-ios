//
//  UserController.swift
//  Patchr
//
//  Created by Jay Massena on 5/11/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//
import AdSupport
import Lockbox
import Branch
import Firebase
import FirebaseAuth
import FirebaseDatabase
import RxSwift

class UserController: NSObject {
    
    static let instance = UserController()

    let db = FIRDatabase.database().reference()
    var onlineRef: FIRDatabaseReference!
    var userRef: FIRDatabaseReference!

    fileprivate(set) internal var userId: String?

    var authenticated: Bool {
        return (self.userId != nil)
    }

    private override init() { }

    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/

    func prepare() {
        self.onlineRef = self.db.child(".info/connected")
        self.setUserId(userId: FIRAuth.auth()?.currentUser?.uid)
    }

    func logout() {
        /* Always switches to lobby. Caller should handle UI cleanup in viewWillDisappear() */
        try! FIRAuth.auth()!.signOut()
        Reporting.track("Logged Out")
        Log.i("User logged out")
        setUserId(userId: nil)
        MainController.instance.route()
    }

    func setUserId(userId: String?) {

        if userId != nil {
            self.userId = userId
            self.userRef = self.db.child("users/\(userId!)")
            Reporting.updateUser(user: FIRAuth.auth()?.currentUser)
            self.onlineRef.observe(.value, with: { snap in
                if !(snap.value is NSNull) {
                    self.userRef.onDisconnectUpdateChildValues(["presence": FIRServerValue.timestamp()])
                    self.userRef.updateChildValues(["presence": true])
                }
            })
        }
        else {
            self.userRef = nil
            self.userId = nil
            Reporting.updateUser(user: nil)
        }
    }
}
