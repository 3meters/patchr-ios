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
    private var jsonUser: String?
    private var jsonSession: String?

	private override init() {
		super.init()
        
		let userDefaults = NSUserDefaults.standardUserDefaults()

		userId = userDefaults.stringForKey(PatchrUserDefaultKey("userId"))
		sessionKey = userDefaults.stringForKey(PatchrUserDefaultKey("sessionKey")) // TODO: We should store this more securely
        jsonUser = userDefaults.stringForKey(PatchrUserDefaultKey("user"))
        jsonSession = userDefaults.stringForKey(PatchrUserDefaultKey("session"))
	}

	var authenticated: Bool {
		return (userId != nil && sessionKey != nil)
	}

	func discardCredentials() {
        userId = nil
        sessionKey = nil
		currentUser = nil
        jsonUser = nil
        jsonSession = nil
        writeCredentialsToUserDefaults()
    }

	func handleSuccessfulSignInResponse(response: AnyObject) {
        let json = JSON(response)
        if let jsonString = json["user"].rawString() {
            jsonUser = jsonString
            println("User signed in:")
            println(jsonUser)
        }
        if let jsonString = json["session"].rawString() {
            jsonSession = jsonString
            println(jsonSession)
        }
        userId = json["session"]["_owner"].string
        sessionKey = json["session"]["key"].string
        writeCredentialsToUserDefaults()
		fetchCurrentUser()
    }

	private func writeCredentialsToUserDefaults() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(jsonUser, forKey: PatchrUserDefaultKey("user"))
        userDefaults.setObject(jsonSession, forKey: PatchrUserDefaultKey("sesson"))
        userDefaults.setObject(userId, forKey: PatchrUserDefaultKey("userId"))
        userDefaults.setObject(sessionKey, forKey: PatchrUserDefaultKey("sessionKey"))
    }

	func fetchCurrentUser(){
		DataController.instance.withUserId(userId!, refresh: true, completion: {
			user in
            self.currentUser = user
		})
	}
    
    func signinAuto() {
        /*
         * Gets called on app create.
         */
        if let dataFromString = jsonUser?.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            let jsonUser = JSON(data: dataFromString)
            let userMap: NSDictionary = jsonUser.dictionaryObject!
            var user: User = User.fetchOrInsertOneById(jsonUser["_id"].string, inManagedObjectContext: DataController.instance.managedObjectContext)
            User.setPropertiesFromDictionary(userMap as [NSObject : AnyObject], onObject: user, mappingNames: true)
            user.activityDate = NSDate(timeIntervalSince1970: 0) // Ensures that the user will be freshed from the service
            self.currentUser = user
        }
    }
}
