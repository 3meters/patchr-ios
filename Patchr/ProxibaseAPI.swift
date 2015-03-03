//
//  ProxibaseAPI.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-20.
//  Copyright (c) 2015 3meters. All rights reserved.
//

//  The ProxibaseClient class is a singleton which mediates interaction with the Patchr server.
//
//  It uses and manages the following user default values:
//      com.3meters.patchr.ios.serverURI  - Server URI
//                            .userId     - The signed-in user's user id
//                            .sessionKey - The current session key
//
// • The userId and sessionKey are sent in API requests to authorize the request.
//
//

import Foundation
import CoreLocation

func PatchrUserDefaultKey(subKey: String) -> String
{
    return "com.3meters.patchr.ios." + subKey
}

public class ProxibaseClient {

    // Use this in Swift 1.2
    // static let sharedInstance = ProxibaseClient()
    
    // Else use this in Swift 1.1
    class var sharedInstance: ProxibaseClient {
        struct Static {
            static let instance: ProxibaseClient = ProxibaseClient()
        }
        return Static.instance
    }
    
    private let sessionManager : AFHTTPSessionManager
    
    public var userId : NSString?
    public var sessionKey : NSString?

    public var installId: String
    
    public var authenticated : Bool {
        return (userId != nil && sessionKey != nil)
    }
    
    
    required public init() {
    
        let userDefaults = NSUserDefaults.standardUserDefaults()
        var serverURI = userDefaults.stringForKey(PatchrUserDefaultKey("serverURI"))

        if serverURI == nil || serverURI?.utf16Count == 0 {
            serverURI = "https://api.aircandi.com/v1/"
            userDefaults.setObject(serverURI, forKey: "com.3meters.patchr.ios.serverURI")
        }
        self.sessionManager = AFHTTPSessionManager(baseURL: NSURL(string: serverURI!))

        sessionManager.requestSerializer = AFJSONRequestSerializer(writingOptions: nil)
        sessionManager.responseSerializer = JSONResponseSerializerWithData()
        
        userId     = userDefaults.stringForKey(PatchrUserDefaultKey("userId"))
        sessionKey = userDefaults.stringForKey(PatchrUserDefaultKey("sessionKey"))
        
        installId = "1" // TODO
        
    }
    
    private func writeCredentialsToUserDefaults()
    {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(userId, forKey: PatchrUserDefaultKey("userId"))
        userDefaults.setObject(sessionKey, forKey: PatchrUserDefaultKey("sessionKey"))
    }
    
    // Send an auth/signin message to the server with the user's email address and password.
    // The completion block will be called asynchronously in either case.
    // If signin is successful, then the credentials from the server will be written to user defaults
    
    public func signIn(email: NSString, password : NSString, completion:(response: AnyObject?, error: NSError?) -> Void)
    {
        let parameters = ["email" : email, "password" : password, "installId" : installId]
        self.sessionManager.POST("auth/signin", parameters: parameters,
            success: { (dataTask, response) -> Void in
                let json = JSON(response)
                
                self.userId = json["session"]["_owner"].string
                self.sessionKey = json["session"]["key"].string
                self.writeCredentialsToUserDefaults()
                
                completion(response: response, error: nil)
            },
            failure: { (dataTask, error) -> Void in
                completion(response: error?.userInfo?[JSONResponseSerializerWithDataKey], error: error)
        })
    }
    
    // Send an auth/signout message. 
    //
    // Discard credentials whether or not the server thinks we are signed out.
    // The completion closure is always performed asynchronously.
    
