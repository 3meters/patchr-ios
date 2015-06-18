//
//  ProxibaseAPI.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-20.
//  Copyright (c) 2015 3meters. All rights reserved.
//

/*  The Proxibase class is a singleton which mediates interaction with the Patchr server.
 *
 *  It uses and manages the following user default values:
 *      com.3meters.patchr.ios.serverURI  - Server URI
 *                            .userId     - The signed-in user's user id
 *                            .sessionKey - The current session key
 *
 * • The userId and sessionKey are sent in API requests to authorize the request.
 *
 */

import Foundation
import CoreLocation
import Darwin
import AVFoundation

/*
 * Access control is set to public because that is the only way that
 * unit tests can use this class.
 */

public class Proxibase {
    
	public typealias ProxibaseCompletionBlock = (response:AnyObject?, error:NSError?) -> Void
	public typealias S3UploadCompletionBlock = (/*result*/AnyObject?, NSError?) -> Void

	public let StagingURI    = "https://api.aircandi.com:8443/v1/"
	public let ProductionURI = "https://api.aircandi.com/v1/"

	private let PatchrS3Key    = "AKIAIYU2FPHC2AOUG3CA"
	private let PatchrS3Secret = "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"
    
    let pageSizeDefault: Int = 20
    let pageSizeNearby: Int = 50
    let pageSizeExplore: Int = 20
    let pageSizeNotifications: Int = 20

	let bucketInfo: [S3Bucket:(name:String, source:String)] = [
			.Users: ("aircandi-users", "aircandi.users"),
			.Images: ("aircandi-images", "aircandi.images")]

	private let sessionManager: AFHTTPSessionManager

	private var cachedInstallationIdentifier: String?

	public var installationIdentifier: String {
		if cachedInstallationIdentifier == nil {
			let installationIdentifierKey    = "installationIdentifier"
			var storedInstallationIdentifier = Lockbox.stringForKey(installationIdentifierKey) as String?

			if storedInstallationIdentifier == nil {
				storedInstallationIdentifier = NSUUID().UUIDString
				Lockbox.setString(storedInstallationIdentifier, forKey: installationIdentifierKey)
			}

			cachedInstallationIdentifier = storedInstallationIdentifier
		}
		return cachedInstallationIdentifier!
	}

	required public init() {
		let userDefaults = NSUserDefaults.standardUserDefaults()
        
		var serverURI = userDefaults.stringForKey(PatchrUserDefaultKey("serverURI"))

		if serverURI == nil {
			serverURI = ProductionURI
			userDefaults.setObject(serverURI, forKey: PatchrUserDefaultKey("serverURI"))
		}

		sessionManager = AFHTTPSessionManager(baseURL: NSURL(string: serverURI!))
		sessionManager.requestSerializer = AFJSONRequestSerializer(writingOptions: nil)
		sessionManager.responseSerializer = JSONResponseSerializerWithData()
	}

	/*--------------------------------------------------------------------------------------------
	 * PUBLIC: Fetch one
	 *--------------------------------------------------------------------------------------------*/

    public func fetchPatchById(entityId: String, criteria: [String:AnyObject], completion: ProxibaseCompletionBlock) {
        
        var parameters: [String:AnyObject] = [:]
        Patch.extras(&parameters)
        if !criteria.isEmpty {
            parameters["query"] = criteria
        }
		performPOSTRequestFor("find/patches/\(entityId)", parameters: parameters, completion: completion)
	}

	public func fetchMessageById(messageId: String, criteria: [String:AnyObject], completion: ProxibaseCompletionBlock) {
        
        var parameters: [String:AnyObject] = [:]
        Message.extras(&parameters)
        if !criteria.isEmpty {
            parameters["query"] = criteria
        }
		performPOSTRequestFor("find/messages/\(messageId)", parameters: parameters, completion: completion)
	}

	public func fetchUserById(userId: String, criteria: [String:AnyObject], completion: ProxibaseCompletionBlock) {
        
        var parameters: [String:AnyObject] = [:]
        User.extras(&parameters)
        if !criteria.isEmpty {
            parameters["query"] = criteria
        }
		performPOSTRequestFor("find/users/\(userId)", parameters: parameters, completion: completion)
	}

    public func fetchPlaceById(id: String, criteria: [String:AnyObject], completion: ProxibaseCompletionBlock) {
        
        var parameters: [String:AnyObject] = [:]
        Place.extras(&parameters)
        if !criteria.isEmpty {
            parameters["query"] = criteria
        }
        performPOSTRequestFor("find/places/\(id)", parameters: parameters, completion: completion)
    }
    
    public func fetchLinkFromId(fromID: String, toID: String, linkType: LinkType, completion: ProxibaseCompletionBlock) {
        /*
        * Currently only used to get the state of the current user watching or liking a patch.
        * TODO: Can probably make this part of the patch fetch.
        */
        let query: NSDictionary	= ["query": ["_from": fromID, "_to": toID, "type": linkType.rawValue]]
        performGETRequestFor("find/links", parameters: query, completion: completion)
    }
    
    /*--------------------------------------------------------------------------------------------
    * PUBLIC: Fetch collection
    *--------------------------------------------------------------------------------------------*/
    
