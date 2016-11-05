//
//  AwsS3.swift
//  Patchr
//
//  Created by Jay Massena on 7/19/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import AWSS3
import AWSCore
import Keys
import Firebase
import FirebaseRemoteConfig

public class S3: NSObject {
    public typealias S3UploadCompletionBlock = (AWSTask<AnyObject>) -> Void

    let poolId      = "us-east-1:ff1976dc-9c27-4046-a59f-7dd43355869b"
    let imageBucket = "aircandi-images"
    let imageSource = "aircandi.images"

    fileprivate var uploads: [URLSessionTask:UploadInfo] = [:]

    // Swift doesn't support static properties yet, so have to use structs to achieve the same thing.

    struct Static {
        static var session: URLSession?
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
        let access = FIRRemoteConfig.remoteConfig().configValue(forKey: "aws_access_key").stringValue!
        let secret = FIRRemoteConfig.remoteConfig().configValue(forKey: "aws_secret_key").stringValue!
        let credProvider = AWSStaticCredentialsProvider(accessKey: access, secretKey: secret)
        let serviceConfig = AWSServiceConfiguration(region: AWSRegionType(rawValue: 3/*'us-west-2'*/)!, credentialsProvider: credProvider)
        AWSServiceManager.default().defaultServiceConfiguration = serviceConfig

        if Static.session == nil {
            let configIdentifier = "group.com.3meters.patchr.ios.image"

            /* PatchrShare only runs on >= iOS8 */
            let config = URLSessionConfiguration.background(withIdentifier: configIdentifier)
            config.sharedContainerIdentifier = "group.com.3meters.patchr.ios"

            // NSURLSession background sessions *need* to have a delegate.
            Static.session = Foundation.URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
        }

        if Static.awss3 == nil {
            Static.awss3 = AWSS3.default()
        }
    }

    func uploadImageToS3(image: UIImage, imageKey: String, completion: @escaping S3UploadCompletionBlock) -> AWSS3TransferManagerUploadRequest? {
        /*
        * It is expected that this will be called on a background thread.
        */

        /* Store image to file as NSData */
        if let imageURL = Utils.TemporaryFileURLForImage(image: image, name: NSUUID().uuidString) {
            // Saves as compressed jpeg

            /* Construct request */
            let uploadRequest = S3.sharedService.buildUploadRequest(fileURL: imageURL, contentType: "image/jpeg", bucket: self.imageBucket, key: imageKey)

            /* Upload */
            AWSS3TransferManager.default().upload(uploadRequest).continue ({(task: AWSTask) in
                if let error = task.error {
                    Log.w("S3 image upload failed: [\(error)]")
                }
                if let exception = task.exception {
                    Log.w("S3 image upload failed: [\(exception)]")
                }

                do {
                    try FileManager.default.removeItem(at: imageURL as URL)
                } catch let error as NSError {
                    print("Error removing image file: \(error.localizedDescription)")
                }

                completion(task)
                return nil
            })

            return uploadRequest
        }
        return nil
    }

    func upload(image: UIImage, imageKey: String, progress: AWSS3TransferUtilityProgressBlock?, completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?) {
        /*
         * It is expected that this will be called on a background thread.
         */
        let expression = AWSS3TransferUtilityUploadExpression()
        if progress != nil {
            expression.progressBlock = progress
        }
        
        if let imageData: Data = UIImageJPEGRepresentation(image, /*compressionQuality*/0.70) as Data? {
            let transferUtility = AWSS3TransferUtility.default()
            transferUtility.uploadData(
                imageData as Data,
                bucket: self.imageBucket,
                key: imageKey,
                contentType: "image/jpeg",
                expression: expression,
                completionHander: completionHandler).continue({ task -> Any! in
                    if let error = task.error {
                        Log.w("Image upload error: \(error.localizedDescription)")
                    }
                    if let exception = task.exception {
                        Log.w("Image upload exception: \(exception.description)")
                    }
                    return nil
                })
        }
    }

