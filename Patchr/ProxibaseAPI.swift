//
//  ProxibaseAPI.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-20.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation

public class ProxibaseClient {
    
    private let sessionManager : AFHTTPSessionManager
    private(set) public var userId : NSString?
    private(set) public var sessionKey : NSString?
    
    public var authenticated : Bool {
        return (userId != nil && sessionKey != nil)
    }
    
    required public init() {
        self.sessionManager = AFHTTPSessionManager(baseURL: NSURL(string: "https://api.aircandi.com/v1/"))
        let jsonSerializer = AFJSONRequestSerializer(writingOptions: nil)

        sessionManager.requestSerializer = jsonSerializer
        sessionManager.responseSerializer = JSONResponseSerializerWithData()
    }
    
    public func signIn(email: NSString, password : NSString, installId: NSString, completion:(response: AnyObject?, error: NSError?) -> Void) {
        let parameters = ["email" : email, "password" : password, "installId" : installId]
        self.sessionManager.POST("auth/signin", parameters: parameters, success: { (dataTask, response) -> Void in
            let json = JSON(response)
            self.userId = json["session"]["_owner"].string
            self.sessionKey = json["session"]["key"].string
            completion(response: response, error: nil)
        }) { (dataTask, error) -> Void in
            completion(response: error?.userInfo?[JSONResponseSerializerWithDataKey], error: error)
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