    public func signOut(completion:(response: AnyObject?, error: NSError?) -> Void)
    {
        if self.authenticated {
            self.performGETRequestFor("auth/signout", parameters: [:],
                completion: { (response, error) -> Void in
                    if error == nil {
                        self.userId = nil;
                        self.sessionKey = nil;
                        self.writeCredentialsToUserDefaults()
                    }
                    
                    completion(response: response, error: error)
                })
        } else {
            self.userId = nil;
            self.sessionKey = nil;
            writeCredentialsToUserDefaults()
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion(response: nil, error: nil)
            })
        }
    }
    
    public func fetchNearbyPatches(location: CLLocationCoordinate2D, radius: NSInteger, limit: NSInteger, skip: NSInteger, links: [Link], completion:(response: AnyObject?, error: NSError?) -> Void) {
        let parameters = [
            "location" : [
                "lat" : location.latitude,
                "lng" : location.longitude
            ],
            "radius" : radius,
            "limit" : limit,
            "skip" : skip,
            "rest" : true,
            "linked" : links.map { $0.toDictionary() }
        ]
        self.performPOSTRequestFor("patches/near", parameters: parameters, completion: completion)
    }
    
    public func fetchNotifications(limit: NSInteger, skip: NSInteger, completion:(response: AnyObject?, error: NSError?) -> Void) {
        let parameters : Dictionary<String, AnyObject> = [
            "entityId" : self.userId ?? "",
            "cursor" : [
                "sort" : ["modifiedDate" : -1],
                "skip" : skip,
                "limit" : limit
            ]
        ]
        self.performPOSTRequestFor("do/getNotifications", parameters: parameters, completion: completion)
    }
    
    public func performPOSTRequestFor(path: NSString, var parameters : NSDictionary, completion:(response: AnyObject?, error: NSError?) -> Void) {
        if self.authenticated {
            var authParameters = NSMutableDictionary(dictionary: ["user" : self.userId!, "session" : self.sessionKey!])
            authParameters.addEntriesFromDictionary(parameters)
            parameters = authParameters
        }
        self.sessionManager.POST(path, parameters: parameters,
            success: { (dataTask, response) -> Void in
                completion(response: response, error: nil)
        }) { (dataTask, error) -> Void in
            let response = dataTask.response as? NSHTTPURLResponse
            completion(response: error?.userInfo?[JSONResponseSerializerWithDataKey], error: error)
        }
    }
    
    public func performGETRequestFor(path: NSString, var parameters : NSDictionary, completion:(response: AnyObject?, error: NSError?) -> Void) {
        if self.authenticated {
            var authParameters = NSMutableDictionary(dictionary: ["user" : self.userId!, "session" : self.sessionKey!])
            authParameters.addEntriesFromDictionary(parameters)
            parameters = authParameters
        }
        self.sessionManager.GET(path, parameters: parameters,
            success: { (dataTask, response) -> Void in
                completion(response: response, error: nil)
            }) { (dataTask, error) -> Void in
                let response = dataTask.response as? NSHTTPURLResponse
                completion(response: error?.userInfo?[JSONResponseSerializerWithDataKey], error: error)
        }
    }
}

public class Link {
    public var to: LinkDestination?
    public var from: LinkDestination?
    public var type: LinkType?
    public var limit: UInt?
    public var count: Bool?
    
    init(to: LinkDestination, type: LinkType, limit: UInt?, count: Bool?) {
        self.to = to
        self.type = type
        self.limit = limit
        self.count = count
    }
    
    init(from: LinkDestination, type: LinkType, limit: UInt?, count: Bool?) {
        self.from = from
        self.type = type
        self.limit = limit
        self.count = count
    }
    
    func toDictionary() -> Dictionary<String, AnyObject> {
        var dictionary = Dictionary<String,AnyObject>()
        if to != nil {
            dictionary["to"] = to!.rawValue
        }
        if from != nil {
            dictionary["from"] = from!.rawValue
        }
        if type != nil {
            dictionary["type"] = type!.rawValue
        }
        if limit != nil {
            dictionary["limit"] = limit!
        }
        if count != nil {
            dictionary["count"] = count!
        }
        return dictionary
    }
}

public enum LinkDestination : String {
    case Beacons = "beacons"
    case Places = "places"
    case Messages = "messages"
    case Users = "users"
}

public enum LinkType : String {
    case Proximity = "proximity"
    case Content = "content"
    case Like = "like"
    case Watch = "watch"
    case Create = "create"
    case Share = "share"
}
