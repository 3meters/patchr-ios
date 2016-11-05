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
import UIKit
import AFNetworking
import Keys
import UIDevice_Hardware
import FirebaseRemoteConfig
import Firebase

/*
 * Access control is set to public because that is the only way that
 * unit tests can use this class.
 */
public class Proxibase {

    public typealias CompletionBlock = (_ response: Any?, _ error: NSError?) -> Void

    let StagingURI		= "http://api.ariseditions.com:8080/v1/"
    let ProductionURI	= "https://api.aircandi.com/v1/"
    let serviceUri: String!

    let pageSizeDefault			: Int = 50
    let pageSizeNearby			: Int = 50
    let pageSizeExplore			: Int = 50
    let pageSizeNotifications	: Int = 50

    var versionIsValid			= true

    private let sessionManager: AFHTTPSessionManager

    required public init() {

        var serviceUri = UserDefaults.standard.string(forKey: PatchrUserDefaultKey(subKey: "serverUri"))
        if serviceUri == nil {
            serviceUri = ProductionURI
            UserDefaults.standard.set(serviceUri, forKey: PatchrUserDefaultKey(subKey: "serverUri"))
        }
        
        self.serviceUri = serviceUri

        sessionManager = AFHTTPSessionManager(baseURL: NSURL(string: serviceUri!) as URL? as URL?)
        sessionManager.requestSerializer = AFJSONRequestSerializer()
        sessionManager.requestSerializer.timeoutInterval = TimeInterval(TIMEOUT_REQUEST)
        sessionManager.responseSerializer = JSONResponseSerializerWithData()
        sessionManager.completionQueue = DataController.instance.backgroundDispatch
    }

    /*--------------------------------------------------------------------------------------------
     * PUBLIC: Fetch one
     *--------------------------------------------------------------------------------------------*/

    public func fetchPatchById(entityId: String, criteria: [String:Any], completion: @escaping CompletionBlock) {

        var parameters: [String:Any] = [:]
        Patch.extras(parameters: &parameters)
        if !criteria.isEmpty {
            parameters["query"] = criteria as AnyObject?
        }
        performPOSTRequestFor(path: "find/patches/\(entityId)", parameters: parameters, completion: completion)
    }

    public func fetchMessageById(messageId: String, criteria: [String:Any], completion: @escaping CompletionBlock) {

        var parameters: [String:Any] = [:]
        Message.extras(parameters: &parameters)
        if !criteria.isEmpty {
            parameters["query"] = criteria as AnyObject?
        }
        performPOSTRequestFor(path: "find/messages/\(messageId)", parameters: parameters, completion: completion)
    }

    public func fetchUserById(userId: String, criteria: [String:Any], completion: @escaping CompletionBlock) {

        var parameters: [String:Any] = [:]
        User.extras(parameters: &parameters)
        if !criteria.isEmpty {
            parameters["query"] = criteria as AnyObject?
        }
        performPOSTRequestFor(path: "find/users/\(userId)", parameters: parameters, completion: completion)
    }

    /*--------------------------------------------------------------------------------------------
    * PUBLIC: Fetch collection
    *--------------------------------------------------------------------------------------------*/

