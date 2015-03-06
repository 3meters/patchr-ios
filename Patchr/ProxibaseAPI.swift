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

let globalGregorianCalendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)

public func DateTimeTag() -> String!
{
    let date = NSDate()

    if let dc = globalGregorianCalendar?.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay |
                                                    .CalendarUnitHour | .CalendarUnitMinute | .CalendarUnitSecond, fromDate: date)
    {
        return String(format:"%04d%02d%02d_%02d%02d%02d", dc.year, dc.month, dc.day, dc.hour, dc.minute, dc.second)
    }
    return nil
}

var temporaryFileCount = 0

func TemporaryFileURLForImage(image: UIImage) -> NSURL?
{
    let imageData = UIImageJPEGRepresentation(image, /*compressionQuality*/0.75)
    if let imageData = imageData {
    
        // Note: This method of getting a temporary file path is not the recommended method. See the docs for NSTemporaryDirectory.
        let temporaryFilePath = NSTemporaryDirectory() + "patchr_temp_file_\(temporaryFileCount).jpg"
        println(temporaryFilePath)
        
        if imageData.writeToFile(temporaryFilePath, atomically: false) {
            return NSURL(fileURLWithPath: temporaryFilePath)
        }
    }
    return nil
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
    
    // These will only be valid after a sign-in.
    public var userName: NSString?      // These are a convenience for now, but eventually we should
    public var userEmail: NSString?     // keep track of a full user record for the signed-in user.

    public var installId: String
    
    public var authenticated : Bool {
        return (userId != nil && sessionKey != nil)
    }
    
    public let StagingURI = "https://api.aircandi.com:8443/v1/"
    public let ProductionURI = "https://api.aircandi.com/v1/"
    
    required public init() {
    
        let userDefaults = NSUserDefaults.standardUserDefaults()
        var serverURI = userDefaults.stringForKey(PatchrUserDefaultKey("serverURI"))

        if serverURI == nil || serverURI?.utf16Count == 0 {
            serverURI = ProductionURI
            userDefaults.setObject(serverURI, forKey: PatchrUserDefaultKey("serverURI"))
        }

        userId     = userDefaults.stringForKey(PatchrUserDefaultKey("userId"))
        sessionKey = userDefaults.stringForKey(PatchrUserDefaultKey("sessionKey"))
        
        installId = "1" // TODO
        
        sessionManager = AFHTTPSessionManager(baseURL: NSURL(string: serverURI!))

        sessionManager.requestSerializer = AFJSONRequestSerializer(writingOptions: nil)
        sessionManager.responseSerializer = JSONResponseSerializerWithData()
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
        // TODO: Static Credentials are not recommended, but ok for development
        
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
    
    private func handleSuccessfulSignInResponse(response:AnyObject)
    {
        let json = JSON(response)
        
        self.userId = json["session"]["_owner"].string
        self.sessionKey = json["session"]["key"].string
        self.userName = json["user"]["name"].string
        self.userEmail = json["user"]["email"].string
        
        self.writeCredentialsToUserDefaults()
    }
    
    // Send an auth/signin message to the server with the user's email address and password.
    // The completion block will be called asynchronously in either case.
    // If signin is successful, then the credentials from the server will be written to user defaults
    
    public func signIn(email: NSString, password : NSString, completion:(response: AnyObject?, error: NSError?) -> Void)
    {
        let parameters = ["email" : email, "password" : password, "installId" : installId]
        self.sessionManager.POST("auth/signin", parameters: parameters,
            success: { (dataTask, response) -> Void in
            
                self.handleSuccessfulSignInResponse(response)
                
                completion(response: response, error: nil)
            },
            failure: { (dataTask, error) -> Void in
                completion(response: error?.userInfo?[JSONResponseSerializerWithDataKey], error: error)
        })
    }
    
    private func discardCredentials()
    {
        userId = nil;
        sessionKey = nil;
        writeCredentialsToUserDefaults()
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
    // • Additional optional information (like profile photo) is sent in the parameters dictionary
    //
    public func createUser(name: String, email: String, password: String, parameters: NSDictionary? = nil, completion: ProxibaseCompletionBlock)
    {
        let parameters = ["data": ["name": name,
                                   "email": email,
                                   "password": password
                                  ],
                          "secret": "larissa",
                          "installId": installId
                         ]
        
        self.performPOSTRequestFor("user/create", parameters: parameters) { response, error in
                if error == nil {
                    // After creating a user, the user is left in a logged-in state, so process the response
                    // to extract the credentials.
                    self.handleSuccessfulSignInResponse(response!)
                }
                // TODO: What can go wrong here? 
                // - User email exists already.
                //        message = "Duplicate value not allowed: E11000 duplicate key error index: prox_stage.users.$email_1  dup key: { : \"test@patchr.com\" }";

                // - Other server failures?
                completion(response: response, error: error)
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
            
            let queue = dispatch_queue_create("update-user-queue", DISPATCH_QUEUE_SERIAL)
            let semaphore = dispatch_semaphore_create(0)
            
            if let mutableUserInfo = userInfo.mutableCopyWithZone(nil) as? NSMutableDictionary {
                
                dispatch_async(queue) {
                    if let photo = userInfo["photo"] as? UIImage
                    {
                        let profilePhotoKey = "\(userId)_\(DateTimeTag()).jpg"
                        
                        let photoDict = [
                            "width":  Int(photo.size.width),  // width/height are in points...should be pixels?
                            "height": Int(photo.size.height),
                            "source": "aircandi.users",
                            "prefix": profilePhotoKey]
                        
                        self.uploadImageToS3(photo, bucket: "aircandi-users", key: profilePhotoKey) { result, error in
                        
                            mutableUserInfo["photo"] = photoDict
                            dispatch_semaphore_signal(semaphore)
                        }
                    }
                    else
                    {
                        dispatch_semaphore_signal(semaphore)
                    }
                }
                
                dispatch_async(queue) {
                    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
                    let parameters = ["data": mutableUserInfo]
                    self.performPOSTRequestFor("data/users/\(userId)", parameters: parameters) { response, error in
                        completion(response: response, error: error)
                    }
                }
            }
        }
    }
    

    
    public func fetchNearbyPatches(location: CLLocationCoordinate2D, radius: NSInteger, limit: NSInteger = 50, skip: NSInteger = 0, links: [Link] = [], completion:(response: AnyObject?, error: NSError?) -> Void) {
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
    
    public func fetchNotifications(limit: NSInteger = 50, skip: NSInteger = 0, completion:(response: AnyObject?, error: NSError?) -> Void) {
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
    
    public func fetchMostMessagedPatches(limit: NSInteger = 50, skip: NSInteger = 0, completion:(response: AnyObject?, error: NSError?) -> Void) {
        var allLinks = self.standardPatchLinks()
        let parameters : Dictionary<String, AnyObject> = [
            "entityId" : self.userId ?? "",
            "cursor" : [
                "sort" : ["modifiedDate" : -1],
                "skip" : skip,
                "limit" : limit
            ],
            "type" : "content"
            //"links" : allLinks.map { $0.toDictionary() } // Doesn't work the same as /find API
        ]
        self.performPOSTRequestFor("stats/to/patches/from/messages", parameters: parameters, completion: completion)
    }
    
    public func fetchMessagesOwnedByCurrentUser(limit: NSInteger = 50, skip: NSInteger = 0, links: [Link] = [], completion:(response: AnyObject?, error: NSError?) -> Void) {
        self.performPOSTRequestFor("find/messages", parameters: [:], completion: completion)
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
            },
            failure: { (dataTask, error) -> Void in
                let response = dataTask.response as? NSHTTPURLResponse
                completion(response: error?.userInfo?[JSONResponseSerializerWithDataKey], error: error)
        })
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
            },
            failure: { (dataTask, error) -> Void in
                let response = dataTask.response as? NSHTTPURLResponse
                completion(response: error?.userInfo?[JSONResponseSerializerWithDataKey], error: error)
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
