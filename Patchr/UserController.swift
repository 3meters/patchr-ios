//
//  UserController.swift
//  Patchr
//
//  Created by Jay Massena on 5/11/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//
import Parse
import AdSupport
import Lockbox
import Branch

class UserController: NSObject {
	
	static let instance = UserController()

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
	
	var installId: String {
		/* 
		 * Unlike the identifierForVendor property of the UIDevice, when using advertisingIdentifier, 
		 * the same value is returned to all vendors. This identifier may change—for example, if 
		 * the user erases the device—so you should not cache it.
		 *
		 * Value can be nil if device has been restarted but device is still locked. The value 
		 * changes if user resets the device or manually resets the advertising identifier in 
		 * settings.
		 */
		return ASIdentifierManager.sharedManager().advertisingIdentifier.UUIDString
	}

	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/

	private override init() {
		super.init()
		
		let userDefaults = NSUserDefaults.standardUserDefaults()
		self.userId = userDefaults.stringForKey(PatchrUserDefaultKey("userId"))
		self.jsonUser = userDefaults.stringForKey(PatchrUserDefaultKey("user"))
		self.jsonSession = self.lockbox.stringForKey("session") as String?
		self.sessionKey = self.lockbox.stringForKey("sessionKey") as String?
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
        Reporting.updateCrashUser(nil)
        Branch.getInstance().logout()
    }

	func handleSuccessfulSignInResponse(response: AnyObject) {
		
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
		
		Log.d("User signed in: \(self.userName!)(\(self.userId!))")
		
		writeCredentialsToUserDefaults()
		fetchCurrentUser(nil)	// Includes making sure the user is in the store
    }
	
	func clearStore() {
		DataController.instance.reset()
	}

	private func writeCredentialsToUserDefaults() {
		
        let userDefaults = NSUserDefaults.standardUserDefaults()

        userDefaults.setObject(self.jsonUser, forKey: PatchrUserDefaultKey("user"))
        userDefaults.setObject(self.userId, forKey: PatchrUserDefaultKey("userId"))
		
		/* This is only place where we push to the keychain */
		self.lockbox.setString((self.sessionKey != nil ? self.sessionKey! : nil), forKey: "sessionKey", accessibility: kSecAttrAccessibleAfterFirstUnlock)
		self.lockbox.setString((self.jsonSession != nil ? self.jsonSession! : nil), forKey: "session", accessibility: kSecAttrAccessibleAfterFirstUnlock)
		
        if let groupDefaults = NSUserDefaults(suiteName: "group.com.3meters.patchr.ios") {
            groupDefaults.setObject(self.jsonUser, forKey: PatchrUserDefaultKey("user"))
            groupDefaults.setObject(self.userId, forKey: PatchrUserDefaultKey("userId"))
        }
    }

	func fetchCurrentUser(completion: CompletionBlock?) {
		DataController.instance.withEntityId(self.userId!, strategy: .UseCacheAndVerify, completion: {
			objectId, error in
			if error == nil && objectId != nil {
				self.currentUser = DataController.instance.mainContext.objectWithID(objectId!) as! User
				Branch.getInstance().setIdentity(self.currentUser.id_)
				Reporting.updateCrashUser(self.currentUser)
			}
			if completion != nil {
				completion!(response: self.currentUser, error: error)
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
			
            /* Need to seed these because sign-in with previous version might not have included them */
            if let groupDefaults = NSUserDefaults(suiteName: "group.com.3meters.patchr.ios") {
                groupDefaults.setObject(self.userId, forKey: PatchrUserDefaultKey("userId"))
            }
            
            Branch.getInstance().setIdentity(user.id_)
            Reporting.updateCrashUser(user)
        }
    }
	
	func signout() {
		/*
		 * Always switches to lobby. Caller should handle UI cleanup in viewWillDisappear()
		 */
		DataController.proxibase.logout {
			response, error in
			
			NSOperationQueue.mainQueue().addOperationWithBlock {	// In case we are not called back on main thread
				
				if error != nil {
					Log.w("Error during logout \(error)")
				}
				
				/* Clear local credentials */
				self.discardCredentials()
				
				/* Clear the core data store and create new data stack, blocks until done */
				self.clearStore()
				
				/* Make sure state is cleared */
				LocationController.instance.clearLastLocationAccepted()
				
				if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
					let navController = UINavigationController()
					navController.viewControllers = [LobbyViewController()]
					appDelegate.window!.setRootViewController(navController, animated: true)
				}
			}
		}
	}
	
	func showGuestGuard(var controller: UIViewController?, message: String?) {
		let guestController = GuestViewController()
		guestController.inputMessage = message
		guestController.modalPresentationStyle = .OverFullScreen
		if controller == nil {
			controller = UIViewController.topMostViewController()!
		}
		controller!.presentViewController(guestController, animated: true, completion: nil)
	}
	
	/*--------------------------------------------------------------------------------------------
	* Installations
	*--------------------------------------------------------------------------------------------*/
	
	func registerInstall() {
		DataController.proxibase.registerInstall() {
			response, error in
			NSOperationQueue.mainQueue().addOperationWithBlock {
				if let error = ServerError(error) {
					Log.w("Error during registerInstall: \(error)")
				}
				else {
					Log.i("Install registered or updated: \(UserController.instance.installId)")
					if let serviceData = DataController.instance.dataWrapperForResponse(response!) {
						if !UIShared.versionIsValid(Int(serviceData.minBuildValue)) {
							UIShared.compatibilityUpgrade()
							return
						}
					}
				}
			}
		}
	}
}
