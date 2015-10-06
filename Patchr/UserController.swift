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
    var userName: String?
    private var jsonUser: String?
    private var jsonSession: String?

	private override init() {
		super.init()
        
		let userDefaults = NSUserDefaults.standardUserDefaults()

		self.userId = userDefaults.stringForKey(PatchrUserDefaultKey("userId"))
		self.sessionKey = userDefaults.stringForKey(PatchrUserDefaultKey("sessionKey")) // TODO: We should store this more securely
        self.jsonUser = userDefaults.stringForKey(PatchrUserDefaultKey("user"))
        self.jsonSession = userDefaults.stringForKey(PatchrUserDefaultKey("session"))
	}

	var authenticated: Bool {
		return (self.userId != nil && self.sessionKey != nil)
	}

	func discardCredentials() {
        self.userId = nil
        self.sessionKey = nil
		self.currentUser = nil
        self.jsonUser = nil
        self.jsonSession = nil
        writeCredentialsToUserDefaults()
        Reporting.updateCrashUser(nil)
        Branch.getInstance().logout()
    }

	func handleSuccessfulSignInResponse(response: AnyObject) {
        let json = JSON(response)
        if let jsonString = json["user"].rawString() {
            self.jsonUser = jsonString
            Log.d("User signed in:")
            Log.d(jsonUser!)
        }
        if let jsonString = json["session"].rawString() {
            self.jsonSession = jsonString
            Log.d(jsonSession!)
        }
        self.userName = json["user"]["name"].string
        self.userId = json["session"]["_owner"].string
        self.sessionKey = json["session"]["key"].string
        writeCredentialsToUserDefaults()
		fetchCurrentUser()
    }

	private func writeCredentialsToUserDefaults() {
        let userDefaults = NSUserDefaults.standardUserDefaults()

        userDefaults.setObject(self.jsonUser, forKey: PatchrUserDefaultKey("user"))
        userDefaults.setObject(self.jsonSession, forKey: PatchrUserDefaultKey("sesson"))
        userDefaults.setObject(self.userId, forKey: PatchrUserDefaultKey("userId"))
        userDefaults.setObject(self.sessionKey, forKey: PatchrUserDefaultKey("sessionKey"))
        
        if let groupDefaults = NSUserDefaults(suiteName: "group.com.3meters.patchr.ios") {
            groupDefaults.setObject(self.jsonUser, forKey: PatchrUserDefaultKey("user"))
            groupDefaults.setObject(self.jsonSession, forKey: PatchrUserDefaultKey("sesson"))
            groupDefaults.setObject(self.userId, forKey: PatchrUserDefaultKey("userId"))
            groupDefaults.setObject(self.sessionKey, forKey: PatchrUserDefaultKey("sessionKey"))
        }
    }

	func fetchCurrentUser(){
		DataController.instance.withUserId(self.userId!, refresh: true, completion: {
			user, error in
            self.currentUser = user
            Branch.getInstance().setIdentity(user!.id_)
            Reporting.updateCrashUser(user)
		})
	}
    
    func signinAuto() {
        /*
         * Gets called on app create.
         */
        if let userAsData = self.jsonUser?.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            
            let userAsJson = JSON(data: userAsData)
            let userAsMap: NSDictionary = userAsJson.dictionaryObject!
            
            let user: User = User.fetchOrInsertOneById(userAsJson["_id"].string, inManagedObjectContext: DataController.instance.managedObjectContext)
            User.setPropertiesFromDictionary(userAsMap as [NSObject : AnyObject], onObject: user, mappingNames: true)
            user.activityDate = NSDate(timeIntervalSince1970: 0) // Ensures that the user will be freshed from the service
            
            self.currentUser = user
            self.userName = user.name
            
            self.userId = NSUserDefaults.standardUserDefaults().stringForKey(PatchrUserDefaultKey("userId"))
            self.sessionKey = NSUserDefaults.standardUserDefaults().stringForKey(PatchrUserDefaultKey("sessionKey")) // TODO: We should store this more securely
            
            /* Need to seed these because sign-in with previous version might not have included them */
            if let groupDefaults = NSUserDefaults(suiteName: "group.com.3meters.patchr.ios") {
                groupDefaults.setObject(self.userId, forKey: PatchrUserDefaultKey("userId"))
                groupDefaults.setObject(self.sessionKey, forKey: PatchrUserDefaultKey("sessionKey"))
            }
            
            Branch.getInstance().setIdentity(user.id_)
            Reporting.updateCrashUser(user)
        }
    }
}
