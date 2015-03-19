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

enum ServerStatusCode : Float {

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
}

// Given an NSError from AFNetworking, provide simple access to a select few pieces of information that
// should be there.
//
// userInfo: {
//      JSONResponseSerializerWithDataKey: {
//          error: {
//              code: Double,
//              message: String,
//          }
//      },
//      NSLocalizedDescription: String


struct ServerError
{
    let error: NSError
    
    var response: NSDictionary?
    var message = LocalizedString("Unknown Error")
    var code: ServerStatusCode = .None
    var localizedDescription = LocalizedString("(No Description)")
    
    init?(_ error: NSError?)
    {
        if let error = error {
            self.error = error
            let userInfoDictionary = (error.userInfo as NSDictionary?)
            
            response = (userInfoDictionary?[JSONResponseSerializerWithDataKey] as NSDictionary?)
            let responseErrorDictionary = response?["error"] as NSDictionary?

            if let responseDict = responseErrorDictionary {
                if let responseMessage = responseDict["message"] as? String {
                    message = responseMessage
                }
                if let responseCode = responseDict["code"] as? Float {
                    code = ServerStatusCode(rawValue: responseCode)!
                }
            }
            if let userInfo = userInfoDictionary
            {
                if let description = userInfo["NSLocalizedDescription"] as? String {
                    localizedDescription = description
                }
            }
            
            println("Proxibase Error Summary")
            println(message)
            println(code)
            println(localizedDescription)
        }
        else
        {
            return nil
        }
    }
}

// The JSON response serializer produces an NSDictionary. This class wraps it and provides more consistent and
// less casty access to things we care about.

struct ServerResponse
{
    var responseDictionary: NSDictionary
    
    var resultCount: Int
    
    init(_ responseObject: AnyObject?)
    {
        responseDictionary = responseObject as NSDictionary
        println(responseDictionary)
        resultCount = (responseDictionary["count"] as NSNumber).integerValue
        
    }
    
    var resultObjects: NSArray
    {
        get {
            if resultCount == 0 {
                return NSArray()
            }
            else if resultCount == 1 {
                return NSArray(object: responseDictionary["data"] as NSDictionary)
            }
            else {
                return responseDictionary["data"] as NSArray
            }
        }
    }
    
    // Single-result accessors
    //
    var resultObject: NSDictionary {
        assert(resultCount == 1, "resultObject called when there are more than one result objects")
        if let resultDict = responseDictionary["data"] as? NSDictionary
        {
            return resultDict
        }
        if let resultArray = responseDictionary["data"] as? NSArray
        {
            return resultArray[0] as NSDictionary
        }
        
        assert(false, "Unexpected result")

        return NSDictionary()
    }
    
    var resultID: String {
        get {
            return self.resultObject["_id"] as String
        }
    }
    
    // Given a response from the server, iterate over all the objects returned in the "data" result field.
    
    func forEachResultObject(block:(NSDictionary) -> Void)
    {
        for object in self.resultObjects
        {
            block(object as NSDictionary)
        }
    }

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
    
    private let sessionManager: AFHTTPSessionManager

    public var userId : NSString?
    public var sessionKey : NSString?
    
    public var installId: String
    
    public var authenticated : Bool {
        return (userId != nil && sessionKey != nil)
    }
    
    public let StagingURI = "https://api.aircandi.com:8443/v1/"
    public let ProductionURI = "https://api.aircandi.com/v1/"
    
    public var categories = [String:NSDictionary]()
    
