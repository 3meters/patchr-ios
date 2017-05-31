//
//  AwsS3.swift
//  Patchr
//
//  Created by Jay Massena on 7/19/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import FirebaseStorage

public class GoogleStorage: NSObject {
    
    static internal let imageSource = "google-storage"
    static internal let imageBucket = "patchr-images"
    
    static let instance: GoogleStorage = GoogleStorage()
    
    func upload(imageData: Data, imageKey: String, then: ((StorageTaskSnapshot) -> Void)?) {
        
        let storage = Storage.storage(url: "gs://patchr-images")
        let imageRef = storage.reference().child(imageKey)
        let metadata = StorageMetadata()
        
        metadata.contentType = "image/jpeg"
        
        let uploadTask = imageRef.putData(imageData, metadata: metadata)
        Log.d("*** Google storage image upload started successfully: \(imageKey)")
        
        if then != nil {
            uploadTask.observe(.progress, handler: then!)
            uploadTask.observe(.success, handler: then!)
            uploadTask.observe(.failure) { snapshot in
                if let error = snapshot.error as? NSError {
                    Log.w("*** Google storage image upload failed with error: \(error.localizedDescription)")
                    then!(snapshot)
                }
            }
        }
    }
}
