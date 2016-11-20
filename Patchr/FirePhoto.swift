//
//  FirePhoto.swift
//  Patchr
//
//  Created by Jay Massena on 10/14/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import Foundation

class FirePhoto: NSObject {
    
    var filename: String?
    var width: Int?
    var height: Int?
    var source: String?
    var takenAt: Int?
    var uploading = false
    
    static func from(dict: [String: Any]?) -> FirePhoto? {
        if dict != nil {
            let photo = FirePhoto()
            photo.filename = dict!["filename"] as? String
            photo.source = dict!["source"] as? String
            photo.width = dict!["width"] as? Int
            photo.height = dict!["height"] as? Int
            photo.takenAt = dict!["taken_at"] as? Int
            if dict!["uploading"] != nil {
                photo.uploading = dict!["uploading"] as! Bool
            }
            return photo
        }
        return nil
    }
}
