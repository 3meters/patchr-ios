//
//  UserController.swift
//  Patchr
//
//  Created by Jay Massena on 5/11/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import FBSDKLoginKit
import FBSDKShareKit
import Keys

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

class FacebookProvider: NSObject, FBSDKAppInviteDialogDelegate {	
	/*
	* Facebook access token is managed by the facebook sdk and is stored
	* in the device keychain. The facebook user id is available using token.userID.
	*/
	let permissions = ["public_profile", "email"]
	let controller: UIViewController
	
	private var _loginManager: FBSDKLoginManager?
	
	var loginManager: FBSDKLoginManager {
		get {
			if _loginManager == nil {
				_loginManager = FBSDKLoginManager()
				_loginManager?.logOut()
			}
			return _loginManager!
		}
	}
	
	init(controller: UIViewController) {
		self.controller = controller
	}
	
	func authorize(completion: CompletionBlock?) {
		/*
		 * This will both authorize the some or all of the specified permissions
		 * and log the user into Facebook if not already.
		 */
		self.loginManager.loginBehavior = FBSDKLoginBehavior.Native
		self.loginManager.logInWithReadPermissions(self.permissions, fromViewController: nil) {
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
		/*
		 * Facebook app invites do not require a currentAccessToken.
		 */
		Log.d("Show facebook invite dialog", breadcrumb: true)
		
		let patchNameEncoded = Utils.encodeForUrlQuery(entity.name)
		var patchPhotoUrl : String?
		let referrerNameEncoded = Utils.encodeForUrlQuery(UserController.instance.currentUser.name)
		var referrerPhotoUrl = ""
		
		if let photo = UserController.instance.currentUser.photo {
			let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!, category: SizeCategory.profile)
			let photoUriEncoded = Utils.encodeForUrlQuery(photoUrl.absoluteString)
			referrerPhotoUrl = "&referrerPhotoUrl=\(photoUriEncoded)"
		}
		
		let queryString = "entityId=\(entity.id_)&entitySchema=patch&referrerName=\(referrerNameEncoded)\(referrerPhotoUrl)"
		let applink = "https://fb.me/934234473291708?\(queryString)"
		
		FBSDKSettings.setLoggingBehavior(Set(arrayLiteral: FBSDKLoggingBehaviorGraphAPIDebugInfo, FBSDKLoggingBehaviorDeveloperErrors))
		
		if let photo = entity.photo {
			let settings = "w=1200&h=628&crop&fit=crop&q=25&txtsize=96&txtalign=left,bottom&txtcolor=fff&txtshad=5&txtpad=60&txtfont=Helvetica%20Neue%20Light"
			patchPhotoUrl = "https://3meters-images.imgix.net/\(photo.prefix)?\(settings)&txt=\(patchNameEncoded)"
		}
		
		FBSDKAppInviteDialog.initialize()
		
		let content = FBSDKAppInviteContent()
		content.appLinkURL = NSURL(string: applink)
		if patchPhotoUrl != nil {
			content.appInvitePreviewImageURL = NSURL(string: patchPhotoUrl!)
		}
		
		FBSDKAppInviteDialog.showFromViewController(self.controller, withContent: content, delegate: self)
	}
	
	func appInviteDialog(appInviteDialog: FBSDKAppInviteDialog!, didCompleteWithResults results: [NSObject : AnyObject]!) {
		if results != nil && results["completionGesture"] as? String != "cancel" {
			let referrerId = UserController.instance.currentUser.id_!
			FBSDKAppEvents.logEvent("patch_invite", parameters: ["referrer":referrerId])
			Reporting.track("Sent Patch Invitation", properties: ["network": "Facebook"])
			Log.d("Patch invitations sent using facebook")
			UIShared.Toast("Patch invitations sent using Facebook!", controller: self.controller)
			if NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("SoundEffects")) {
				AudioController.instance.play(Sound.pop.rawValue)
			}
		}
	}
	
	func appInviteDialog(appInviteDialog: FBSDKAppInviteDialog!, didFailWithError error: NSError!) {
		Log.i("Facebook invite error: \(error)")
	}
}