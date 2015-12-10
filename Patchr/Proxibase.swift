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
import Parse
import UIKit

/*
 * Access control is set to public because that is the only way that
 * unit tests can use this class.
 */
public class Proxibase {
    
	public typealias CompletionBlock = (response:AnyObject?, error:NSError?) -> Void

	public let StagingURI    = "https://api.aircandi.com:8443/v1/"
	public let ProductionURI = "https://api.aircandi.com/v1/"

	let pageSizeDefault:       Int = 50
	let pageSizeNearby:        Int = 50
	let pageSizeExplore:       Int = 50
	let pageSizeNotifications: Int = 50

	private var cachedInstallationIdentifier: String?

	public var installationIdentifier: String {
        
		if cachedInstallationIdentifier == nil {
			let installationIdentifierKey    = "installationIdentifier"
			let lockbox = Lockbox(keyPrefix: KEYCHAIN_GROUP)
			var storedInstallationIdentifier = lockbox.stringForKey(installationIdentifierKey) as String?

			if storedInstallationIdentifier == nil {
				storedInstallationIdentifier = NSUUID().UUIDString
				lockbox.setString(storedInstallationIdentifier, forKey: installationIdentifierKey)
			}
			cachedInstallationIdentifier = storedInstallationIdentifier
		}
		
		return cachedInstallationIdentifier!
	}

	private let sessionManager: AFHTTPSessionManager
	
	required public init() {

		var serverURI = NSUserDefaults.standardUserDefaults().stringForKey(PatchrUserDefaultKey("serverURI"))
		if serverURI == nil {
			serverURI = ProductionURI
			NSUserDefaults.standardUserDefaults().setObject(serverURI, forKey: PatchrUserDefaultKey("serverURI"))
		}

		sessionManager = AFHTTPSessionManager(baseURL: NSURL(string: serverURI!))
		sessionManager.requestSerializer = AFJSONRequestSerializer()
        sessionManager.requestSerializer.timeoutInterval = NSTimeInterval(TIMEOUT_REQUEST)
		sessionManager.responseSerializer = JSONResponseSerializerWithData()
		sessionManager.completionQueue = DataController.instance.backgroundDispatch
	}

	/*--------------------------------------------------------------------------------------------
	 * PUBLIC: Fetch one
	 *--------------------------------------------------------------------------------------------*/

	public func fetchPatchById(entityId: String, criteria: [String:AnyObject], completion: CompletionBlock) {

		var parameters: [String:AnyObject] = [:]
		Patch.extras(&parameters)
		if !criteria.isEmpty {
			parameters["query"] = criteria
		}
		performPOSTRequestFor("find/patches/\(entityId)", parameters: parameters, completion: completion)
	}

	public func fetchMessageById(messageId: String, criteria: [String:AnyObject], completion: CompletionBlock) {

		var parameters: [String:AnyObject] = [:]
		Message.extras(&parameters)
		if !criteria.isEmpty {
			parameters["query"] = criteria
		}
		performPOSTRequestFor("find/messages/\(messageId)", parameters: parameters, completion: completion)
	}

	public func fetchUserById(userId: String, criteria: [String:AnyObject], completion: CompletionBlock) {

		var parameters: [String:AnyObject] = [:]
		User.extras(&parameters)
		if !criteria.isEmpty {
			parameters["query"] = criteria
		}
		performPOSTRequestFor("find/users/\(userId)", parameters: parameters, completion: completion)
	}

	public func fetchPlaceById(id: String, criteria: [String:AnyObject], completion: CompletionBlock) {

		var parameters: [String:AnyObject] = [:]
		Place.extras(&parameters)
		if !criteria.isEmpty {
			parameters["query"] = criteria
		}
		performPOSTRequestFor("find/places/\(id)", parameters: parameters, completion: completion)
	}

	/*--------------------------------------------------------------------------------------------
	* PUBLIC: Fetch collection
	*--------------------------------------------------------------------------------------------*/