    func uploadImage(image inImage: UIImage, key: String, bucket: String, shared: Bool = false) {

        /* Only called by share extension */
        Log.d("Posting image to s3...")
        let image = Utils.prepareImage(image: inImage)   // resizing

        /* We need to stash the image as a file in the shared container in NSData format. */
        let uuid  = NSUUID().uuidString
        if let imageURL = Utils.TemporaryFileURLForImage(image: image, name: uuid, shared: shared) {
            // Saves as compressed jpeg
            uploadTaskToS3(fileUrl: imageURL, contentType: "image/jpeg", bucket: imageBucket, key: key)
        }
    }

    private func uploadTaskToS3(fileUrl: NSURL, contentType: String, bucket: String, key: String) {

        let preSignedReq = AWSS3GetPreSignedURLRequest()

        preSignedReq.bucket = bucket
        preSignedReq.key = key
        preSignedReq.contentType = contentType                       // required
        preSignedReq.httpMethod = AWSHTTPMethod.PUT                   // required
        preSignedReq.expires = NSDate(timeIntervalSinceNow: 3600) as Date    // required

        /* The defaultS3PreSignedURLBuilder uses the global config, as specified in the init method. */
        let urlBuilder = AWSS3PreSignedURLBuilder.default()

        /* The new AWS SDK uses AWSTasks to chain requests together. */
        urlBuilder.getPreSignedURL(preSignedReq).continue({
            (task:AWSTask) -> AnyObject! in

            if task.error != nil {
                Log.w(String(format: "getPreSignedURL error: %@", (task.error?.localizedDescription)!))
                return nil
            }

            let preSignedUrl = task.result
            Log.d(String(format: "S3 upload pre-signedUrl: %@", preSignedUrl!))

            let request = NSMutableURLRequest(url: preSignedUrl as! URL)
            request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData

            /* Make sure the content-type and http method are the same as in preSignedReq */
            request.httpMethod = "PUT"
            request.setValue(preSignedReq.contentType, forHTTPHeaderField: "Content-Type")

            /* NSURLSession background session does *not* support completionHandler, so don't set it. */
            let uploadTask = Static.session?.uploadTask(with: request as URLRequest, fromFile: fileUrl as URL)

            /* Tracking */
            let uploadInfo = UploadInfo(key: key, bucket: bucket, fileUrl: fileUrl)
            self.uploads[uploadTask!] = uploadInfo

            // Start the upload task:
            uploadTask?.resume()

            return nil
        })
    }

    func buildUploadRequest(fileURL: NSURL, contentType: String, bucket: String, key: String) -> AWSS3TransferManagerUploadRequest {
        let uploadRequest = AWSS3TransferManagerUploadRequest()

        uploadRequest?.bucket = bucket
        uploadRequest?.key = key
        uploadRequest?.body = fileURL as URL!
        uploadRequest?.acl = AWSS3ObjectCannedACL(rawValue: 2/*AWSS3ObjectCannedACLPublicRead*/)!
        uploadRequest?.contentType = contentType

        return uploadRequest!
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

extension S3: URLSessionDelegate {
    
    func URLSession(session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        Log.d(String(format: "Did receive data: %@", NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue)!))
    }

    func URLSession(session: URLSession, uploadTask: URLSessionTask, didCompleteWithError error: NSError?) {

        if let uploadInfo = uploads[uploadTask as! URLSessionUploadTask] {
            self.uploads.removeValue(forKey: uploadTask)

            if FileManager.default.isDeletableFile(atPath: uploadInfo.fileUrl.path!) {
                do {
                    try FileManager.default.removeItem(atPath: uploadInfo.fileUrl.path!)
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
                aclRequest?.bucket = uploadInfo.bucket
                aclRequest?.key = uploadInfo.key
                aclRequest?.acl = AWSS3ObjectCannedACL.publicRead

                Static.awss3!.putObjectAcl(aclRequest!).continue({
                    (task:AWSTask) -> AnyObject! in

                    DispatchQueue.main.async {
                        if task.error != nil {
                            Log.w(String(format: "Error putObjectAcl: %@", task.error!.localizedDescription))
                        }
                        else {
                            Log.d("ACL for an uploaded file was changed successfully!")
                        }
                    }
                    return nil
                })
            }
        }
    }
}