    required public init() {
    
        let userDefaults = NSUserDefaults.standardUserDefaults()
        var serverURI = userDefaults.stringForKey(PatchrUserDefaultKey("serverURI"))

        if serverURI == nil || serverURI?.utf16Count == 0 {
            serverURI = StagingURI
            userDefaults.setObject(serverURI, forKey: PatchrUserDefaultKey("serverURI"))
        }

        userId     = userDefaults.stringForKey(PatchrUserDefaultKey("userId"))
        sessionKey = userDefaults.stringForKey(PatchrUserDefaultKey("sessionKey")) // TODO: We should store this more securely
        
        installId = "1"
        
        sessionManager = AFHTTPSessionManager(baseURL: NSURL(string: serverURI!))

        sessionManager.requestSerializer = AFJSONRequestSerializer(writingOptions: nil)
        sessionManager.responseSerializer = JSONResponseSerializerWithData()
        
        self.fetchAllCategories() { response, error in

            if let serverError = ServerError(error)
            {
                // TODO: Default is "place" now.
                self.categories = ["general":["id":"general","name":"General","photo": ["prefix":"img_group.png","source":"assets.categories"]]]
            }
            else
            {
                dispatch_async(dispatch_get_main_queue())
                {
                    var categories = [String:NSDictionary]()

                    let serverResponse = ServerResponse(response)
                    
                    serverResponse.forEachResultObject { resultObject in
                    
                        var mutableObject = resultObject.mutableCopy() as NSMutableDictionary
                        // The server returns us an empty array of "categories" for each category, but will not
                        // accept these from us, so remove them here.
                        mutableObject.removeObjectForKey("categories")
                        categories[mutableObject["id"] as NSString] = mutableObject
                    }
                    self.categories = categories
                }
            }
        }
    }
    
// MARK: S3 Uploading
//
//      {
//          key: 'AKIAIYU2FPHC2AOUG3CA',
//          secret: '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',
//          region: 'us-west-2',
//          bucket: 'aircandi-images',
//      }
    private let PatchrS3Key    = "AKIAIYU2FPHC2AOUG3CA"
    private let PatchrS3Secret = "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"
    
    public typealias S3UploadCompletionBlock = (/*result*/AnyObject?, NSError?) -> Void
    
    public func uploadImageToS3(image:UIImage, bucket:String, key:String, completion:S3UploadCompletionBlock)
    {
        if let imageURL = TemporaryFileURLForImage(image) {
            uploadFileToS3(imageURL, contentType: "image/jpeg", bucket: bucket, key: key) { result, error in
                completion(result, error)
                
                NSFileManager.defaultManager().removeItemAtURL(imageURL, error: nil)
            }
        }
    }
    
    // Uploads a file from the local file URL to the specified bucket in the 3meters S3 storage space. The file is stored with
    // the provided key.
    //
    // The upload occurs asynchronously and when completed, the completion block will be called with a result and error arguments.
    // A successful result includes information like the following in the result argument of the S3UploadCompletionBlock
    //
    // Optional(<AWSS3TransferManagerUploadOutput: 0x7fc580c79b90> {
    //     ETag = "\"6f2a09d19a6ae845d5916de4543984e5\"";
    //     serverSideEncryption = 0;
    //     versionId = 8JYaCWNaozIQIhF2pR1xYFy6W8hhbFPP;
    // })

