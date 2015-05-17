//
//  UserController.swift
//  Patchr
//
//  Created by Jay Massena on 5/11/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

class UserController: NSObject {

	static let instance = UserController()

	var currentUser: User!
	var userId:      String?
	var sessionKey:  String?

	private override init() {
		super.init()
        
		let userDefaults = NSUserDefaults.standardUserDefaults()

		userId = userDefaults.stringForKey(PatchrUserDefaultKey("userId"))
		sessionKey = userDefaults.stringForKey(PatchrUserDefaultKey("sessionKey")) // TODO: We should store this more securely
	}

	var authenticated: Bool {
		return (userId != nil && sessionKey != nil)
	}

	func discardCredentials() {
        userId = nil
        sessionKey = nil
		currentUser = nil
        writeCredentialsToUserDefaults()
    }

	func handleSuccessfulSignInResponse(response: AnyObject) {
        let json = JSON(response)
        userId = json["session"]["_owner"].string
        sessionKey = json["session"]["key"].string
        writeCredentialsToUserDefaults()
		fetchCurrentUser()
    }

	func writeCredentialsToUserDefaults() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(userId, forKey: PatchrUserDefaultKey("userId"))
        userDefaults.setObject(sessionKey, forKey: PatchrUserDefaultKey("sessionKey"))
    }

	func fetchCurrentUser(){
		DataController.instance.withUserId(userId!, refresh: true, completion: {
			user in
			self.currentUser = user
		})
	}
}
