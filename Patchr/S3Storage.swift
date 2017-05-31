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
    
    static let imageSource = "aircandi.images"
    static let imageBucket = "aircandi-images"
    
    static let instance: S3 = S3()
    
    func upload(imageData: Data, imageKey: String
        , progress: AWSS3TransferUtilityProgressBlock?
        , completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?) {
        
        /* It is expected that this will be called on a background thread. */
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = progress
        
        /* Saves the data as a file in a temporary directory. The next time
         the transfer utility is initialized, the expired temp files are cleaned up.
         Upload continues whether app is active or in background. If app is terminated by
         iOS, the system continues the upload and launches app after upload finishes.
         If user kills app, the upload stops. */
        AWSS3TransferUtility.default().uploadData(imageData
            , bucket: S3.imageBucket
            , key: imageKey
            , contentType: "image/jpeg"
            , expression: expression
            , completionHander: completionHandler).continue({ task -> Any! in
                Log.w(task.error != nil
                    ? "*** S3 image upload failed with error: \(task.error!.localizedDescription)"
                    : task.exception != nil
                    ? "*** S3 image upload failed with exception: \(task.exception!.description)"
                    : "*** S3 image upload started successfully: \(imageKey)")
                return nil
            })
    }
}
