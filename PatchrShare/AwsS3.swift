//
//  AwsS3.swift
//  Patchr
//
//  Created by Jay Massena on 7/19/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import AWSCore
import AWSS3
import Keys
import Firebase
import FirebaseRemoteConfig

public class S3: NSObject {
    public typealias S3UploadCompletionBlock = (AWSTask) -> Void

    let poolId      = "us-east-1:ff1976dc-9c27-4046-a59f-7dd43355869b"
    let imageBucket = "aircandi-images"
    let imageSource = "aircandi.images"

    private var uploads: [NSURLSessionTask:UploadInfo] = [:]

    // Swift doesn't support static properties yet, so have to use structs to achieve the same thing.

    struct Static {
        static var session: NSURLSession?
        static var awss3:   AWSS3?
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
        let access = FIRRemoteConfig.remoteConfig().configValueForKey("aws_access_key").stringValue!
        let secret = FIRRemoteConfig.remoteConfig().configValueForKey("aws_secret_key").stringValue!
        let credProvider = AWSStaticCredentialsProvider(accessKey: access, secretKey: secret)
        let serviceConfig = AWSServiceConfiguration(region: AWSRegionType(rawValue: 3/*'us-west-2'*/)!, credentialsProvider: credProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = serviceConfig

        if Static.session == nil {
            let configIdentifier = "group.com.3meters.patchr.ios.image"

            /* PatchrShare only runs on >= iOS8 */
            let config           = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(configIdentifier)
            config.sharedContainerIdentifier = "group.com.3meters.patchr.ios"

            // NSURLSession background sessions *need* to have a delegate.
            Static.session = NSURLSession(configuration: config, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        }

        if Static.awss3 == nil {
            Static.awss3 = AWSS3.defaultS3()
        }
    }

    func uploadImageToS3(image: UIImage, imageKey: String, completion: S3UploadCompletionBlock) -> AWSS3TransferManagerUploadRequest? {
        /*
        * It is expected that this will be called on a background thread.
        */

        /* Store image to file as NSData */
        if let imageURL = Utils.TemporaryFileURLForImage(image, name: NSUUID().UUIDString) {
            // Saves as compressed jpeg

            /* Construct request */
            let uploadRequest
            = S3.sharedService.buildUploadRequest(imageURL, contentType: "image/jpeg", bucket: self.imageBucket, key: imageKey)

            /* Upload */
            AWSS3TransferManager.defaultS3TransferManager().upload(uploadRequest).continueWithBlock {
                task -> AnyObject! in

                if let error = task.error {
                    Log.w("S3 image upload failed: [\(error)]")
                }
                if let exception = task.exception {
                    Log.w("S3 image upload failed: [\(exception)]")
                }

                do {
                    try NSFileManager.defaultManager().removeItemAtURL(imageURL)
                } catch let error as NSError {
                    print("Error removing image file: \(error.localizedDescription)")
                }

                completion(task)
                return nil
            }

            return uploadRequest
        }
        return nil
    }

    func uploadImage(image inImage: UIImage, key: String, bucket: String, shared: Bool = false) {

        /* Only called by share extension */
        Log.d("Posting image to s3...")
        let image = Utils.prepareImage(image: inImage)   // resizing

        /* We need to stash the image as a file in the shared container in NSData format. */
        let uuid  = NSUUID().UUIDString
        if let imageURL = Utils.TemporaryFileURLForImage(image, name: uuid, shared: shared) {
            // Saves as compressed jpeg
            uploadTaskToS3(imageURL, contentType: "image/jpeg", bucket: imageBucket, key: key)
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
                Log.w(String(format: "getPreSignedURL error: %@", task.error!))
                return nil
            }

            let preSignedUrl = task.result as! NSURL
            Log.d(String(format: "S3 upload pre-signedUrl: %@", preSignedUrl))

            let request = NSMutableURLRequest(URL: preSignedUrl)
            request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData

            /* Make sure the content-type and http method are the same as in preSignedReq */
            request.HTTPMethod = "PUT"
            request.setValue(preSignedReq.contentType, forHTTPHeaderField: "Content-Type")

            /* NSURLSession background session does *not* support completionHandler, so don't set it. */
            let uploadTask = Static.session?.uploadTaskWithRequest(request, fromFile: fileUrl)

            /* Tracking */
            let uploadInfo = UploadInfo(key: key, bucket: bucket, fileUrl: fileUrl)
            self.uploads[uploadTask!] = uploadInfo

            // Start the upload task:
            uploadTask?.resume()

            return nil
        }
    }

    func buildUploadRequest(fileURL: NSURL, contentType: String, bucket: String, key: String) -> AWSS3TransferManagerUploadRequest {
        let uploadRequest = AWSS3TransferManagerUploadRequest()

        uploadRequest.bucket = bucket
        uploadRequest.key = key
        uploadRequest.body = fileURL
        uploadRequest.ACL = AWSS3ObjectCannedACL(rawValue: 2/*AWSS3ObjectCannedACLPublicRead*/)!
        uploadRequest.contentType = contentType

        return uploadRequest
    }
}

class UploadInfo {
    var key:     String
    var fileUrl: NSURL
    var bucket:  String

    init(key: String, bucket: String, fileUrl: NSURL) {
        self.key = key
        self.fileUrl = fileUrl
        self.bucket = bucket
    }
}

extension S3: NSURLSessionDelegate {
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        Log.d(String(format: "Did receive data: %@", NSString(data: data, encoding: NSUTF8StringEncoding)!))
    }

    func URLSession(session: NSURLSession, uploadTask: NSURLSessionTask, didCompleteWithError error: NSError?) {

        if let uploadInfo = uploads[uploadTask as! NSURLSessionUploadTask] {
            self.uploads.removeValueForKey(uploadTask)

            if NSFileManager.defaultManager().isDeletableFileAtPath(uploadInfo.fileUrl.path!) {
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(uploadInfo.fileUrl.path!)
                } catch let error as NSError {
                    print("Error removing image file: \(error.localizedDescription)")
                }
            }

            if error != nil {
                Log.w(String(format: "S3 upload task: %@ completed with error: %@", uploadTask, error!.localizedDescription))
            }
            else {
                Log.d(String(format: "S3 upload task: %@ completed", uploadTask))

                /* AWS signed requests do not support ACL yet so it has to be set in a separate call. */
                let aclRequest = AWSS3PutObjectAclRequest()
                aclRequest.bucket = uploadInfo.bucket
                aclRequest.key = uploadInfo.key
                aclRequest.ACL = AWSS3ObjectCannedACL.PublicRead

                Static.awss3!.putObjectAcl(aclRequest).continueWithBlock() {
                    (task) -> AnyObject! in

                    dispatch_async(dispatch_get_main_queue()) {
                        if task.error != nil {
                            Log.w(String(format: "Error putObjectAcl: %@", task.error!.localizedDescription))
                        }
                        else {
                            Log.d("ACL for an uploaded file was changed successfully!")
                        }
                    }
                    return nil
                }
            }
        }
    }
}