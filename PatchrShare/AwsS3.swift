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

public class S3: NSObject {
    public typealias S3UploadCompletionBlock = (AWSTask<AnyObject>) -> Void

    internal let imageSource = "aircandi.images"
    
    static let instance: S3 = S3()

    func upload(image: UIImage, imageKey: String
        , progress: AWSS3TransferUtilityProgressBlock?
        , completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?) {
        
        /* It is expected that this will be called on a background thread. */
        let expression = AWSS3TransferUtilityUploadExpression()
        
        if progress != nil {
            expression.progressBlock = progress
        }
        
        if let imageData: Data = UIImageJPEGRepresentation(image, /*compressionQuality*/0.70) as Data? {
            let transferUtility = AWSS3TransferUtility.default()
            transferUtility.uploadData(imageData as Data
                , bucket: "aircandi-images"
                , key: imageKey
                , contentType: "image/jpeg"
                , expression: expression
                , completionHander: completionHandler).continue({ task -> Any! in
                    if let error = task.error {
                        Log.w("*** S3 image upload failed with error: \(error.localizedDescription)")
                    }
                    else if let exception = task.exception {
                        Log.w("*** S3 image upload failed with exception: \(exception.description)")
                    }
                    else {
                        Log.d("*** S3 image upload started successfully: \(imageKey)")
                    }
                    return nil
            })
        }
    }
    
    func exists(imageKey: String, next: @escaping ((Bool) -> Void)) {
        
        let s3 = AWSS3.default()
        let request = AWSS3HeadObjectRequest()
        
        request?.bucket = "aircandi-images"
        request?.key = imageKey
        
        s3.headObject(request!).continue({ task -> Any! in
            next(task.isCompleted && !task.isFaulted)
        })
    }
}