	public func fetchNearbyPatches(location: CLLocationCoordinate2D?, radius: UInt = 10000, skip: Int = 0, completion: ProxibaseCompletionBlock) {

		if let loc = location as CLLocationCoordinate2D! {
            var parameters: [String:AnyObject] = [
                "location": [
                    "lat": loc.latitude,
                    "lng": loc.longitude
                ],
                "radius": radius,
                "limit": pageSizeNearby,
                "skip": skip,
                "more": false,
                "rest": true,
            ]
            Patch.extras(&parameters)
            performPOSTRequestFor("patches/near", parameters: parameters, completion: completion)
		}
	}

	public func fetchNotifications(skip: Int = 0, completion: ProxibaseCompletionBlock) {
        
        let parameters = [
            "limit": pageSizeNotifications,
            "skip": skip,
            "more": true,
        ]
        performPOSTRequestFor("user/getNotifications", parameters: parameters, completion: completion)
	}

	public func fetchInterestingPatches(location: CLLocationCoordinate2D?, skip: Int = 0, completion: (response:AnyObject?, error:NSError?) -> Void) {

        if let loc = location as CLLocationCoordinate2D! {
            var parameters: [String:AnyObject] = [
				"location": [
                    "lat": loc.latitude,
                    "lng": loc.longitude
				],
                "limit": pageSizeExplore,
                "skip": skip,
                "more": true,
			]
            Patch.extras(&parameters)
			performPOSTRequestFor("patches/interesting", parameters: parameters, completion: completion)
        }
	}

    public func fetchMessagesOwnedByUser(userId: String, criteria: [String:AnyObject] = [:], skip: Int = 0, completion: (response:AnyObject?, error:NSError?) -> Void) {
        
        var linked: [String:AnyObject] = ["to": "messages", "type": "create", "limit": pageSizeDefault, "skip": skip, "more": true]
        var parameters: [String:AnyObject] = [
            "linked": Message.extras(&linked),
            "promote": "linked",
        ]
        if !criteria.isEmpty {
            parameters["query"] = criteria
        }
        performPOSTRequestFor("find/users/\(userId)", parameters: parameters, completion: completion)
	}

	public func fetchMessagesForPatch(patchId: String, criteria: [String:AnyObject] = [:], skip: Int = 0, completion: (response:AnyObject?, error:NSError?) -> Void) {

        var linked: [String:AnyObject] = ["from": "messages", "type": "content", "limit": pageSizeDefault, "skip": skip, "more": true]
        var parameters: [String:AnyObject] = [
            "linked": Message.extras(&linked),
            "promote": "linked",
        ]
        if !criteria.isEmpty {
            parameters["query"] = criteria
        }
		performPOSTRequestFor("find/patches/\(patchId)", parameters: parameters, completion: completion)
	}
    
    public func fetchPatchesOwnedByUser(userId: String, criteria: [String:AnyObject] = [:], skip: Int = 0, completion: (response:AnyObject?, error:NSError?) -> Void) {
        
        var linked: [String:AnyObject] = ["to": "patches", "type": "create", "limit": pageSizeDefault, "skip": skip, "more": true]
        var parameters: [String:AnyObject] = [
            "linked": Patch.extras(&linked),
            "promote": "linked",
        ]
        if !criteria.isEmpty {
            parameters["query"] = criteria
        }
        performPOSTRequestFor("find/users/\(userId)", parameters: parameters, completion: completion)
    }

    public func fetchPatchesUserIsWatching(userId: String, criteria: [String:AnyObject] = [:], skip: Int = 0, completion: (response:AnyObject?, error:NSError?) -> Void) {
        
        var linked: [String:AnyObject] = ["to": "patches", "type": "watch", "limit": pageSizeDefault, "skip": skip, "more": true, "linkFields": "type,enabled"]
        var parameters: [String:AnyObject] = [
            "linked": Patch.extras(&linked),
            "promote": "linked",
        ]
        if !criteria.isEmpty {
            parameters["query"] = criteria
        }
        performPOSTRequestFor("find/users/\(userId)", parameters: parameters, completion: completion)
    }
    
	public func fetchUsersThatLikePatch(patchId: String, criteria: [String:AnyObject] = [:], skip: Int = 0, completion: (response:AnyObject?, error:NSError?) -> Void) {
        
		/* Used to show a list of users that currently like a patch. */
        var linked: [String:AnyObject] = ["from": "users", "type": "like", "limit": pageSizeDefault, "skip": skip, "more": true]
        var parameters: [String:AnyObject] = [
            "linked": User.extras(&linked),
            "promote": "linked",
        ]
        if !criteria.isEmpty {
            parameters["query"] = criteria
        }
		performPOSTRequestFor("find/patches/\(patchId)", parameters: parameters, completion: completion)
	}

