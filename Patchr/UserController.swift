//
//  UserController.swift
//  Patchr
//
//  Created by Jay Massena on 5/11/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

class UserController: NSObject {
	/*
	 * Facebook access token is managed by the facebook sdk and is stored
	 * in the device keychain. The facebook user id is available using token.userID.
	 */
	static let instance = UserController()

	let facebookReadPermissions = ["public_profile", "email", "user_friends"]
	
	var currentUser: User!
	var userName: String?
	
	var userId: String?
	var sessionKey: String?
	
    private var jsonUser: String?
    private var jsonSession: String?

	private override init() {
		super.init()
        
		let userDefaults = NSUserDefaults.standardUserDefaults()

		self.userId = userDefaults.stringForKey(PatchrUserDefaultKey("userId"))
        self.jsonUser = userDefaults.stringForKey(PatchrUserDefaultKey("user"))
		
        self.jsonSession = Lockbox.stringForKey("session") as String?
		self.sessionKey = Lockbox.stringForKey("sessionKey") as String?
	}

	var authenticated: Bool {
		return (self.userId != nil && self.sessionKey != nil)
	}

	func discardCredentials() {
		
        self.userId = nil
		self.currentUser = nil
        self.jsonUser = nil
		
        self.jsonSession = nil
		self.sessionKey = nil
		
		if FBSDKAccessToken.currentAccessToken() != nil {
			FBSDKLoginManager().logOut()
		}
		
        writeCredentialsToUserDefaults()
		clearStore()
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
		fetchCurrentUser()	// Includes making sure the user is in the store
    }
	
	func clearStore() {
		DataController.instance.reset()
	}

	private func writeCredentialsToUserDefaults() {
		
        let userDefaults = NSUserDefaults.standardUserDefaults()

        userDefaults.setObject(self.jsonUser, forKey: PatchrUserDefaultKey("user"))
        userDefaults.setObject(self.userId, forKey: PatchrUserDefaultKey("userId"))
		
		Lockbox.setString(self.sessionKey, forKey: "sessionKey")
		Lockbox.setString(self.jsonSession, forKey: "session")
		
        if let groupDefaults = NSUserDefaults(suiteName: "group.com.3meters.patchr.ios") {
            groupDefaults.setObject(self.jsonUser, forKey: PatchrUserDefaultKey("user"))
            groupDefaults.setObject(self.userId, forKey: PatchrUserDefaultKey("userId"))
        }
    }

	func fetchCurrentUser(){
		DataController.instance.withUserId(self.userId!, refresh: true, completion: {
			objectId, error in
			if objectId != nil {
				self.currentUser = DataController.instance.mainContext.objectWithID(objectId!) as! User
				Branch.getInstance().setIdentity(self.currentUser.id_)
				Reporting.updateCrashUser(self.currentUser)
			}
		})
	}
	
    func signinAuto() {
        /*
         * Gets called on app create.
         */
        if let userAsData = self.jsonUser?.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            
            let userAsJson = JSON(data: userAsData)
            let userAsMap: NSDictionary = userAsJson.dictionaryObject!
            
            let user: User = User.fetchOrInsertOneById(userAsJson["_id"].string, inManagedObjectContext: DataController.instance.mainContext)
            User.setPropertiesFromDictionary(userAsMap as [NSObject : AnyObject], onObject: user)
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
	
	func signout() {
		/*
		 * Always switches to lobby. Caller should handle UI cleanup in viewWillDisappear()
		 */
		DataController.proxibase.signout {
			response, error in
			
			NSOperationQueue.mainQueue().addOperationWithBlock {	// In case we are not called back on main thread
				
				if error != nil {
					Log.w("Error during logout \(error)")
				}
				
				/* Clear local credentials */
				self.discardCredentials()
				
				/* Make sure state is cleared */
				LocationController.instance.clearLastLocationAccepted()
				
				let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
				let destinationViewController = UIStoryboard(name: "Lobby", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("LobbyNavigationController")
				appDelegate.window!.setRootViewController(destinationViewController, animated: true)
			}
		}
	}
	
	func facebookConnect(completion: (response: AnyObject?, error: NSError?) -> Void) {
		
		FBSDKLoginManager().loginBehavior = FBSDKLoginBehavior.SystemAccount
		FBSDKLoginManager().logInWithReadPermissions(self.facebookReadPermissions, fromViewController: nil) {
			result, error in
			
			if error != nil {
				completion(response: nil, error: error)
			}
			else {
				completion(response: result, error: nil)
			}
		}
	}
}
