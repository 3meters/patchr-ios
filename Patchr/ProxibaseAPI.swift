//
//  ProxibaseAPI.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-20.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import CoreLocation

public class ProxibaseClient {
    
    private let sessionManager : AFHTTPSessionManager
    public var userId : NSString?
    public var sessionKey : NSString?
    
    public var authenticated : Bool {
        return (userId != nil && sessionKey != nil)
    }
    
    required public init() {
    
        let userDefaults = NSUserDefaults.standardUserDefaults()
        var serverURI = userDefaults.stringForKey("com.3meters.patchr.ios.serverURI")

        if serverURI == nil || serverURI?.utf16Count == 0 {
            serverURI = "https://api.aircandi.com/v1/"
            userDefaults.setObject(serverURI, forKey: "com.3meters.patchr.ios.serverURI")
        }
        self.sessionManager = AFHTTPSessionManager(baseURL: NSURL(string: serverURI!))
        let jsonSerializer = AFJSONRequestSerializer(writingOptions: nil)

        sessionManager.requestSerializer = jsonSerializer
        sessionManager.responseSerializer = JSONResponseSerializerWithData()
    }
    
    public func signIn(email: NSString, password : NSString, installId: NSString, completion:(userId: String?, sessionKey: String?, response: AnyObject?, error: NSError?) -> Void) {
        let parameters = ["email" : email, "password" : password, "installId" : installId]
        self.sessionManager.POST("auth/signin", parameters: parameters, success: { (dataTask, response) -> Void in
            let json = JSON(response)
            self.userId = json["session"]["_owner"].string
            self.sessionKey = json["session"]["key"].string
            completion(userId: self.userId, sessionKey: self.sessionKey, response: response, error: nil)
        }) { (dataTask, error) -> Void in
            completion(userId: nil, sessionKey: nil, response: error?.userInfo?[JSONResponseSerializerWithDataKey], error: error)
        }
    }
    
    public func signOut(completion:(response: AnyObject?, error: NSError?) -> Void) {
        if self.authenticated {
            self.performGETRequestFor("auth/signout", parameters: [:], completion: { (response, error) -> Void in
                if error == nil {
                    self.userId = nil;
                    self.sessionKey = nil;
                }
                completion(response: response, error: error)
            })
        } else {
            self.userId = nil;
            self.sessionKey = nil;
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion(response: nil, error: nil)
            })
        }
    }
    
    public func fetchNearby(location: CLLocationCoordinate2D, radius: NSInteger, limit: NSInteger, offset: NSInteger, links: [Link], completion:(response: AnyObject?, error: NSError?) -> Void) {
        let parameters = [
            "location" : [
                "lat" : location.latitude,
                "lng" : location.longitude
            ],
            "radius" : radius,
            "limit" : limit,
            "rest" : true,
            "linked" : links.map { $0.toDictionary() }
        ]
        self.performPOSTRequestFor("patches/near", parameters: parameters, completion: completion)
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
}