    public func fetchUsersThatWatchPatch(patchId: String, isOwner: Bool = false, criteria: [String:AnyObject] = [:], skip: Int = 0, completion: (response:AnyObject?, error:NSError?) -> Void) {
        
		/* Used to show a list of users that are watching a patch or have a pending watch request for the patch. */
        var linked: [String:AnyObject] = ["from": "users", "type": "watch", "limit": pageSizeDefault, "skip": skip, "more": true, "linkFields": "type,enabled"]
        if !isOwner {
            linked["filter"] = ["enabled": true]
        }
        var parameters: [String:AnyObject] = [
            "linked": User.extras(&linked),
            "promote": "linked",
        ]
        if !criteria.isEmpty {
            parameters["query"] = criteria
        }
		performPOSTRequestFor("find/patches/\(patchId)", parameters: parameters, completion: completion)
	}

    public func fetchUsersThatLikeMessage(messageId: String, criteria: [String:AnyObject] = [:], skip: Int = 0, completion: (response:AnyObject?, error:NSError?) -> Void) {
        
        /* Used to show a list of users that currently like a message. */
        var linked: [String:AnyObject] = ["from": "users", "type": "like", "limit": pageSizeDefault, "skip": skip, "more": true]
        var parameters: [String:AnyObject] = [
            "linked": User.extras(&linked),
            "promote": "linked",
        ]
        if !criteria.isEmpty {
            parameters["query"] = criteria
        }
        performPOSTRequestFor("find/messages/\(messageId)", parameters: parameters, completion: completion)
    }
    
	/*--------------------------------------------------------------------------------------------
	 * PUBLIC: Modify
	 *--------------------------------------------------------------------------------------------*/

	public func signIn(email: NSString, password: NSString, completion: ProxibaseCompletionBlock) {
		/*
		* Send an auth/signin message to the server with the user's email address and password.
		* The completion block will be called asynchronously in either case.
		* If signin is successful, then the credentials from the server will be written to user defaults
		*/
		let parameters = ["email": email, "password": password, "installId": installationIdentifier]
		sessionManager.POST("auth/signin", parameters: parameters,
							success: {
								_, response in
								UserController.instance.handleSuccessfulSignInResponse(response)
								completion(response: response, error: nil)
							},
							failure: {
								_, error in
								completion(response: ServerError(error)?.response, error: error)
							})
	}

	public func signOut(completion: (response:AnyObject?, error:NSError?) -> Void) {
		/*
		* Send an auth/signout message.
		*
		* Discard credentials whether or not the server thinks we are signed out.
		* The completion closure is always performed asynchronously.
		*/
		if UserController.instance.authenticated {
			performGETRequestFor("auth/signout", parameters: [:]) {
				response, error in

				UserController.instance.discardCredentials()
				completion(response: response, error: error)
			}
		}
		else {
			UserController.instance.discardCredentials()

			dispatch_async(dispatch_get_main_queue(), {
				() -> Void in
				completion(response: nil, error: nil)
			})
		}
	}

    public func updatePassword(userId: NSString, password: NSString, passwordNew: NSString,  completion: ProxibaseCompletionBlock) {
        let parameters = ["userId": userId, "oldPassword": password, "newPassword": passwordNew, "installId": installationIdentifier]
        sessionManager.POST("user/changepw", parameters: authenticatedParameters(parameters),
            success: {
                _, response in
                completion(response: response, error: nil)
            },
            failure: {
                _, error in
                completion(response: ServerError(error)?.response, error: error)
        })
    }
    
    public func requestPasswordReset(email: NSString, completion: ProxibaseCompletionBlock) {
        let parameters = ["email": email, "installId": installationIdentifier]
        sessionManager.POST("user/reqresetpw", parameters: parameters,
            success: {
                _, response in
                completion(response: response, error: nil)
            },
            failure: {
                _, error in
                completion(response: ServerError(error)?.response, error: error)
        })
    }
    
    public func resetPassword(password: NSString, userId: NSString, sessionKey: NSString, completion: ProxibaseCompletionBlock) {
        let parameters = ["password": password, "user": userId, "session": sessionKey, "installId": installationIdentifier]
        sessionManager.POST("user/resetpw", parameters: parameters,
            success: {
                _, response in
                completion(response: response, error: nil)
            },
            failure: {
                _, error in
                completion(response: ServerError(error)?.response, error: error)
        })
    }
    
	public func insertUser(name: String, email: String, password: String, parameters: NSDictionary? = nil, completion: ProxibaseCompletionBlock) {
		/*
		 * Create a new user with the provided name, email and password.
		 * • Additional information (like profile photo) may optionally be sent in the parameters dictionary
		 */
		let createParameters = [
				"data": ["name": name,
						 "email": email,
						 "password": password
				],
				"secret": "larissa",
				"installId": installationIdentifier
		]

		performPOSTRequestFor("user/create", parameters: createParameters) {
			response, error in

			let queue = dispatch_queue_create("user-create-queue", DISPATCH_QUEUE_SERIAL)
			if error == nil {
				/*
				 * After creating a user, the user is left in a logged-in state, so process the response
				 * to extract the credentials.
				 */
				UserController.instance.handleSuccessfulSignInResponse(response!)

				/*
				 * If there were other parameters sent in the create request, then perform an update to get
				 * them onto the server
				 */
				if parameters != nil && parameters!.count > 0 {
					let semaphore = dispatch_semaphore_create(0)
					dispatch_async(queue)
					{
						self.updateUser(parameters!) {
							updateResponse, updateError in

							if let error = updateError {
								/* 
                                 * If the update fails, then the user-creation still succeeded.
								 * Log the second error, but don't take any action.
                                 */
								println("** Error during update after user creation")
								println(updateError)
							}
							dispatch_semaphore_signal(semaphore)
						}
					}

					dispatch_async(queue)
					{
						let s = semaphore // bogus
						dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
					}
				}
			}
			/*
			 * Invoke the caller's completion routine _after_ the update (if any) finishes. Pass the result of
			 * the create operation.
			 */
			dispatch_async(queue) {
				completion(response: response, error: error)
			}
		}
	}