    public func uploadFileToS3(fileURL: NSURL, contentType: String, bucket: String, key: String, completion:S3UploadCompletionBlock)
    {
        // NOTE: I can't get Swift to recognize the enum values for AWSRegionTypes and AWSS3ObjectCannedACLs, so I have used
        // rawValue: initializers here.
        
        let credProvider = AWSStaticCredentialsProvider.credentialsWithAccessKey(PatchrS3Key, secretKey: PatchrS3Secret)
        let serviceConfig = AWSServiceConfiguration(region: AWSRegionType(rawValue: 3/*'us-west-2'*/)!, credentialsProvider: credProvider)

        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest.bucket = bucket
        uploadRequest.key = key
        uploadRequest.body = fileURL
        uploadRequest.ACL = AWSS3ObjectCannedACL(rawValue: 2/*AWSS3ObjectCannedACLPublicRead*/)!
        uploadRequest.contentType = contentType
        
        let transferManager = AWSS3TransferManager(configuration: serviceConfig, identifier: "AWS-Patcher")

        let task = transferManager.upload(uploadRequest)
        
        task.continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: { (task) -> AnyObject! in
            completion(task.result, task.error)
            
            return nil // return nil to indicate the task is complete
        })
    }

    
    private func writeCredentialsToUserDefaults()
    {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(userId, forKey: PatchrUserDefaultKey("userId"))
        userDefaults.setObject(sessionKey, forKey: PatchrUserDefaultKey("sessionKey"))
    }

    private func discardCredentials()
    {
        userId = nil;
        sessionKey = nil;
        writeCredentialsToUserDefaults()
    }
    
    private func handleSuccessfulSignInResponse(response: AnyObject)
    {
        let json = JSON(response)
        
        self.userId = json["session"]["_owner"].string
        self.sessionKey = json["session"]["key"].string
        
        self.writeCredentialsToUserDefaults()
    }
    
    // Send an auth/signin message to the server with the user's email address and password.
    // The completion block will be called asynchronously in either case.
    // If signin is successful, then the credentials from the server will be written to user defaults
    
    public func signIn(email: NSString, password : NSString, completion: ProxibaseCompletionBlock)
    {
        let parameters = ["email" : email, "password" : password, "installId" : installId]
        self.sessionManager.POST("auth/signin", parameters: parameters,
            success: { _, response in
            
                self.handleSuccessfulSignInResponse(response)
                
                completion(response: response, error: nil)
            },
            failure: { _, error in
                completion(response: ServerError(error)?.response, error: error)
        })
    }
    
    
    // Send an auth/signout message.
    //
    // Discard credentials whether or not the server thinks we are signed out.
    // The completion closure is always performed asynchronously.
    
    public func signOut(completion:(response: AnyObject?, error: NSError?) -> Void)
    {
        if self.authenticated {
            self.performGETRequestFor("auth/signout", parameters: [:]) { response, error in

                self.discardCredentials()
                completion(response: response, error: error)
            }
        } else {
            discardCredentials()
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion(response: nil, error: nil)
            })
        }
    }
    
    public typealias ProxibaseCompletionBlock = (response: AnyObject?, error: NSError?) -> Void
    
    // Create a new user with the provided name, email and password.
    // • Additional information (like profile photo) may optionally be sent in the parameters dictionary
    //
    public func createUser(name: String, email: String, password: String, parameters: NSDictionary? = nil, completion: ProxibaseCompletionBlock)
    {
        let createParameters = [
            "data": ["name": name,
                     "email": email,
                     "password": password
                    ],
            "secret": "larissa",
            "installId": installId
        ]
        
        self.performPOSTRequestFor("user/create", parameters: createParameters) { response, error in
        
            let queue = dispatch_queue_create("user-create-queue", DISPATCH_QUEUE_SERIAL)
            if error == nil {

                // After creating a user, the user is left in a logged-in state, so process the response
                // to extract the credentials.
                self.handleSuccessfulSignInResponse(response!)
                
                // If there were other parameters sent in the create request, then perform an update to get
                // them onto the server
                if parameters != nil && parameters!.count > 0
                {

                    let semaphore = dispatch_semaphore_create(0)
                    dispatch_async(queue)
                    {
                        self.updateUser(parameters!) { updateResponse, updateError in

                            if let error = updateError {
                                // If the update fails, then the user-creation still succeeded.
                                // Log the second error, but don't take any action.
                                
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
            // Invoke the caller's completion routine _after_ the update (if any) finishes. Pass the result of
            // the create operation.
            dispatch_async(queue) {
                completion(response: response, error: error)
            }
        }
    }

    
    enum S3Bucket
    {
        case Users
        case Images
    }
    
    let bucketInfo: [S3Bucket:(name:String, source:String)] =
        [.Users:  ("aircandi-users", "aircandi.users"),
         .Images: ("aircandi-images", "aircandi.images")]

    func queuePhotoUploadInParameters(parameters: NSMutableDictionary, queue: dispatch_queue_t, bucket: S3Bucket)
    {
        assert(self.authenticated, "ProxibaseClient must be authenticated prior to editing the user")
        if let userId = self.userId
        {
            if let photo = parameters["photo"] as? UIImage
            {
                let semaphore = dispatch_semaphore_create(0)
                
                let profilePhotoKey = "\(userId)_\(DateTimeTag()).jpg"
                
                let photoDict = [
                    "width":  Int(photo.size.width),  // width/height are in points...should be pixels?
                    "height": Int(photo.size.height),
                    "source": self.bucketInfo[bucket]!.source,
                    "prefix": profilePhotoKey]
                
                dispatch_async(queue) {
                    self.uploadImageToS3(photo, bucket: self.bucketInfo[bucket]!.name, key: profilePhotoKey) { result, error in
                        
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
    
    // Update the currently signed-in user's information. Only provide fields that you want to change.
    //
    // There is special processing performed for the "photo" key, which may contain a UIImage on input.
    // If this is the case, then the image is uploaded to the users bucket on S3 and then, when that upload
    // is completed, the user record is updated with the photo field.
    
    public func updateUser(userInfo: NSDictionary, completion: ProxibaseCompletionBlock)
    {
        assert(self.authenticated, "ProxibaseClient must be authenticated prior to editing the user")
        if let userId = self.userId {

            // The queue and semaphore are used to synchronize the (optional) upload to S3 with the
            // update of the record on the server. The S3 upload, if present, must complete first before
            // the database update.
            
            if let mutableUserInfo = userInfo.mutableCopy() as? NSMutableDictionary {
                
                let queue = dispatch_queue_create("update-user-queue", DISPATCH_QUEUE_SERIAL)
                queuePhotoUploadInParameters(mutableUserInfo, queue: queue, bucket: .Users)
                
                dispatch_async(queue) {
                    let parameters = ["data": mutableUserInfo]
                    self.performPOSTRequestFor("data/users/\(userId)", parameters: parameters) { response, error in
                        completion(response: response, error: error)
                    }
                }
            }
        }
    }
    
    public func convertLocationProperties(properties: NSMutableDictionary)
    {
        if let location = properties["location"] as? CLLocation
        {
            properties["location"] = [
                "accuracy":location.horizontalAccuracy,
                "geometry": [
                    location.coordinate.longitude,
                    location.coordinate.latitude],
                "lat": location.coordinate.latitude,
                "lng": location.coordinate.longitude]
        }
    }
    
    // path can be a collection name (i.e. "data/patches", "data/messages") to create a new object.
    // path can also be an object path (i.e. "data/patches/pa.xyz" to update an existing object.
    //
    private func postObject(path:String, parameters: NSDictionary, completion: ProxibaseCompletionBlock)
    {
        let properties = parameters.mutableCopy() as NSMutableDictionary
        let queue = dispatch_queue_create("post-object-queue", DISPATCH_QUEUE_SERIAL)
        
        convertLocationProperties(properties)
        queuePhotoUploadInParameters(properties, queue: queue, bucket: .Images)
        
        dispatch_async(queue)
        {
            let postParameters = ["data":properties]
            self.performPOSTRequestFor(path, parameters: postParameters, completion: completion)
        }
    }

    public func createObject(path: String, parameters: NSDictionary, completion: ProxibaseCompletionBlock)
    {
        postObject(path, parameters: parameters, completion: completion)
    }
    
    public func updateObject(path: String, parameters: NSDictionary, completion: ProxibaseCompletionBlock)
    {
        postObject(path, parameters: parameters, completion: completion)
    }
    
    public func deleteObject(path:String, completion: ProxibaseCompletionBlock)
    {
        self.performDELETERequestFor(path, parameters: NSDictionary(), completion: completion)
    }
    
    public func deleteLink(linkID: String, completion: ProxibaseCompletionBlock? = nil)
    {
        let linkPath = "data/links/\(linkID)"
        self.performDELETERequestFor(linkPath, parameters: NSDictionary()) { response, error in
            if let completionBlock = completion
            {
                completionBlock(response: response, error: error)
            }
        }
    }
    public func createLink(fromID: String, toID: String, linkType: LinkType, completion: ProxibaseCompletionBlock)
    {
        let linkParameters: NSDictionary = [
            "_from": fromID,
            "_to": toID,
            "type": linkType.rawValue
        ]
        
        let postParameters = ["data": linkParameters]
        
        self.performPOSTRequestFor("data/links", parameters: postParameters) { response, error in
            completion(response: response, error: error)
        }
    }
    
    public func findLink(fromID: String, toID: String, linkType: LinkType, completion: ProxibaseCompletionBlock)
    {
        let query: NSDictionary = ["query": ["_from": fromID, "_to": toID, "type": linkType.rawValue]]

        self.performGETRequestFor("find/links", parameters: query, completion: completion)
    }
    
    public func fetchAllCategories(completion: ProxibaseCompletionBlock)
    {
        self.performGETRequestFor("patches/categories", parameters: [:], completion: completion)
    }
    
    public func fetchCurrentUser(completion: ProxibaseCompletionBlock)
    {
        self.performGETRequestFor("data/users/\(userId!)", parameters: [:], completion: completion)
    }
    
    public func fetchNearbyPatches(location: CLLocationCoordinate2D, radius: NSInteger, limit: NSInteger = 50, skip: NSInteger = 0, links: [Link] = [], completion: ProxibaseCompletionBlock) {
        var allLinks = self.standardPatchLinks() + links
        let parameters = [
            "location" : [
                "lat" : location.latitude,
                "lng" : location.longitude
            ],
            "radius" : radius,
            "limit" : limit,
            "skip" : skip,
            "rest" : true,
            "linked" : allLinks.map { $0.toDictionary() }
        ]
        self.performPOSTRequestFor("patches/near", parameters: parameters, completion: completion)
    }
    
    public func fetchMessagesForPatch(patchId: String, limit: NSInteger = 50, skip: NSInteger = 0, links: [Link] = [], completion:(response: AnyObject?, error: NSError?) -> Void) {
        let allLinks = [Link(from: .Messages, type: .Content, linkFields: "_id")] + links
        let parameters = [
            "refs" : "_id,name,photo,schema",
            "linked" : allLinks.map { $0.toDictionary() }
        ]
        self.performPOSTRequestFor("find/patches/\(patchId)", parameters: parameters, completion: completion)
    }
    
    public func fetchNotifications(limit: NSInteger = 50, skip: NSInteger = 0, completion: ProxibaseCompletionBlock) {
        var allLinks = self.standardPatchLinks()
        let parameters = [
            "limit" : limit,
            "skip" : skip,
            "linked" : allLinks.map { $0.toDictionary() }
        ]
        self.performPOSTRequestFor("user/getNotifications", parameters: parameters, completion: completion)
    }
    
    public func fetchMostMessagedPatches(limit: NSInteger = 50, skip: NSInteger = 0, completion:(response: AnyObject?, error: NSError?) -> Void) {
        var allLinks = self.standardPatchLinks()
        let parameters : Dictionary<String, AnyObject> = [
            "type" : "content"
            //"links" : allLinks.map { $0.toDictionary() } // Doesn't work the same as /find API
        ]
        self.performPOSTRequestFor("stats/to/patches/from/messages", parameters: parameters, completion: completion)
    }
    
    public func fetchMessagesOwnedByCurrentUser(limit: NSInteger = 50, skip: NSInteger = 0, links: [Link] = [], completion:(response: AnyObject?, error: NSError?) -> Void) {
        self.performPOSTRequestFor("find/messages", parameters: [:], completion: completion)
    }
    
    private func authenticatedParameters(var parameters: NSDictionary) -> NSDictionary
    {
        if self.authenticated
        {
            var authParameters = NSMutableDictionary(dictionary: ["user" : self.userId!, "session" : self.sessionKey!])
            authParameters.addEntriesFromDictionary(parameters)
            parameters = authParameters
        }
        return parameters
    }
    
    public func performPOSTRequestFor(path: NSString, var parameters : NSDictionary, completion: ProxibaseCompletionBlock)
    {
        self.sessionManager.POST(path, parameters: authenticatedParameters(parameters),
            success: { (dataTask, response) -> Void in
                completion(response: response, error: nil)
            },
            failure: { (dataTask, error) -> Void in
                let response = dataTask.response as? NSHTTPURLResponse
                completion(response: ServerError(error)?.response, error: error)
        })
    }
    
    public func performGETRequestFor(path: NSString, var parameters : NSDictionary, completion: ProxibaseCompletionBlock)
    {
        self.sessionManager.GET(path, parameters: authenticatedParameters(parameters),
            success: { (dataTask, response) -> Void in
                completion(response: response, error: nil)
            },
            failure: { (dataTask, error) -> Void in
                let response = dataTask.response as? NSHTTPURLResponse
                completion(response: ServerError(error)?.response, error: error)
        })
    }
    
    public func performDELETERequestFor(path: NSString, var parameters: NSDictionary, completion: ProxibaseCompletionBlock)
    {
        self.sessionManager.DELETE(path, parameters: authenticatedParameters(parameters),
            success: { dataTask, response in
                completion(response: response, error: nil)
            },
            failure: {dataTask, error in
                let response = dataTask.response as? NSHTTPURLResponse
                completion(response: ServerError(error)?.response, error: error)
            })
    }
    
    public func standardPatchLinks() -> [Link] {
        return [
            Link(to: .Beacons, type: .Proximity, limit: 10),
            Link(to: .Places, type: .Proximity, limit: 10),
            Link(from: .Messages, type: .Content, limit: 2),
            Link(from: .Messages, type: .Content, count: true),
            Link(from: .Users, type: .Like, count: true),
            Link(from: .Users, type: .Watch, count: true)
        ]
    }
}

public class Link {
    public var to: LinkDestination?
    public var from: LinkDestination?
    public var type: LinkType?
    public var limit: UInt?
    public var count: Bool?
    public var linkFields: String?
    
    init(to: LinkDestination, type: LinkType, limit: UInt? = nil, count: Bool? = nil, linkFields: String? = nil) {
        self.to = to
        self.type = type
        self.limit = limit
        self.count = count
        self.linkFields = linkFields
    }
    
    init(from: LinkDestination, type: LinkType, limit: UInt? = nil, count: Bool? = nil, linkFields: String? = nil) {
        self.from = from
        self.type = type
        self.limit = limit
        self.count = count
        self.linkFields = linkFields
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
        if linkFields != nil {
            dictionary["linkFields"] = linkFields
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
