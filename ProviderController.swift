//
//  UserController.swift
//  Patchr
//
//  Created by Jay Massena on 5/11/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

protocol ServiceProvider: NSObjectProtocol {
	func authorize(completion: CompletionBlock?) -> Void
	func profile(completion: CompletionBlock?) -> Void
	func deauthorize(completion: CompletionBlock?) -> Void
	func logout() -> Void
}

class ServiceUserProfile: NSObject {
	var name: String?
	var email: String?
	var phone: String?
	var userId: String?
	var photoUrl: NSURL?
	var photoSource: String?
	
	convenience init(name: String?, email: String?, phone: String?, userId: String, photoUrl: NSURL?, photoSource: String?) {
		self.init()
		self.name = name
		self.email = email
		self.phone = phone
		self.userId = userId
		self.photoUrl = photoUrl
		self.photoSource = photoSource
	}
}

public typealias CompletionBlock = (response:AnyObject?, error:NSError?) -> Void

class FacebookProvider: NSObject, ServiceProvider {
	
	let permissions = ["public_profile", "email", "user_friends"]
	
	private var _loginManager: FBSDKLoginManager?
	
	var loginManager: FBSDKLoginManager {
		get {
			if _loginManager == nil {
				_loginManager = FBSDKLoginManager()
			}
			return _loginManager!
		}
	}
	
	func authorize(completion: CompletionBlock?) {
		/*
		 * This will both authorize the some or all of the specified permissions
		 * and log the user into Facebook if not already.
		 */
		self.loginManager.loginBehavior = FBSDKLoginBehavior.Native
		self.loginManager.logInWithReadPermissions(self.permissions) {
			result, error in
			completion?(response: result, error: error)
		}
	}
	
	func profile(completion: CompletionBlock?) {
		
		if FBSDKAccessToken.currentAccessToken() == nil {
			completion?(response: nil, error: nil)
		}
		/*
		 * This could be replaced by using FBSDKProfile.
		 */
		let fields = ["fields": "id,name,email,picture.type(large)"]
		let request = FBSDKGraphRequest(graphPath: "me", parameters: fields)
		
		request.startWithCompletionHandler{
			connection, result, error in
			
			if (error != nil) {
				completion?(response: nil, error: error)
			}
			else {
				let dict = result as! NSDictionary
				let profile = ServiceUserProfile()
				
				profile.name = (dict["name"] as! String)
				profile.email = (dict["email"] as! String)
				profile.userId = (dict["id"] as! String)
				profile.photoUrl = NSURL(string: (dict.objectForKey("picture")?.objectForKey("data")?.objectForKey("url") as! String))
				
				completion?(response: profile, error: nil)
			}
		}
	}
	
	func deauthorize(completion: CompletionBlock?) {
		/*
		 * This removes the permission authorizations created in graph by our
		 * authorize call. The user remains logged into Facebook.
		 */
		if FBSDKAccessToken.currentAccessToken() != nil {
			let tokenString = FBSDKAccessToken.currentAccessToken().tokenString
			let request = FBSDKGraphRequest(graphPath: "me/permissions",
				parameters: nil, tokenString: tokenString, version: nil, HTTPMethod: "DELETE" )
			
			request.startWithCompletionHandler { connection, result, error in
				
				if (error != nil) {
					Log.d("Facebook error while deauthorizing")
				}
				else {
					self._loginManager = nil
					FBSDKAccessToken.setCurrentAccessToken(nil)
					FBSDKProfile.setCurrentProfile(nil)
					completion?(response: result, error: error)
				}
			}
		}
	}
	
	func logout() {
		/*
		 * Because we are using SSO, this will log the user out of facebook 
		 * for all applications on the device.
		 */
		if FBSDKAccessToken.currentAccessToken() != nil {
			self.loginManager.logOut()
			self._loginManager = nil
		}
	}
}