	public func insertObject(path: String, parameters: NSDictionary, completion: ProxibaseCompletionBlock) {
		postObject(path, parameters: parameters, completion: completion)
	}

	public func updateObject(path: String, parameters: NSDictionary, completion: ProxibaseCompletionBlock) {
		postObject(path, parameters: parameters, completion: completion)
	}

	public func deleteObject(path: String, completion: ProxibaseCompletionBlock) {
		performDELETERequestFor(path, parameters: NSDictionary(), completion: completion)
	}

	public func insertLink(fromID: String, toID: String, linkType: LinkType, completion: ProxibaseCompletionBlock) {
		let linkParameters: NSDictionary = [
				"_from": fromID,
				"_to": toID,
				"type": linkType.rawValue
		]

		let postParameters = ["data": linkParameters]

		performPOSTRequestFor("data/links", parameters: postParameters) {
			response, error in
			completion(response: response, error: error)
		}
	}

	public func enableLinkById(linkId: String, enabled: Bool, completion: ProxibaseCompletionBlock) {
		let parameters = ["data": ["enabled": enabled]]
		performPOSTRequestFor("data/links/\(linkId)", parameters: parameters, completion: completion)
	}

	public func deleteLinkById(linkID: String, completion: ProxibaseCompletionBlock? = nil) {
		let linkPath = "data/links/\(linkID)"
		performDELETERequestFor(linkPath, parameters: NSDictionary()) {
			response, error in
			if let completionBlock = completion {
				completionBlock(response: response, error: error)
			}
		}
	}

	public func registerInstallStandard(completion: (response:AnyObject?, error:NSError?) -> Void) {
		let installId         = installationIdentifier
		let parseInstallId    = PFInstallation.currentInstallation().installationId
		let clientVersionName = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
		let clientVersionCode = (NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as! String).toInt()!
		let clientPackageName = NSBundle.mainBundle().bundleIdentifier!
		let deviceName        = UIDevice.currentDevice().modelIdentifier()
		let deviceType        = "ios"
		let deviceVersionName = UIDevice.currentDevice().systemVersion

		registerInstall(installId, parseInstallId: parseInstallId, clientVersionName: clientVersionName, clientVersionCode: clientVersionCode, clientPackageName: clientPackageName, deviceName: deviceName, deviceType: deviceType, deviceVersionName: deviceVersionName, completion: completion)
	}

	private func updateUser(userInfo: NSDictionary, completion: ProxibaseCompletionBlock) {
		/*
		* Update the currently signed-in user's information. Only provide fields that you want to change.
		*
		* There is special processing performed for the "photo" key, which may contain a UIImage on input.
		* If this is the case, then the image is uploaded to the users bucket on S3 and then, when that upload
		* is completed, the user record is updated with the photo field.
		*/
		assert(UserController.instance.authenticated, "ProxibaseClient must be authenticated prior to editing the user")
		if let userId = UserController.instance.userId {
			/*
			* The queue and semaphore are used to synchronize the (optional) upload to S3 with the
			* update of the record on the server. The S3 upload, if present, must complete first before
			* the database update.
			*/
			if let mutableUserInfo = userInfo.mutableCopy() as? NSMutableDictionary {
				let queue = dispatch_queue_create("update-user-queue", DISPATCH_QUEUE_SERIAL)
				queuePhotoUploadInParameters(mutableUserInfo, queue: queue, bucket: .Users)

				dispatch_async(queue) {
					let parameters = ["data": mutableUserInfo]
					self.performPOSTRequestFor("data/users/\(userId)", parameters: parameters) {
						response, error in
						completion(response: response, error: error)
					}
				}
			}
		}
	}
    
    /*--------------------------------------------------------------------------------------------
    * PUBLIC: Bing
    *--------------------------------------------------------------------------------------------*/
    
