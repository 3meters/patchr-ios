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

class FacebookProvider: NSObject, ServiceProvider, FBSDKAppInviteDialogDelegate {
	
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
	
	func invite(entity: Entity) {
		
		if FBSDKAccessToken.currentAccessToken() != nil {
			let inviteDialog = FBSDKAppInviteDialog()
			if inviteDialog.canShow() {
				/*
				* FIXME: SECURITY HOLE: Temporary for testing!
				* The correct way to handle this is to have the service hold the secret, call
				* facebook to get a long lived app access token, and pass it back to the client.
				*/
				let inviterName = UserController.instance.currentUser.name.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
				let tokenString = PatchrKeys().facebookToken() // app_id|app_secret
				let deepLink = "patchr-ios://invite?entityId=\(entity.id_)&entitySchema=patch&inviterName=\(inviterName)"
				let ios = "[{\"app_name\":\"Patchr\", \"app_store_id\":929750075, \"url\":\"\(deepLink)\"}]"
				let parameters = [
					"name": "Patchr App Link",
					"ios": ios
				]
				
				FBSDKSettings.setLoggingBehavior(Set(arrayLiteral: FBSDKLoggingBehaviorGraphAPIDebugInfo))
				
				let request = FBSDKGraphRequest(graphPath: "app/app_link_hosts",
					parameters: parameters as [NSObject : AnyObject], tokenString: tokenString, version: "v2.5", HTTPMethod: "POST" )
				
				request.startWithCompletionHandler { connection, result, error in
					if (error != nil) {
						Log.d("Facebook error while creating applink")
					}
					else {
						let applinkUrl = "https://fb.me/\(result["id"])"
						let photo = entity.getPhotoManaged()
						let titleEncoded = entity.name.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
						let settings = "w=1200&h=628&crop&fit=crop&q=25&txtsize=96&txtalign=left,bottom&txtcolor=fff&txtshad=5&txtpad=60&txtfont=Helvetica%20Neue%20Light"
						let photoUrl = "https://3meters-images.imgix.net/\(photo.prefix)?\(settings)&txt=\(titleEncoded)"
						
						let invite = FBSDKAppInviteContent()
						invite.appLinkURL = NSURL(string: applinkUrl)
						invite.previewImageURL = NSURL(string: photoUrl)
						inviteDialog.content = invite
						inviteDialog.delegate = self
						inviteDialog.show()
					}
				}
			}
		}
	}
	
	func appInviteDialog(appInviteDialog: FBSDKAppInviteDialog!, didCompleteWithResults results: [NSObject : AnyObject]!) {
		if results != nil && results["completionGesture"] as? String != "cancel" {
			Shared.Toast("Patch invitations sent using Facebook!")
		}
	}
	
	func appInviteDialog(appInviteDialog: FBSDKAppInviteDialog!, didFailWithError error: NSError!) {
		Log.i("Facebook invite error: \(error)")
	}
}