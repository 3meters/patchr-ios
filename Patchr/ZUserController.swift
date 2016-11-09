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
import RxSwift

class ZUserController: NSObject {
    
    static let instance = ZUserController()

    let lockbox = Lockbox(keyPrefix: KEYCHAIN_GROUP)

    var currentUser: User!
    var userName: String?
    var userId: String?
    var sessionKey: String?

    private var jsonUser: String?
    private var jsonSession: String?
    
    var authenticated: Bool {
        return (self.userId != nil && self.sessionKey != nil)
    }

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    private override init() {
        super.init()

        let userDefaults = UserDefaults.standard
        self.userId = userDefaults.string(forKey: PatchrUserDefaultKey(subKey: "userId"))
        self.jsonUser = userDefaults.string(forKey: PatchrUserDefaultKey(subKey: "user"))
        self.jsonSession = self.lockbox?.unarchiveObject(forKey: "session") as? String
        self.sessionKey = self.lockbox?.unarchiveObject(forKey: "sessionKey") as? String        
    }

    /*--------------------------------------------------------------------------------------------
    * Credentials
    *--------------------------------------------------------------------------------------------*/

    func discardCredentials() {

        self.currentUser = nil
        self.userId = nil
        self.sessionKey = nil
        self.jsonUser = nil
        self.jsonSession = nil

        writeCredentialsToUserDefaults()
    }

    func handlePasswordChange(response: Any) {
        /*
         * Capture and update the session
         */
        let json = JSON(response)

        if let jsonString = json["session"].rawString() {
            self.jsonSession = jsonString
        }

        self.sessionKey = json["session"]["key"].string

        Log.i("User changed password: \(self.userName!) (\(self.userId!))")

        let success = self.lockbox?.archiveObject(self.sessionKey as NSSecureCoding!, forKey: "sessionKey", accessibility: kSecAttrAccessibleAfterFirstUnlock)
        if success! {
            self.lockbox?.archiveObject(self.jsonSession as NSSecureCoding!, forKey: "session", accessibility: kSecAttrAccessibleAfterFirstUnlock)
        }

        if !success! {
            Log.w("Failed to store session in keychain")
        }
        
    }

    func handleSuccessfulLoginResponse(response: Any) {
        /*
         * Called everytime we have a new authenticated user. The store can
         * contain entities that are missing state that is tied to the current
         * user so we need to clear it to get the correct contextual state.
         */
        let json = JSON(response)

        if let jsonString = json["user"].rawString() {
            self.jsonUser = jsonString
        }

        if let jsonString = json["session"].rawString() {
            self.jsonSession = jsonString
        }

        self.userName = json["user"]["name"].string
        self.userId = json["session"]["_owner"].string
        self.sessionKey = json["session"]["key"].string

        Log.i("User logged in: \(self.userName!) (\(self.userId!))")
        
        /* Activate install */
        NotificationController.instance.activateUser()

        writeCredentialsToUserDefaults()
        fetchCurrentUser() // Includes making sure the user is in the store

        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.UserDidLogin), object: nil)
    }

    private func writeCredentialsToUserDefaults() {

        let userDefaults = UserDefaults.standard

        userDefaults.set(self.jsonUser, forKey: PatchrUserDefaultKey(subKey: "user"))
        userDefaults.set(self.userId, forKey: PatchrUserDefaultKey(subKey: "userId"))

        /* This is only place where we push to the keychain */
        var success = false
        success = (self.lockbox?.archiveObject(self.sessionKey as NSSecureCoding!, forKey: "sessionKey", accessibility: kSecAttrAccessibleAfterFirstUnlock))!
        if success {
            self.lockbox?.archiveObject(self.jsonSession as NSSecureCoding!, forKey: "session", accessibility: kSecAttrAccessibleAfterFirstUnlock)
        }

        if !success {
            Log.w("Failed to store session in keychain")
        }

        if let groupDefaults = UserDefaults(suiteName: "group.com.3meters.patchr.ios") {
            groupDefaults.set(self.jsonUser, forKey: PatchrUserDefaultKey(subKey: "user"))
            groupDefaults.set(self.userId, forKey: PatchrUserDefaultKey(subKey: "userId"))
        }
    }

    func fetchCurrentUser() {
        DataController.instance.withEntityId(entityId: self.userId!, strategy: .UseCacheAndVerify, completion: { objectId, error in
            if error == nil && objectId != nil {
                let user = DataController.instance.mainContext.object(with: objectId!) as! User
                if user.id_ != nil {
                    self.initUserState(user: user)
                }
            }
        })
    }

    func clearUserState() {
        /*
        * Should be called when logging out or if for any reason do not have a valid user.
        */
        self.discardCredentials()
        self.clearStore()		// Clear the core data store and create new data stack, blocks until done
        LocationController.instance.clearLastLocationAccepted()  // Triggers fresh location processing
        Reporting.updateUser(user: nil)
    }

    func initUserState(user: User!) {
        self.currentUser = user
        self.userName = user.name
        self.userId = user.id_

        /* Need to seed these because sign-in with previous version might not have included them */
        if let groupDefaults = UserDefaults(suiteName: "group.com.3meters.patchr.ios") {
            groupDefaults.set(user.id_, forKey: PatchrUserDefaultKey(subKey: "userId"))
        }
    }

    func clearStore() {
        DataController.instance.reset()
    }
    
    func prepare() {}
    
    /*--------------------------------------------------------------------------------------------
     * Functions
     *--------------------------------------------------------------------------------------------*/
    

}