    public func loadSearchImages(query: String, limit: Int64 = 50, offset: Int64 = 0, maxImageSize: Int = 500000, maxDimen: Int = 1280, completion: (response:AnyObject?, error:NSError?) -> Void) {
        
        if let bingSessionManager: AFHTTPSessionManager = AFHTTPSessionManager(baseURL: NSURL(string: URI_PROXIBASE_SEARCH_IMAGES)) {
            
            let requestSerializer: AFJSONRequestSerializer = AFJSONRequestSerializer(writingOptions: nil)
            requestSerializer.setAuthorizationHeaderFieldWithUsername(nil, password: BING_ACCESS_KEY)
            bingSessionManager.requestSerializer = requestSerializer
            bingSessionManager.responseSerializer = JSONResponseSerializerWithData()
            
            var queryEncoded: String = query.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
            var bingUrl = "Image?Query=%27" + queryEncoded + "%27"
                + "&Market=%27en-US%27&Adult=%27Strict%27&ImageFilters=%27size%3alarge%27"
                + "&$top=\(limit + 1)"
                + "&$skip=\(offset)"
                + "&$format=Json"
            
            bingSessionManager.GET(bingUrl, parameters: nil,
                success: {
                    _, response in
                    completion(response: response, error: nil)
                },
                failure: {
                    _, error in
                    completion(response: ServerError(error)?.response, error: error)
            })
        }
    }

	/*--------------------------------------------------------------------------------------------
	 * User and install
	 *--------------------------------------------------------------------------------------------*/

	private func registerInstall(installId: String, parseInstallId: String, clientVersionName: String, clientVersionCode: Int, clientPackageName: String,
								 deviceName: String, deviceType: String, deviceVersionName: String, completion: (response:AnyObject?, error:NSError?) -> Void) {
		let parameters = [
				"install":
				[
						"installId": installId,
						"parseInstallId": parseInstallId,
						"clientVersionName": clientVersionName,
						"clientVersionCode": clientVersionCode,
						"clientPackageName": clientPackageName,
						"deviceName": deviceName,
						"deviceType": deviceType,
						"deviceVersionName": deviceVersionName
				]
		]
		performPOSTRequestFor("do/registerInstall", parameters: parameters, completion: completion)
	}

	private func authenticatedParameters(var parameters: NSDictionary) -> NSDictionary {
        /* Skip if already includes a sessionKey */
        if parameters["session"] == nil {
            if UserController.instance.authenticated {
                let userId         = UserController.instance.userId as NSString?
                let sessionKey     = UserController.instance.sessionKey as NSString?
                var authParameters = NSMutableDictionary(dictionary: ["user": userId! as NSString, "session": sessionKey! as NSString])
                authParameters.addEntriesFromDictionary(parameters as [NSObject:AnyObject])
                parameters = authParameters
            }
        }
		return parameters
	}

	/*--------------------------------------------------------------------------------------------
	 * Rest
	 *--------------------------------------------------------------------------------------------*/

	private func postObject(path: String, parameters: NSDictionary, completion: ProxibaseCompletionBlock) {
		/*
		* path can be a collection name (i.e. "data/patches", "data/messages") to create a new object.
		* path can also be an object path (i.e. "data/patches/pa.xyz" to update an existing object.
		*/
		let properties = parameters.mutableCopy() as! NSMutableDictionary
		let queue      = dispatch_queue_create("post-object-queue", DISPATCH_QUEUE_SERIAL)

		convertLocationProperties(properties)

        /* I believe this blocks until completed */
		queuePhotoUploadInParameters(properties, queue: queue, bucket: .Images)

		dispatch_async(queue) {
            /*
             * If photo parameter is still set to UIImage then s3 upload failed 
             */
            if let photo = properties["photo"] as? UIImage {
                completion(response: nil, error: NSError(domain: "Proxibase", code: 100, userInfo: ["message": "Image save failed"]))
                return
            }
			let postParameters = ["data": properties]
			self.performPOSTRequestFor(path, parameters: postParameters, completion: completion)
		}
	}

	private func performPOSTRequestFor(path: NSString, var parameters: NSDictionary, completion: ProxibaseCompletionBlock) {
		sessionManager.POST(path as String, parameters: authenticatedParameters(parameters),
							success: {
								(dataTask, response) -> Void in
								completion(response: response, error: nil)
							},
							failure: {
								(dataTask, error) -> Void in
								let response = dataTask.response as? NSHTTPURLResponse
								completion(response: ServerError(error)?.response, error: error)
							})
	}

	private func performGETRequestFor(path: NSString, var parameters: NSDictionary, completion: ProxibaseCompletionBlock) {
		sessionManager.GET(path as String, parameters: authenticatedParameters(parameters),
						   success: {
							   (dataTask, response) -> Void in
							   completion(response: response, error: nil)
						   },
						   failure: {
							   (dataTask, error) -> Void in
							   let response = dataTask.response as? NSHTTPURLResponse
							   completion(response: ServerError(error)?.response, error: error)
						   })
	}

	private func performDELETERequestFor(path: NSString, var parameters: NSDictionary, completion: ProxibaseCompletionBlock) {
		sessionManager.DELETE(path as String, parameters: authenticatedParameters(parameters),
							  success: {
								  dataTask, response in
								  completion(response: response, error: nil)
							  },
							  failure: {
								  dataTask, error in
								  let response = dataTask.response as? NSHTTPURLResponse
								  completion(response: ServerError(error)?.response, error: error)
							  })
	}

	/*--------------------------------------------------------------------------------------------
	 * Link profiles
	 *--------------------------------------------------------------------------------------------*/