	public func fetchNearbyPatches(location: CLLocationCoordinate2D?, radius: UInt = 10000, skip: Int = 0, completion: CompletionBlock) {

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

	public func fetchNotifications(skip: Int = 0, completion: CompletionBlock) {

		let parameters = [
				"limit": pageSizeNotifications,
				"skip": skip,
				"more": true,
		]
		performPOSTRequestFor("user/getNotifications", parameters: parameters, completion: completion)
	}

	public func fetchInterestingPatches(location: CLLocationCoordinate2D?, skip: Int = 0, completion: (response:AnyObject?, error:NSError?) -> Void) {

        var parameters: [String:AnyObject] = [
                "limit": pageSizeExplore,
                "skip": skip,
                "more": true,
        ]
        
        if let loc = location as CLLocationCoordinate2D! {
            parameters["location"] = [
                "lat": loc.latitude,
                "lng": loc.longitude
            ]
        }

		Patch.extras(&parameters)
		performPOSTRequestFor("patches/interesting", parameters: parameters, completion: completion)
	}

	public func fetchMessagesOwnedByUser(userId: String, criteria: [String:AnyObject] = [:], skip: Int = 0, completion: (response:AnyObject?, error:NSError?) -> Void) {

		var linked:     [String:AnyObject] = ["to": "messages", "type": "create", "limit": pageSizeDefault, "skip": skip, "more": true]
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

		var linked:     [String:AnyObject] = ["from": "messages", "type": "content", "limit": pageSizeDefault, "skip": skip, "more": true]
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

		var linked:     [String:AnyObject] = ["to": "patches", "type": "create", "limit": pageSizeDefault, "skip": skip, "more": true]
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

		var linked:     [String:AnyObject] = ["to": "patches", "type": "watch", "limit": pageSizeDefault, "skip": skip, "more": true, "linkFields": "type,enabled"]
		var parameters: [String:AnyObject] = [
				"linked": Patch.extras(&linked),
				"promote": "linked",
		]
		if !criteria.isEmpty {
			parameters["query"] = criteria
		}
		performPOSTRequestFor("find/users/\(userId)", parameters: parameters, completion: completion)
	}

    public func fetchUsersFavoritePatches(userId: String, criteria: [String:AnyObject] = [:], skip: Int = 0, completion: (response:AnyObject?, error:NSError?) -> Void) {
        
        var linked:     [String:AnyObject] = ["to": "patches", "type": "like", "limit": pageSizeDefault, "skip": skip, "more": true]
        var parameters: [String:AnyObject] = [
            "linked": Patch.extras(&linked),
            "promote": "linked",
        ]
        if !criteria.isEmpty {
            parameters["query"] = criteria
        }
        performPOSTRequestFor("find/users/\(userId)", parameters: parameters, completion: completion)
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
		var linked:     [String:AnyObject]
										   = ["from": "users", "type": "like", "limit": pageSizeDefault, "skip": skip, "more": true]
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

    public func postEntity(path: String, parameters: NSDictionary, addLocation: Bool = true, completion: CompletionBlock) -> NSURLSessionTask {
        
        var parametersCopy = parameters.mutableCopy() as! NSMutableDictionary
        convertLocationProperties(parametersCopy)
        if parametersCopy["data"] == nil {
            parametersCopy = ["data": parametersCopy]
        }
        let request: NSURLSessionTask = self.performPOSTRequestFor(path, parameters: parametersCopy, addLocation: addLocation, completion: completion)
        return request
    }
    
    public func deleteObject(path: String, completion: CompletionBlock) {
		performDELETERequestFor(path, parameters: NSDictionary(), completion: completion)
	}

	public func insertLink(fromID: String, toID: String, linkType: LinkType, completion: CompletionBlock) {
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

	public func enableLinkById(linkId: String, enabled: Bool, completion: CompletionBlock) {
		let parameters = ["data": ["enabled": enabled]]
		performPOSTRequestFor("data/links/\(linkId)", parameters: parameters, completion: completion)
	}

    public func muteLinkById(linkId: String, muted: Bool, completion: CompletionBlock) {
        let parameters = ["data": ["mute": muted]]
        performPOSTRequestFor("data/links/\(linkId)", parameters: parameters, completion: completion)
    }
    
	public func deleteLinkById(linkID: String, completion: CompletionBlock? = nil) {
		let linkPath = "data/links/\(linkID)"
		performDELETERequestFor(linkPath, parameters: NSDictionary()) {
			response, error in
			if let completionBlock = completion {
				completionBlock(response: response, error: error)
			}
		}
	}

    public func deleteLink(fromId: String, toId: String, linkType: LinkType, completion: CompletionBlock? = nil) {

        /* We are not encoding the query string because we know that all of the characters are valid */
        let queryString = "query[_to]=\(toId)&query[_from]=\(fromId)&query[type]=\(linkType.rawValue)"
        let linkPath = "data/links?\(queryString)"

        performDELETERequestFor(linkPath, parameters: NSDictionary()) {
            response, error in
            if let completionBlock = completion {
                completionBlock(response: response, error: error)
            }
        }
    }
    
	/*--------------------------------------------------------------------------------------------
	* PUBLIC: Bing
	*--------------------------------------------------------------------------------------------*/

	public func loadSearchImages(query: String, limit: Int64 = 50, offset: Int64 = 0, maxImageSize: Int = 500000, maxDimen: Int = Int(IMAGE_DIMENSION_MAX), completion: CompletionBlock) {

		if let bingSessionManager: AFHTTPSessionManager = AFHTTPSessionManager(baseURL: NSURL(string: URI_PROXIBASE_SEARCH_IMAGES)) {
			
            let keys = PatchrKeys()
			let requestSerializer: AFJSONRequestSerializer = AFJSONRequestSerializer()
			
			requestSerializer.setAuthorizationHeaderFieldWithUsername("", password: keys.bingAccessKey())
			bingSessionManager.requestSerializer = requestSerializer
			bingSessionManager.responseSerializer = JSONResponseSerializerWithData()

			let queryEncoded: String
						= query.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
			let bingUrl = "Image?Query=%27" + queryEncoded + "%27"
					+ "&Market=%27en-US%27&Adult=%27Strict%27&ImageFilters=%27size%3alarge%27"
					+ "&$top=\(limit + 1)"
					+ "&$skip=\(offset)"
					+ "&$format=Json"

			bingSessionManager.GET(bingUrl, parameters: nil,
								   success: {
									   dataTask, response in
									   completion(response: response, error: nil)
								   },
								   failure: {
									   dataTask, error in
									   completion(response: ServerError(error)?.response, error: error)
								   })
		}
	}

	/*--------------------------------------------------------------------------------------------
	 * User and install
	 *--------------------------------------------------------------------------------------------*/

	public func login(email: String, password: String, provider: String, token: String?, completion: CompletionBlock) {
		/*
		* Send an auth/signin message to the server with the user's email address and password.
		* The completion block will be called asynchronously in either case.
		* If signin is successful, then the credentials from the server will be written to user defaults
		*/
		var parameters = ["email": email, "password": password, "installId": installationIdentifier]
		if provider == AuthProvider.FACEBOOK || provider == AuthProvider.GOOGLE {
			parameters = ["provider": provider, "token": token!, "installId": installationIdentifier]
		}
		
		sessionManager.POST("auth/signin", parameters: parameters,
			success: {
				dataTask, response in
				UserController.instance.handleSuccessfulSignInResponse(response)
				completion(response: response, error: nil)
			},
			failure: {
				dataTask, error in
				completion(response: ServerError(error)?.response, error: error)
		})
	}
	
	public func logout(completion: (response:AnyObject?, error:NSError?) -> Void) {
		/*
		* Send an auth/signout message.
		*
		* Discard credentials whether or not the server thinks we are signed out.
		* The completion closure is always performed asynchronously.
		*/
		if UserController.instance.authenticated {
			performGETRequestFor("auth/signout", parameters: [:]) {
				response, error in
				completion(response: response, error: error)
			}
		}
		else {
			dispatch_async(dispatch_get_main_queue(), {
				() -> Void in
				completion(response: nil, error: nil)
			})
		}
	}
	
	public func updatePassword(userId: NSString, password: NSString, passwordNew: NSString, completion: CompletionBlock) {
		let parameters = ["userId": userId, "oldPassword": password, "newPassword": passwordNew, "installId": installationIdentifier]
		sessionManager.POST("user/changepw", parameters: addSessionParameters(parameters),
			success: {
				dataTask, response in
				completion(response: response, error: nil)
			},
			failure: {
				dataTask, error in
				completion(response: ServerError(error)?.response, error: error)
		})
	}
	
	public func requestPasswordReset(email: NSString, completion: CompletionBlock) {
		let parameters = ["email": email, "installId": installationIdentifier]
		sessionManager.POST("user/reqresetpw", parameters: parameters,
			success: {
				dataTask, response in
				completion(response: response, error: nil)
			},
			failure: {
				dataTask, error in
				completion(response: ServerError(error)?.response, error: error)
		})
	}
	
	public func resetPassword(password: NSString, userId: NSString, sessionKey: NSString, completion: CompletionBlock) {
		let parameters
		= ["password": password, "user": userId, "session": sessionKey, "installId": installationIdentifier]
		sessionManager.POST("user/resetpw", parameters: parameters,
			success: {
				dataTask, response in
				completion(response: response, error: nil)
			},
			failure: {
				dataTask, error in
				completion(response: ServerError(error)?.response, error: error)
		})
	}
	
	public func registerInstallStandard(completion: (response:AnyObject?, error:NSError?) -> Void) {
		let installId         = installationIdentifier
		let parseInstallId    = PFInstallation.currentInstallation().installationId
		let clientVersionName = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
		let clientVersionCode = Int(NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as! String)!
		let clientPackageName = NSBundle.mainBundle().bundleIdentifier!
		let deviceName        = UIDevice.currentDevice().modelIdentifier()
		let deviceType        = "ios"
		let deviceVersionName = UIDevice.currentDevice().systemVersion
		
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
	
    public func updateProximity(location: CLLocation, completion: (response:AnyObject?, error:NSError?) -> Void) {
        let parameters = [
            "installId": self.installationIdentifier,
            "location": [
                "accuracy": location.horizontalAccuracy,
                "geometry": [
                    location.coordinate.longitude,
                    location.coordinate.latitude],
                "lat": location.coordinate.latitude,
                "lng": location.coordinate.longitude
            ]
        ]
        performPOSTRequestFor("do/updateProximity", parameters: parameters, completion: completion)
    }

	private func addSessionParameters(var parameters: NSDictionary) -> NSDictionary {
		/* Skip if already includes a sessionKey */
		if parameters["session"] == nil {
			if UserController.instance.authenticated {
				let userId         = UserController.instance.userId as NSString?
				let sessionKey     = UserController.instance.sessionKey as NSString?
				let authParameters = NSMutableDictionary(dictionary: ["user": userId! as NSString, "session": sessionKey! as NSString])
				authParameters.addEntriesFromDictionary(parameters as [NSObject:AnyObject])
				parameters = authParameters
			}
		}
		return parameters
	}

	/*--------------------------------------------------------------------------------------------
	 * Rest
	 *--------------------------------------------------------------------------------------------*/
    
	private func performPOSTRequestFor(path: NSString, var parameters: NSDictionary, addLocation: Bool = false, completion: CompletionBlock) -> NSURLSessionTask {
        
        parameters = addSessionParameters(parameters)
        
        if addLocation {
            if let location = LocationController.instance.lastLocationAccepted() {
                let locDict = [
                    "accuracy": location.horizontalAccuracy,
                    "geometry": [
                        location.coordinate.longitude,
                        location.coordinate.latitude],
                    "lat": location.coordinate.latitude,
                    "lng": location.coordinate.longitude
                ]
                parameters.setValue(self.installationIdentifier, forKey: "installId")
                parameters.setValue(locDict, forKey: "location")
            }
        }

        let request: NSURLSessionTask = sessionManager.POST(path as String, parameters: parameters,
							success: {
								dataTask, response in
								completion(response: response, error: nil)
							},
							failure: {
								dataTask, error in
								completion(response: ServerError(error)?.response, error: error)
							})!
        return request
	}

	private func performGETRequestFor(path: NSString, parameters: NSDictionary, completion: CompletionBlock) {
		sessionManager.GET(path as String, parameters: addSessionParameters(parameters),
						   success: {
							   dataTask, response in
							   completion(response: response, error: nil)
						   },
						   failure: {
							   dataTask, error in
							   completion(response: ServerError(error)?.response, error: error)
						   })
	}

	private func performDELETERequestFor(path: NSString, parameters: NSDictionary, completion: CompletionBlock) {
		sessionManager.DELETE(path as String, parameters: addSessionParameters(parameters),
							  success: {
								  dataTask, response in
								  completion(response: response, error: nil)
							  },
							  failure: {
								  dataTask, error in
								  completion(response: ServerError(error)?.response, error: error)
							  })
	}

	/*--------------------------------------------------------------------------------------------
	 * Link profiles
	 *--------------------------------------------------------------------------------------------*/

	private func standardPatchLinks() -> [LinkSpec] {

		var links = [
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
	let error:       NSError
	var code:        ServerStatusCode = .None		// Status code from the service
	var status:      Int?             = 200			// Status code form the network stack
	var response:    NSDictionary?
	var message:     String?
	var description: String?

	init?(_ error: NSError?) {
		if let error = error {
			self.error = error
            
            if let userInfoDictionary = (error.userInfo as NSDictionary?) {
                if let response = (userInfoDictionary[JSONResponseSerializerWithDataKey] as! NSDictionary?)
                    , let responseErrorDictionary = response["error"] as! NSDictionary? {
                    
                    if let responseMessage = responseErrorDictionary["message"] as? String {
                        self.message = responseMessage
                    }
                    if let responseCode = responseErrorDictionary["code"] as? Float {
                        self.code = ServerStatusCode(rawValue: responseCode)!
                    }
                    if let responseStatus = responseErrorDictionary["status"] as? Int {
                        self.status = responseStatus
                    }
                }
                
                if let localizedDescription = userInfoDictionary["NSLocalizedDescription"] as? String {
                    self.description = localizedDescription
                }
                if let userMessage = userInfoDictionary["message"] as? String {   // Used for s3 failures
                    self.message = userMessage
                }
            }
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
	public var linked:       [LinkSpec]?
    public var links:        [LinkSpec]?
    public var linkCount:    [LinkSpec]?
	public var refs:		 [NSObject:AnyObject]?

	init(to: LinkDestination, type: LinkType, enabled: Bool? = nil, limit: UInt? = nil, count: Bool? = nil,
		 fields: AnyObject? = nil, filter: [NSObject:AnyObject]? = nil,
		 linkFields: AnyObject? = nil, linkedFilter: [NSObject:AnyObject]? = nil,
		linked: [LinkSpec]? = nil, links: [LinkSpec]? = nil, linkCount: [LinkSpec]? = nil, refs: [NSObject:AnyObject]? = nil) {
		self.to = to
		self.type = type
		self.enabled = enabled
		self.limit = limit
		self.count = count
		self.fields = fields
		self.filter = filter
		self.linkFields = linkFields
		self.linkedFilter = linkedFilter
		self.linked = linked
        self.links = links
        self.linkCount = linkCount
		self.refs = refs
	}

	init(from: LinkDestination, type: LinkType, enabled: Bool? = nil, limit: UInt? = nil, count: Bool? = nil,
		 fields: AnyObject? = nil, filter: [NSObject:AnyObject]? = nil,
		 linkFields: AnyObject? = nil, linkedFilter: [NSObject:AnyObject]? = nil,
         linked: [LinkSpec]? = nil, links: [LinkSpec]? = nil, linkCount: [LinkSpec]? = nil, refs: [NSObject:AnyObject]? = nil) {
		self.from = from
		self.type = type
		self.enabled = enabled
		self.limit = limit
		self.count = count
		self.fields = fields
		self.filter = filter
		self.linkFields = linkFields
		self.linkedFilter = linkedFilter
        self.linked = linked
        self.links = links
        self.linkCount = linkCount
		self.refs = refs
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
		if linked != nil {
			dictionary["linked"] = linked!.map {
				$0.toDictionary()
			}
		}
        if links != nil {
            dictionary["links"] = links!.map {
                $0.toDictionary()
            }
        }        
        if linkCount != nil {
            dictionary["linkCount"] = linkCount!.map {
                $0.toDictionary()
            }
        }
		if refs != nil {
			dictionary["refs"] = refs
		}
		return dictionary
	}
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
    case UNAUTHORIZED_CREDENTIALS     = 401.1   // Either email or password are incorrect
    case UNAUTHORIZED_SESSION_EXPIRED = 401.2   // Provided session id is not longer good
	case UNAUTHORIZED_NOT_HUMAN       = 401.3
	case UNAUTHORIZED_EMAIL_NOT_FOUND = 401.4

	case FORBIDDEN                    = 403.0
	case FORBIDDEN_DUPLICATE          = 403.1
	case FORBIDDEN_DUPLICATE_LIKELY   = 403.11
	case FORBIDDEN_USER_PASSWORD_WEAK = 403.21
	case FORBIDDEN_VIA_API_ONLY       = 403.22
	case FORBIDDEN_LIMIT_EXCEEDED     = 403.3

	case NOT_FOUND = 404.0
}

/**
HTTP status codes as per http://en.wikipedia.org/wiki/List_of_HTTP_status_codes
The RF2616 standard is completely covered (http://www.ietf.org/rfc/rfc2616.txt)
*/

enum HTTPStatusCode: Int {
	// Informational
	case Continue                      = 100
	case SwitchingProtocols            = 101
	case Processing                    = 102

	// Success
	case OK                            = 200
	case Created                       = 201
	case Accepted                      = 202
	case NonAuthoritativeInformation   = 203
	case NoContent                     = 204
	case ResetContent                  = 205
	case PartialContent                = 206
	case MultiStatus                   = 207
	case AlreadyReported               = 208
	case IMUsed                        = 226

	// Redirections
	case MultipleChoices               = 300
	case MovedPermanently              = 301
	case Found                         = 302
	case SeeOther                      = 303
	case NotModified                   = 304
	case UseProxy                      = 305
	case SwitchProxy                   = 306
	case TemporaryRedirect             = 307
	case PermanentRedirect             = 308

	// Client Errors
	case BadRequest                    = 400
	case Unauthorized                  = 401
	case PaymentRequired               = 402
	case Forbidden                     = 403
	case NotFound                      = 404
	case MethodNotAllowed              = 405
	case NotAcceptable                 = 406
	case ProxyAuthenticationRequired   = 407
	case RequestTimeout                = 408
	case Conflict                      = 409
	case Gone                          = 410
	case LengthRequired                = 411
	case PreconditionFailed            = 412
	case RequestEntityTooLarge         = 413
	case RequestURITooLong             = 414
	case UnsupportedMediaType          = 415
	case RequestedRangeNotSatisfiable  = 416
	case ExpectationFailed             = 417
	case ImATeapot                     = 418
	case AuthenticationTimeout         = 419
	case UnprocessableEntity           = 422
	case Locked                        = 423
	case FailedDependency              = 424
	case UpgradeRequired               = 426
	case PreconditionRequired          = 428
	case TooManyRequests               = 429
	case RequestHeaderFieldsTooLarge   = 431
	case LoginTimeout                  = 440
	case NoResponse                    = 444
	case RetryWith                     = 449
	case UnavailableForLegalReasons    = 451
	case RequestHeaderTooLarge         = 494
	case CertError                     = 495
	case NoCert                        = 496
	case HTTPToHTTPS                   = 497
	case TokenExpired                  = 498
	case ClientClosedRequest           = 499

	// Server Errors
	case InternalServerError           = 500
	case NotImplemented                = 501
	case BadGateway                    = 502
	case ServiceUnavailable            = 503
	case GatewayTimeout                = 504
	case HTTPVersionNotSupported       = 505
	case VariantAlsoNegotiates         = 506
	case InsufficientStorage           = 507
	case LoopDetected                  = 508
	case BandwidthLimitExceeded        = 509
	case NotExtended                   = 510
	case NetworkAuthenticationRequired = 511
	case NetworkTimeoutError           = 599
}

extension HTTPStatusCode {
	/// Informational - Request received, continuing process.
	var isInformational: Bool {
		return inRange(100 ... 200)
	}
	/// Success - The action was successfully received, understood, and accepted.
	var isSuccess: Bool {
		return inRange(200 ... 299)
	}
	/// Redirection - Further action must be taken in order to complete the request.
	var isRedirection: Bool {
		return inRange(300 ... 399)
	}
	/// Client Error - The request contains bad syntax or cannot be fulfilled.
	var isClientError: Bool {
		return inRange(400 ... 499)
	}
	/// Server Error - The server failed to fulfill an apparently valid request.
	var isServerError: Bool {
		return inRange(500 ... 599)
	}

	/// :returns: true if the status code is in the provided range, false otherwise.
	private func inRange(range: Range<Int>) -> Bool {
		return range.contains(rawValue)
	}
}

extension HTTPStatusCode {
	var localizedReasonPhrase: String {
		return NSHTTPURLResponse.localizedStringForStatusCode(rawValue)
	}
}

// MARK: - Printing

extension HTTPStatusCode: CustomDebugStringConvertible, CustomStringConvertible {
	var description: String {
		return "\(rawValue) - \(localizedReasonPhrase)"
	}
	var debugDescription: String {
		return "HTTPStatusCode:\(description)"
	}
}

// MARK: - HTTP URL Response

extension HTTPStatusCode {
	/// Obtains a possible status code from an optional HTTP URL response.
	init?(HTTPResponse: NSHTTPURLResponse?) {
		if let value = HTTPResponse?.statusCode {
			self.init(rawValue: value)
		}
		else {
			return nil
		}
	}
}

extension NSHTTPURLResponse {
	var statusCodeValue: HTTPStatusCode? {
		return HTTPStatusCode(HTTPResponse: self)
	}

	@available(iOS, introduced = 7.0)
	convenience init?(URL url: NSURL, statusCode: HTTPStatusCode, HTTPVersion: String?, headerFields: [String: String]?) {
		self.init(URL: url, statusCode: statusCode.rawValue, HTTPVersion: HTTPVersion, headerFields: headerFields)
	}
}

