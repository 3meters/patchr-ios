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
    
    static func setPropertiesFromDictionary(dictionary: NSDictionary, onObject photo: FirePhoto) -> FirePhoto {
        photo.filename = dictionary["filename"] as? String
        photo.source = dictionary["source"] as? String
        photo.width = dictionary["width"] as? Int
        photo.height = dictionary["height"] as? Int
        photo.takenAt = dictionary["taken_at"] as? Int        
        return photo
    }
}