	private func standardPatchLinks() -> [LinkSpec] {

        var links = [
            //Link(to: .Places, type: .Proximity, fields: "_id,name,photo,schema", linkFields: "_id,type,schema" ), // Place the patch is linked to
            LinkSpec(from: .Messages, type: .Content, count: true), // Count of messages linked to the patch
            LinkSpec(from: .Users, type: .Like, count: true), // Count of users that like the patch
            LinkSpec(from: .Users, type: .Watch, count: true) // Count of users that are watching the patch
        ]
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if let userId = userDefaults.stringForKey(PatchrUserDefaultKey("userId")) {
            links.append(LinkSpec(from: .Users, type: .Like, fields: "_id,type,schema", filter: ["_from": userId]))
            links.append(LinkSpec(from: .Users, type: .Watch, fields: "_id,type,enabled,schema", filter: ["_from": userId]))
            links.append(LinkSpec(from: .Messages, type: .Content, limit: 1, fields: "_id,type,schema", filter: ["_creator": userId]))
        }

        return links
	}

	private func standardMessageLinks() -> [LinkSpec] {
        
        var links = [
            LinkSpec(from: .Users, type: .Like, count: true), // Count of users that like this message
            LinkSpec(to: .Patches, type: .Content, limit: 1), // Patch the message is linked to
            LinkSpec(to: .Messages, type: .Share, limit: 1), // Message this message is sharing
            LinkSpec(to: .Patches, type: .Share, limit: 1), // Patch this message is sharing
            LinkSpec(to: .Users, type: .Share, limit: 5)   // Users this message is shared with
        ]
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if let userId = userDefaults.stringForKey(PatchrUserDefaultKey("userId")) {
            links.append(LinkSpec(from: .Users, type: .Like, fields: "_id,type,schema", filter: ["_from": userId]))
        }
        
        return links
	}

	private func standardUserLinks() -> [LinkSpec] {

		return [
			LinkSpec(to: .Patches, type: .Create, count: true), // Count of patches the user created
			LinkSpec(to: .Patches, type: .Watch, count: true), // Count of patches the user is watching
		]
	}

	/*--------------------------------------------------------------------------------------------
	 * S3
	 *--------------------------------------------------------------------------------------------*/

	private func queuePhotoUploadInParameters(parameters: NSMutableDictionary, queue: dispatch_queue_t, bucket: S3Bucket) {
        
		assert(UserController.instance.authenticated, "ProxibaseClient must be authenticated prior to editing the user")
        
		if let userId = UserController.instance.userId {
			if let photo = parameters["photo"] as? UIImage {
				let semaphore = dispatch_semaphore_create(0)
                
                var image = photo
                
                /* Ensure image is resized before upload */
                var scalingNeeded: Bool = (photo.size.width > 1280 || photo.size.height > 1280)
                if (scalingNeeded) {
                    let rect: CGRect = AVMakeRectWithAspectRatioInsideRect(photo.size, CGRectMake(0,0,1280, 1280))
                    image = photo.resizeTo(rect.size)
                }
                else {
                    image = photo.normalizedImage()
                }
                
				let profilePhotoKey = "\(userId)_\(DateTimeTag()).jpg"

				let photoDict = [
						"width": Int(image.size.width), // width/height are in points...should be pixels?
						"height": Int(image.size.height),
						"source": bucketInfo[bucket]!.source,
						"prefix": profilePhotoKey]

				dispatch_async(queue) {
					self.uploadImageToS3(image, bucket: self.bucketInfo[bucket]!.name, key: profilePhotoKey) {
						result, error in

						if error == nil {
							parameters["photo"] = photoDict
						}
						dispatch_semaphore_signal(semaphore)
					}
				}

				dispatch_async(queue) {
					let sem = semaphore // bogus! Avoids an invalid compiler error in Swift 1.1
					dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
				}
			}
		}
	}

	private func uploadImageToS3(image: UIImage, bucket: String, key: String, completion: S3UploadCompletionBlock) {
		if let imageURL = TemporaryFileURLForImage(image) {
			uploadFileToS3(imageURL, contentType: "image/jpeg", bucket: bucket, key: key) {
				result, error in
				completion(result, error)

				NSFileManager.defaultManager().removeItemAtURL(imageURL, error: nil)
			}
		}
	}

