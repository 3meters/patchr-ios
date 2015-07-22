//
//  AwsS3.swift
//  Patchr
//
//  Created by Jay Massena on 7/19/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation

public class S3: NSObject {
    
    private let PatchrS3Key    = "AKIAIYU2FPHC2AOUG3CA"
    private let PatchrS3Secret = "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"
    private let bucket = "aircandi-images"
    private var uploads: [NSURLSessionTask: UploadInfo] = [:]
    
    // Swift doesn't support static properties yet, so have to use structs to achieve the same thing.
    struct Static {
        static var session : NSURLSession?
        static var awss3: AWSS3?
    }
    
    public class var sharedService: S3 {
        struct Singleton {
            static let instance = S3()
        }
        return Singleton.instance
    }
    
    override init() {
        super.init()
        
        // Note: There are probably safer ways to store the AWS credentials.
        let credentialsProvider = AWSStaticCredentialsProvider(accessKey: PatchrS3Key, secretKey: PatchrS3Secret)
        let configuration = AWSServiceConfiguration(region: AWSRegionType(rawValue: 3/*'us-west-2'*/)!, credentialsProvider: credentialsProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
        if Static.session == nil {
            let configIdentifier = "group.com.3meters.patchr.ios.image"
            
            /* PatchrShare only runs on >= iOS8 */
            var config = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(configIdentifier)   // iOS8 only
            config.sharedContainerIdentifier = "group.com.3meters.patchr.ios"
            
            // NSURLSession background sessions *need* to have a delegate.
            Static.session = NSURLSession(configuration: config, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        }
        
        if Static.awss3 == nil {
            Static.awss3 = AWSS3.defaultS3()
        }
    }
    
    func uploadImage(var image: UIImage, key: String) {
        NSLog("Posting image to s3...")
        image = Utils.prepareImage(image)   // resizing
        /*
         * We need to stash the image as a file in the shared container.
         */
        let uuid = NSUUID().UUIDString
        if let imageURL = tempContainerUrl(image, name:uuid) {
            uploadTaskToS3(imageURL, contentType: "image/jpeg", bucket: self.bucket, key: key)
        }
    }
    
    private func uploadTaskToS3(fileUrl: NSURL, contentType: String, bucket: String, key: String) {
        
        let preSignedReq = AWSS3GetPreSignedURLRequest()
        
        preSignedReq.bucket = bucket
        preSignedReq.key = key
        preSignedReq.contentType = contentType                       // required
        preSignedReq.HTTPMethod = AWSHTTPMethod.PUT                   // required
        preSignedReq.expires = NSDate(timeIntervalSinceNow: 3600)    // required
        
        /* The defaultS3PreSignedURLBuilder uses the global config, as specified in the init method. */
        let urlBuilder = AWSS3PreSignedURLBuilder.defaultS3PreSignedURLBuilder()
        
        /* The new AWS SDK uses AWSTasks to chain requests together. */
        urlBuilder.getPreSignedURL(preSignedReq).continueWithBlock {
            (task) -> AnyObject! in
            
            if task.error != nil {
                NSLog("getPreSignedURL error: %@", task.error)
                return nil
            }
            
            var preSignedUrl = task.result as! NSURL
            NSLog("S3 upload pre-signedUrl: %@", preSignedUrl)
            
            var request = NSMutableURLRequest(URL: preSignedUrl)
            request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
            
            /* Make sure the content-type and http method are the same as in preSignedReq */
            request.HTTPMethod = "PUT"
            request.setValue(preSignedReq.contentType, forHTTPHeaderField: "Content-Type")
            
            /* NSURLSession background session does *not* support completionHandler, so don't set it. */
            let uploadTask = Static.session?.uploadTaskWithRequest(request, fromFile: fileUrl)
            
            /* Tracking */
            var uploadInfo = UploadInfo(key: key, fileUrl: fileUrl)
            self.uploads[uploadTask!] = uploadInfo
            
            // Start the upload task:
            uploadTask?.resume()
            
            return nil
        }
    }
    
    func tempContainerUrl(image: UIImage, name: String) -> NSURL? {
        
        if let containerURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.com.3meters.patchr.ios") {
            
            var contairURLWithName = containerURL.URLByAppendingPathComponent(name)
            if !NSFileManager.defaultManager().fileExistsAtPath(contairURLWithName.path!) {
                NSFileManager.defaultManager().createDirectoryAtPath(containerURL.path!, withIntermediateDirectories: false, attributes: nil, error: nil)
            }
            
            var imageDirectoryURL = containerURL
            imageDirectoryURL = imageDirectoryURL.URLByAppendingPathComponent(name)
            imageDirectoryURL = imageDirectoryURL.URLByAppendingPathExtension("jpg")
            
            if let imageData = UIImageJPEGRepresentation(image, /*compressionQuality*/0.70) {
                if imageData.writeToFile(imageDirectoryURL.path!, atomically: true) {
                    return imageDirectoryURL
                }
            }
        }
        return nil
    }
    
    class UploadInfo {
        var key: String
        var fileUrl: NSURL
        
        init(key: String, fileUrl: NSURL) {
            self.key = key
            self.fileUrl = fileUrl
        }
    }
}

extension S3 : NSURLSessionDelegate {
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        NSLog("Did receive data: %@", NSString(data: data, encoding: NSUTF8StringEncoding)!)
    }
    
    func URLSession(session: NSURLSession, uploadTask: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        if let uploadInfo = uploads[uploadTask as! NSURLSessionUploadTask] {
            
            self.uploads.removeValueForKey(uploadTask)
            
            var delError: NSError?
            if NSFileManager.defaultManager().isDeletableFileAtPath(uploadInfo.fileUrl.path!) {
                let success = NSFileManager.defaultManager().removeItemAtPath(uploadInfo.fileUrl.path!, error: &delError)
                if !success {
                    println("Error removing file at path: \(error?.description)")
                }
            }

            if error != nil {
                NSLog("S3 upload task: %@ completed with error: %@", uploadTask, error!.localizedDescription)
            }
            else {
                NSLog("S3 upload task: %@ completed", uploadTask)
                
                /* AWS signed requests do not support ACL yet so it has to be set in a separate call. */
                let aclRequest = AWSS3PutObjectAclRequest()
                aclRequest.bucket = self.bucket
                aclRequest.key = uploadInfo.key
                aclRequest.ACL = AWSS3ObjectCannedACL.PublicRead
                
                Static.awss3!.putObjectAcl(aclRequest).continueWithBlock() {
                    (task) -> AnyObject! in
                    
                    dispatch_async(dispatch_get_main_queue()){
                        if task.error != nil {
                            NSLog("Error putObjectAcl: %@", task.error.localizedDescription);
                        }
                        else {
                            NSLog("ACL for an uploaded file was changed successfully!");
                        }
                    }
                    return nil
                }
            }
        }
    }
}