    public func fetchNearbyPatches(location: CLLocationCoordinate2D?, radius: UInt = 10000, skip: Int = 0, completion: @escaping CompletionBlock) {

        if let loc = location as CLLocationCoordinate2D! {
            var parameters: [String:Any] = [
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
            Patch.extras(parameters: &parameters)
            performPOSTRequestFor(path: "patches/near", parameters: parameters, completion: completion)
        }
    }

    public func fetchNotifications(skip: Int = 0, completion: @escaping CompletionBlock) {

        let parameters: [String : Any] = [
            "limit": pageSizeNotifications,
            "skip": skip,
            "more": true,
        ]
        performPOSTRequestFor(path: "user/getNotifications", parameters: parameters, completion: completion)
    }

    public func fetchInterestingPatches(skip: Int = 0, completion: @escaping CompletionBlock) {

        var parameters: [String:Any] = [
            "limit": pageSizeExplore,
            "skip": skip,
            "more": true,
        ]

        Patch.extras(parameters: &parameters)
        performPOSTRequestFor(path: "patches/interesting", parameters: parameters, completion: completion)
    }

    public func fetchMessagesOwnedByUser(userId: String, criteria: [String:Any] = [:], skip: Int = 0, completion: @escaping CompletionBlock) {

        var linked: [String:Any] = ["to": "messages", "type": "create", "limit": pageSizeDefault, "skip": skip, "more": true]
        Message.extras(parameters: &linked)
        var parameters: [String:Any] = [
                "linked": linked,
                "promote": "linked",
        ]
        if !criteria.isEmpty {
            parameters["query"] = criteria as AnyObject?
        }
        performPOSTRequestFor(path: "find/users/\(userId)", parameters: parameters, completion: completion)
    }

    public func fetchPhotosForPatch(patchId: String, criteria: [String:Any] = [:], limit: Int, skip: Int = 0, completion: @escaping CompletionBlock) {

        var linked: [String:Any] = [
            "from": "messages" as Any,
            "limit": limit as Any,
            "linkedFilter": ["photo":["$exists": true]],
            "more": true,
            "refs": ["_creator":"_id,name,photo,schema,type"],
            "skip": skip,
            "type": "content",
            "fields": "createdDate,description,photo,_creator"
        ]

        let userDefaults = UserDefaults.standard
        if let userId = userDefaults.string(forKey: PatchrUserDefaultKey(subKey: "userId")) {
            let links = [
                LinkSpec(from: .Users, type: .Like, fields: "_id,type", filter: ["_from": userId])	// Has the current user liked the message
            ]
            let array = links.map {
                $0.toDictionary() // Returns an array of maps
            }
            linked["links"] = array
        }

        let parameters: [String:Any] = [
            "linked": linked,
            "promote": "linked",
        ]

        performPOSTRequestFor(path: "find/patches/\(patchId)", parameters: parameters, completion: completion)
    }

    public func fetchMessagesForPatch(patchId: String, criteria: [String:Any] = [:], skip: Int = 0, completion: @escaping CompletionBlock) {

        var linked:     [String: Any] = ["from": "messages", "type": "content", "limit": pageSizeDefault, "skip": skip, "more": true]
        Message.extras(parameters: &linked)
        var parameters: [String: Any] = [
            "linked": linked,
            "promote": "linked",
        ]
        if !criteria.isEmpty {
            parameters["query"] = criteria
        }
        performPOSTRequestFor(path: "find/patches/\(patchId)", parameters: parameters, completion: completion)
    }

    public func fetchPatchesOwnedByUser(userId: String, criteria: [String:Any] = [:], skip: Int = 0, completion: @escaping CompletionBlock) {

        var linked:     [String:Any] = ["to": "patches", "type": "create", "limit": pageSizeDefault, "skip": skip, "more": true]
        Patch.extras(parameters: &linked)
        var parameters: [String:Any] = [
            "linked": linked,
            "promote": "linked",
        ]
        if !criteria.isEmpty {
            parameters["query"] = criteria
        }
        performPOSTRequestFor(path: "find/users/\(userId)", parameters: parameters, completion: completion)
    }

    public func fetchPatchesUserIsWatching(userId: String, criteria: [String:Any] = [:], skip: Int = 0, completion: @escaping CompletionBlock) {

        var linked:     [String:Any] = ["to": "patches", "type": "watch", "limit": pageSizeDefault, "skip": skip, "more": true, "linkFields": "type,enabled"]
        Patch.extras(parameters: &linked)
        var parameters: [String:Any] = [
            "linked": linked,
            "promote": "linked",
        ]
        if !criteria.isEmpty {
            parameters["query"] = criteria
        }
        performPOSTRequestFor(path: "find/users/\(userId)", parameters: parameters, completion: completion)
    }

    public func fetchUsersFavoritePatches(userId: String, criteria: [String:Any] = [:], skip: Int = 0, completion: @escaping CompletionBlock) {

        var linked:     [String:Any] = ["to": "patches", "type": "like", "limit": pageSizeDefault, "skip": skip, "more": true]
        Patch.extras(parameters: &linked)
        var parameters: [String:Any] = [
            "linked": linked,
            "promote": "linked",
        ]
        if !criteria.isEmpty {
            parameters["query"] = criteria
        }
        performPOSTRequestFor(path: "find/users/\(userId)", parameters: parameters, completion: completion)
    }

    public func fetchUsersThatWatchPatch(patchId: String, isOwner: Bool = false, criteria: [String:Any] = [:], skip: Int = 0, completion: @escaping CompletionBlock) {

        /* Used to show a list of users that are watching a patch or have a pending watch request for the patch. */
        var linked: [String:Any] = ["from": "users", "type": "watch", "limit": pageSizeDefault, "skip": skip, "more": true, "linkFields": "type,enabled"]
        if !isOwner {
            linked["filter"] = ["enabled": true]
        }
        User.extras(parameters: &linked)
        var parameters: [String:Any] = [
            "linked": linked,
            "promote": "linked",
        ]
        if !criteria.isEmpty {
            parameters["query"] = criteria
        }
        performPOSTRequestFor(path: "find/patches/\(patchId)", parameters: parameters, completion: completion)
    }

    public func fetchUsersThatLikeMessage(messageId: String, criteria: [String:Any] = [:], skip: Int = 0, completion: @escaping CompletionBlock) {

        /* Used to show a list of users that currently like a message. */
        var linked:     [String:Any] = ["from": "users", "type": "like", "limit": pageSizeDefault, "skip": skip, "more": true]
        User.extras(parameters: &linked)
        var parameters: [String:Any] = [
            "linked": linked,
            "promote": "linked",
        ]
        if !criteria.isEmpty {
            parameters["query"] = criteria
        }
        performPOSTRequestFor(path: "find/messages/\(messageId)", parameters: parameters, completion: completion)
    }

    /*--------------------------------------------------------------------------------------------
     * PUBLIC: Modify
     *--------------------------------------------------------------------------------------------*/

    public func postEntity(path: String, parameters: [String:Any], completion: @escaping CompletionBlock) -> URLSessionTask {

        var parameters = parameters
        convertLocationProperties(properties: &parameters)
        if parameters["data"] == nil {
            parameters = ["data": parameters]
        }
        let request: URLSessionTask = self.performPOSTRequestFor(path: path, parameters: parameters, completion: completion)
        return request
    }

    public func deleteObject(path: String, completion: @escaping CompletionBlock) {
        performDELETERequestFor(path: path, parameters: [:] as [String : Any], completion: completion)
    }

    public func insertLink(fromID: String, toID: String, linkType: LinkType, completion: @escaping CompletionBlock) {
        
        let linkParameters: [String:Any] = [
            "_from": fromID,
            "_to": toID,
            "type": linkType.rawValue
        ]

        let postParameters = ["data": linkParameters]

        performPOSTRequestFor(path: "data/links", parameters: postParameters) {
            response, error in
            completion(response, error)
        }
    }

    public func enableLinkById(linkId: String, enabled: Bool, completion: @escaping CompletionBlock) {
        let parameters = ["data": ["enabled": enabled]]
        performPOSTRequestFor(path: "data/links/\(linkId)", parameters: parameters, completion: completion)
    }

    public func muteLinkById(linkId: String, muted: Bool, completion: @escaping CompletionBlock) {
        let parameters = ["data": ["mute": muted]]
        performPOSTRequestFor(path: "data/links/\(linkId)", parameters: parameters, completion: completion)
    }

    public func deleteLinkById(linkID: String, completion: CompletionBlock? = nil) {
        let linkPath = "data/links/\(linkID)"
        performDELETERequestFor(path: linkPath, parameters: [:] as [String : Any]) {
            response, error in
            if let completionBlock = completion {
                completionBlock(response, error)
            }
        }
    }

    public func deleteLink(fromId: String, toId: String, linkType: LinkType, completion: CompletionBlock? = nil) {

        /* We are not encoding the query string because we know that all of the characters are valid */
        let queryString = "query[_to]=\(toId)&query[_from]=\(fromId)&query[type]=\(linkType.rawValue)"
        let linkPath = "data/links?\(queryString)"

        performDELETERequestFor(path: linkPath, parameters: [:] as [String : Any]) {
            response, error in
            if let completionBlock = completion {
                completionBlock(response, error)
            }
        }
    }

    /*--------------------------------------------------------------------------------------------
    * PUBLIC: Bing
    *--------------------------------------------------------------------------------------------*/

    public func loadSearchImages(query: String, count: Int64 = 50, offset: Int64 = 0, completion: @escaping CompletionBlock) {
        
        Log.d("Image search count: \(count), offset: \(offset) ")

        let bingSessionManager: AFHTTPSessionManager = AFHTTPSessionManager(baseURL: NSURL(string: URI_PROXIBASE_SEARCH_IMAGES) as URL?)
        let requestSerializer: AFJSONRequestSerializer = AFJSONRequestSerializer()
        let bingKey = FIRRemoteConfig.remoteConfig().configValue(forKey: "bing_subscription_key").stringValue!

        requestSerializer.setValue(bingKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        bingSessionManager.requestSerializer = requestSerializer
        bingSessionManager.responseSerializer = JSONResponseSerializerWithData()

        let queryEncoded: String = query.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
        let bingUrl = "images/search?q=%27" + queryEncoded + "%27"
                + "&mkt=en-us&safeSearch=strict&size=large"
                + "&count=\(count + 1)"
                + "&offset=\(offset)"

        bingSessionManager.get(bingUrl, parameters: nil,
                               success: {
                                   dataTask, response in
                                   completion(response, nil)
                               },
                               failure: {
                                dataTask, error in
                                   completion(nil, error as NSError)
                               })
    }

    /*--------------------------------------------------------------------------------------------
     * User and install
     *--------------------------------------------------------------------------------------------*/

    public func validEmail(email: String, completion: @escaping CompletionBlock) {

        let emailString = (CFURLCreateStringByAddingPercentEscapes(nil, email as NSString, nil, ":/?@!$&'()*+,;=" as NSString, CFStringConvertNSStringEncodingToEncoding(String.Encoding.utf8.rawValue)) as NSString) as String

        sessionManager.get("find/users?q[email]=\(emailString)", parameters: nil,
            success: {
                dataTask, response in
                completion(response, nil)
            },
            failure: {
                dataTask, error in
                completion(nil, error as NSError)
        })
    }

    public func login(email: String, password: String, completion: @escaping CompletionBlock) {
        /*
        * Send an auth/signin message to the server with the user's email address and password.
        * The completion block will be called asynchronously in either case.
        * If signin is successful, then the credentials from the server will be written to user defaults
        */
        var parameters: [String: Any] = ["email": email, "password": password]
        if let installId = NotificationController.instance.installId {
            parameters["installId"] = installId
        }

        sessionManager.post("auth/signin", parameters: parameters,
            success: {
                dataTask, response in
                ZUserController.instance.handleSuccessfulLoginResponse(response: response)
                completion(response, nil)
            },
            failure: {
                dataTask, error in
                completion(nil, error as NSError)
        })
    }

    public func logout(completion: @escaping CompletionBlock) {
        /*
        * Send an auth/signout message.
        *
        * Discard credentials whether or not the server thinks we are signed out.
        * The completion closure is always performed asynchronously.
        */
        performGETRequestFor(path: "auth/signout", parameters: [:]) {
            (response: Any?, error: NSError?) in
            completion(response, error)
        }
    }

    public func updatePassword(userId: String, password: String, passwordNew: String, completion: @escaping CompletionBlock) {
        
        var parameters: [String:Any] = [
            "userId": userId,
            "oldPassword": password,
            "newPassword": passwordNew
        ]
        
        if let installId = NotificationController.instance.installId {
            parameters["installId"] = installId
        }

        sessionManager.post("user/pw/change", parameters: addSessionParameters(parameters: parameters),
            success: {
                dataTask, response in
                ZUserController.instance.handlePasswordChange(response: response)
                completion(response, nil)
            },
            failure: {
                dataTask, error in
                completion(nil, error as NSError)
        })
    }

    public func requestPasswordReset(email: NSString, completion: @escaping CompletionBlock) {
        
        var parameters: [String: Any] = ["email": email]
        
        if let installId = NotificationController.instance.installId {
            parameters["installId"] = installId
        }

        sessionManager.post("user/pw/reqreset", parameters: parameters,
            success: {
                dataTask, response in
                completion(response, nil)
            },
            failure: {
                dataTask, error in
                completion(nil, error as NSError)
        })
    }

    public func resetPassword(password: NSString, token: NSString, completion: @escaping CompletionBlock) {
        
        var parameters: [String: Any] = ["token": token, "password": password]
        
        if let installId = NotificationController.instance.installId {
            parameters["installId"] = installId
        }

        sessionManager.post("user/pw/reset", parameters: parameters,
            success: {
                dataTask, response in
                ZUserController.instance.handleSuccessfulLoginResponse(response: response)
                completion(response, nil)
            },
            failure: {
                dataTask, error in
                completion(nil, error as NSError)
        })
    }

    public func preflight(completion: @escaping CompletionBlock) {
        let parameters: [String: Any] = [:]
        sessionManager.get("client", parameters: addSessionParameters(parameters: parameters),
            success: {
                dataTask, response in
                completion(response, nil)
            },
            failure: {
                dataTask, error in
                completion(nil, error as NSError)
        })
    }

    public func registerInstall(completion: @escaping CompletionBlock) {
        /*
         * These properties will be updated if the install already exists.
         */
        let installId         = NotificationController.instance.installId!
        let pushInstallId     = NotificationController.instance.installId!
        let clientVersionName = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let clientVersionCode = Int(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String)!
        let clientPackageName = Bundle.main.bundleIdentifier!
        let deviceName        = UIDevice.current.modelIdentifier()
        let deviceType        = "ios"
        let deviceVersionName = UIDevice.current.systemVersion

        let parameters: NSDictionary = [
            "install":
                [
                    "installId": installId,
                    "pushInstallId": pushInstallId,
                    "clientVersionName": clientVersionName,
                    "clientVersionCode": clientVersionCode,
                    "clientPackageName": clientPackageName,
                    "deviceName": deviceName,
                    "deviceType": deviceType,
                    "deviceVersionName": deviceVersionName
            ]
        ]
        performPOSTRequestFor(path: "do/registerInstall", parameters: parameters as! [String : Any], completion: completion)
    }

    private func addSessionParameters(parameters inParameters: [String:Any]) -> [String:Any] {
        /* Skip if already includes a sessionKey */
        var parameters = inParameters
        if parameters["session"] == nil {
            parameters["session"] = ZUserController.instance.sessionKey
            parameters["user"] = ZUserController.instance.userId
        }
        return parameters
    }

    /*--------------------------------------------------------------------------------------------
     * Rest
     *--------------------------------------------------------------------------------------------*/
    
    @discardableResult private func performPOSTRequestFor(path: String, parameters inParameters: [String:Any], completion: @escaping CompletionBlock) -> URLSessionTask {

        var parameters = inParameters
        parameters = addSessionParameters(parameters: parameters)

        let request: URLSessionTask = sessionManager.post(path, parameters: parameters,
                            success: {
                                dataTask, response in
                                completion(response, nil)
                            },
                            failure: {
                                dataTask, error in
                                completion(nil, error as NSError)
                            })!
        return request
    }

    private func performGETRequestFor(path: String, parameters: [String:Any], completion: @escaping CompletionBlock) {
        sessionManager.get(path, parameters: addSessionParameters(parameters: parameters),
                           success: {
                               dataTask, response in
                               completion(response, nil)
                           },
                           failure: {
                               dataTask, error in
                               completion(nil, error as NSError)
                           })
    }

    private func performDELETERequestFor(path: String, parameters: [String:Any], completion: @escaping CompletionBlock) {
        sessionManager.delete(path, parameters: addSessionParameters(parameters: parameters),
                              success: {
                                  dataTask, response in
                                  completion(response, nil)
                              },
                              failure: {
                                  dataTask, error in
                                  completion(nil, error as NSError)
                              })
    }

    /*--------------------------------------------------------------------------------------------
     * Helpers
     *--------------------------------------------------------------------------------------------*/

    private func convertLocationProperties( properties: inout [String:Any]) {
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

                    self.response = responseErrorDictionary

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
        precondition(resultCount == 1, "resultObject called when there are more than one result objects")

        if let resultDict = responseDictionary["data"] as? NSDictionary {
            return resultDict
        }

        if let resultArray = responseDictionary["data"] as? NSArray {
            return resultArray[0] as! NSDictionary
        }

        precondition(false, "Unexpected result")

        return NSDictionary()
    }

    var resultID: String {
        get {
            return resultObject["_id"] as! String
        }
    }

    init(_ responseObject: AnyObject?) {
        responseDictionary = responseObject as! NSDictionary
        resultCount = (responseDictionary["count"] as! NSNumber).intValue
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
    public var filter:       [String:Any]?
    public var fields:       Any?
    public var linkFields:   Any?
    public var linkedFilter: [String:Any]?
    public var linked:       [LinkSpec]?
    public var links:        [LinkSpec]?
    public var linkCounts:   [LinkSpec]?
    public var refs:		 [String:Any]?

    init(to: LinkDestination, type: LinkType, enabled: Bool? = nil, limit: UInt? = nil, count: Bool? = nil,
         fields: Any? = nil, filter: [String:Any]? = nil,
         linkFields: Any? = nil, linkedFilter: [String:Any]? = nil,
         linked: [LinkSpec]? = nil, links: [LinkSpec]? = nil, linkCounts: [LinkSpec]? = nil, refs: [String:Any]? = nil) {
        
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
        self.linkCounts = linkCounts
        self.refs = refs
    }

    init(from: LinkDestination, type: LinkType, enabled: Bool? = nil, limit: UInt? = nil, count: Bool? = nil,
         fields: Any? = nil, filter: [String:Any]? = nil,
         linkFields: Any? = nil, linkedFilter: [String:Any]? = nil,
         linked: [LinkSpec]? = nil, links: [LinkSpec]? = nil, linkCounts: [LinkSpec]? = nil, refs: [String:Any]? = nil) {
        
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
        self.linkCounts = linkCounts
        self.refs = refs
    }

    func toDictionary() -> Dictionary<String, Any> {
        var dictionary = Dictionary<String, Any>()
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
        if linkCounts != nil {
            dictionary["linkCounts"] = linkCounts!.map {
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
        return inRange(range: Range(uncheckedBounds: (lower: 100, upper: 199)))
    }
    /// Success - The action was successfully received, understood, and accepted.
    var isSuccess: Bool {
        return inRange(range: Range(uncheckedBounds: (lower: 200, upper: 299)))
    }
    /// Redirection - Further action must be taken in order to complete the request.
    var isRedirection: Bool {
        return inRange(range: Range(uncheckedBounds: (lower: 300, upper: 399)))
    }
    /// Client Error - The request contains bad syntax or cannot be fulfilled.
    var isClientError: Bool {
        return inRange(range: Range(uncheckedBounds: (lower: 400, upper: 499)))
    }
    /// Server Error - The server failed to fulfill an apparently valid request.
    var isServerError: Bool {
        return inRange(range: Range(uncheckedBounds: (lower: 500, upper: 599)))
    }

    /// :returns: true if the status code is in the provided range, false otherwise.
    private func inRange(range: Range<Int>) -> Bool {
        return range.contains(rawValue)
    }
}

extension HTTPStatusCode {
    var localizedReasonPhrase: String {
        return HTTPURLResponse.localizedString(forStatusCode: rawValue)
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
    init?(HTTPResponse: HTTPURLResponse?) {
        if let value = HTTPResponse?.statusCode {
            self.init(rawValue: value)
        }
        else {
            return nil
        }
    }
}

extension HTTPURLResponse {
    var statusCodeValue: HTTPStatusCode? {
        return HTTPStatusCode(HTTPResponse: self)
    }

    //    @available(iOS, introduced : 7.0)
    //convenience init?(URL url: NSURL, statusCode: HTTPStatusCode, HTTPVersion: String?, headerFields: [String: String]?) {
    //        self(url: url as URL, statusCode: statusCode.rawValue, httpVersion: HTTPVersion, headerFields: headerFields)
    //}
}