	private func uploadFileToS3(fileURL: NSURL, contentType: String, bucket: String, key: String, completion: S3UploadCompletionBlock) {
		/*
		* Uploads a file from the local file URL to the specified bucket in the 3meters S3 storage space. The file is stored with
		* the provided key.
		*
		* The upload occurs asynchronously and when completed, the completion block will be called with a result and error arguments.
		* A successful result includes information like the following in the result argument of the S3UploadCompletionBlock
		*
		* Optional(<AWSS3TransferManagerUploadOutput: 0x7fc580c79b90> {
		*     ETag = "\"6f2a09d19a6ae845d5916de4543984e5\"";
		*     serverSideEncryption = 0;
		*     versionId = 8JYaCWNaozIQIhF2pR1xYFy6W8hhbFPP;
		* })
		*      {
		*          key: 'AKIAIYU2FPHC2AOUG3CA',
		*          secret: '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',
		*          region: 'us-west-2',
		*          bucket: 'aircandi-images',
		*      }
		* TODO: switch to iam credentials
		*
		* TODO: store in aws cognito or some remote storage that is loaded on app launch
		* NOTE: I can't get Swift to recognize the enum values for AWSRegionTypes and AWSS3ObjectCannedACLs, so I have used
		* rawValue: initializers here.
		*/
		let credProvider  = AWSStaticCredentialsProvider(accessKey: PatchrS3Key, secretKey: PatchrS3Secret)
		let serviceConfig = AWSServiceConfiguration(region: AWSRegionType(rawValue: 3/*'us-west-2'*/)!, credentialsProvider: credProvider)
		let uploadRequest = AWSS3TransferManagerUploadRequest()

		uploadRequest.bucket = bucket
		uploadRequest.key = key
		uploadRequest.body = fileURL
		uploadRequest.ACL = AWSS3ObjectCannedACL(rawValue: 2/*AWSS3ObjectCannedACLPublicRead*/)!
		uploadRequest.contentType = contentType

		AWSS3TransferManager.registerS3TransferManagerWithConfiguration(serviceConfig, forKey: "AWS-Patchr")

		let transferManager = AWSS3TransferManager.S3TransferManagerForKey("AWS-Patchr")
		let task            = transferManager.upload(uploadRequest)

		task.continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: {
			(task) -> AnyObject! in
			completion(task.result, task.error)
			return nil // return nil to indicate the task is complete
		})
	}

	/*--------------------------------------------------------------------------------------------
	 * Helpers
	 *--------------------------------------------------------------------------------------------*/

	private func convertLocationProperties(properties: NSMutableDictionary) {
		if let location = properties["location"] as? CLLocation {
			properties["location"] = [
					"accuracy": location.horizontalAccuracy,
					"geometry": [
							location.coordinate.longitude,
							location.coordinate.latitude],
					"lat": location.coordinate.latitude,
					"lng": location.coordinate.longitude]
		}
	}

}

/*--------------------------------------------------------------------------------------------
 * Classes
 *--------------------------------------------------------------------------------------------*/

struct ServerError {
	/*
	* Given an NSError from AFNetworking, provide simple access to a select few pieces of information that
	* should be there.
	*
	* userInfo: {
	*      JSONResponseSerializerWithDataKey: {
	*          error: {
	*              code: Double,
	*              message: String,
	*          }
	*      },
	*      NSLocalizedDescription: String
	*/
	let error:                NSError
	var response:             NSDictionary?
	var message:              String           = LocalizedString("Unknown Error")
	var code:                 ServerStatusCode = .None
    var status:               Int              = 0
	var localizedDescription: String           = LocalizedString("(No Description)")

	init?(_ error: NSError?) {
		if let error = error {
			self.error = error

			let userInfoDictionary = (error.userInfo as NSDictionary?)

			response = (userInfoDictionary?[JSONResponseSerializerWithDataKey] as! NSDictionary?)
			let responseErrorDictionary = response?["error"] as! NSDictionary?

			if let responseDict = responseErrorDictionary {
				if let responseMessage = responseDict["message"] as? String {
					message = responseMessage
				}
				if let responseCode = responseDict["code"] as? Float {
					code = ServerStatusCode(rawValue: responseCode)!
				}
                if let responseStatus = responseDict["status"] as? Int {
                    status = responseStatus
                }
			}
			if let userInfo = userInfoDictionary {
				if let description = userInfo["NSLocalizedDescription"] as? String {
					localizedDescription = description
				}
			}

			println("Proxibase Error Summary")
			println(message)
			println(code)
			println(localizedDescription)
		}
		else {
			return nil
		}
	}
}

struct ServerResponse {
	/*
	* Convenience wrapper
	*
	* The JSON response serializer produces an NSDictionary. This class wraps it and provides
	* more consistent and less casty access to things we care about.
	*/
	var responseDictionary: NSDictionary
	var resultCount:        Int

	var resultObjects: NSArray {
		get {
			if resultCount == 0 {
				/* Returns single item as an empty array */
				return NSArray()
			}
			else if resultCount == 1 {
				/* Returns single item as a map */
				return NSArray(object: responseDictionary["data"] as! NSDictionary)
			}
			else {
				/* Returns multiple items as an array of maps */
				return responseDictionary["data"] as! NSArray
			}
		}
	}

	/* Single-result accessors */
	var resultObject: NSDictionary {
		assert(resultCount == 1, "resultObject called when there are more than one result objects")

		if let resultDict = responseDictionary["data"] as? NSDictionary {
			return resultDict
		}

		if let resultArray = responseDictionary["data"] as? NSArray {
			return resultArray[0] as! NSDictionary
		}

		assert(false, "Unexpected result")

		return NSDictionary()
	}

	var resultID: String {
		get {
			return resultObject["_id"] as! String
		}
	}

	init(_ responseObject: AnyObject?) {
		responseDictionary = responseObject as! NSDictionary
		resultCount = (responseDictionary["count"] as! NSNumber).integerValue
	}

	/*
	* Given a response from the server, iterate over all the objects returned in the "data" result field.
	*/
	func forEachResultObject(block: (NSDictionary) -> Void) {
		for object in resultObjects {
			block(object as! NSDictionary)
		}
	}
}

extension UIImage {
    
    func resizeTo(size:CGSize) -> UIImage {
        
        let hasAlpha = false
        let scale: CGFloat = 1.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        self.drawInRect(CGRect(origin: CGPointZero, size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    func normalizedImage() -> UIImage {
        if self.imageOrientation == UIImageOrientation.Up {
            return self
        }
        UIGraphicsBeginImageContextWithOptions(self.size, true, self.scale)
        self.drawInRect(CGRect(origin: CGPoint(x: 0, y: 0), size: self.size))
        let normalizedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return normalizedImage;
    }
}

public class LinkSpec {
    
	public var to:           LinkDestination?
	public var from:         LinkDestination?
	public var type:         LinkType?
    public var enabled:      Bool?
	public var limit:        UInt?
	public var count:        Bool?
    public var filter:       [NSObject:AnyObject]?
    public var fields:       AnyObject?
	public var linkFields:   AnyObject?
	public var linkedFilter: [NSObject:AnyObject]?
	public var subLinks:     [LinkSpec]?

    init(to: LinkDestination, type: LinkType, enabled: Bool? = nil, limit: UInt? = nil, count: Bool? = nil,
        fields: AnyObject? = nil, filter: [NSObject:AnyObject]? = nil,
        linkFields: AnyObject? = nil, linkedFilter: [NSObject:AnyObject]? = nil, subLinks: [LinkSpec]? = nil) {
		self.to = to
		self.type = type
        self.enabled = enabled
		self.limit = limit
		self.count = count
        self.fields = fields
        self.filter = filter
		self.linkFields = linkFields
		self.linkedFilter = linkedFilter
		self.subLinks = subLinks
	}

	init(from: LinkDestination, type: LinkType, enabled: Bool? = nil, limit: UInt? = nil, count: Bool? = nil,
        fields: AnyObject? = nil, filter: [NSObject:AnyObject]? = nil,
        linkFields: AnyObject? = nil, linkedFilter: [NSObject:AnyObject]? = nil, subLinks: [LinkSpec]? = nil) {
		self.from = from
		self.type = type
        self.enabled = enabled
		self.limit = limit
		self.count = count
        self.fields = fields
        self.filter = filter
		self.linkFields = linkFields
		self.linkedFilter = linkedFilter
		self.subLinks = subLinks
	}

	func toDictionary() -> Dictionary<String, AnyObject> {
		var dictionary = Dictionary<String, AnyObject>()
		if to != nil {
			dictionary["to"] = to!.rawValue
		}
		if from != nil {
			dictionary["from"] = from!.rawValue
		}
		if type != nil {
			dictionary["type"] = type!.rawValue
		}
        if enabled != nil {
            dictionary["enabled"] = enabled!
        }
		if limit != nil {
			dictionary["limit"] = limit!
		}
		if count != nil {
			dictionary["count"] = count!
		}
        if fields != nil {
            dictionary["fields"] = fields
        }
        if filter != nil {
            dictionary["filter"] = filter
        }
		if linkFields != nil {
			dictionary["linkFields"] = linkFields
		}

		if linkedFilter != nil {
			dictionary["linkedFilter"] = linkedFilter
		}

		if subLinks != nil {
			dictionary["linked"] = subLinks!.map {
				$0.toDictionary()
			}
		}

		return dictionary
	}
}

enum S3Bucket {
	case Users
	case Images
}

public enum LinkDestination: String {
	case Beacons  = "beacons"
	case Places   = "places"
	case Messages = "messages"
	case Users    = "users"
	case Patches  = "patches"
}

public enum LinkType: String {
	case Proximity = "proximity"
	case Content   = "content"
	case Like      = "like"
	case Watch     = "watch"
	case Create    = "create"
	case Share     = "share"
}

enum ServerStatusCode: Float {
	case None = 0.0

	case BAD_REQUEST = 400.0

	case MISSING_PARAM        = 400.1
	case BAD_PARAM            = 400.11
	case BAD_TYPE             = 400.12
	case BAD_VALUE            = 400.13
	case BAD_JSON             = 400.14
	case BAD_USER_AUTH_PARAMS = 400.21
	case BAD_VERSION          = 400.4
	case BAD_APPLINK          = 400.5

	case UNAUTHORIZED                 = 401.0
	case UNAUTHORIZED_CREDENTIALS     = 401.1
	case UNAUTHORIZED_SESSION_EXPIRED = 401.2
	case UNAUTHORIZED_NOT_HUMAN       = 401.3
	case UNAUTHORIZED_EMAIL_NOT_FOUND = 401.4

	case FORBIDDEN                    = 403.0
	case FORBIDDEN_DUPLICATE          = 403.1
	case FORBIDDEN_DUPLICATE_LIKELY   = 403.11
	case FORBIDDEN_USER_PASSWORD_WEAK = 403.21
	case FORBIDDEN_VIA_API_ONLY       = 403.22
	case FORBIDDEN_LIMIT_EXCEEDED     = 403.3
    
    case NOT_FOUND                    = 404.0
}

