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
    
    required convenience init?(dict: [String: Any], id: String?) {
        self.init()
        self.filename = dict["filename"] as? String
        self.source = dict["source"] as? String
        self.width = dict["width"] as? Int
        self.height = dict["height"] as? Int
        self.takenAt = dict["taken_at"] as? Int
    }
    
    internal var dict: [String : Any] {
        return [
            "filename": self.filename,
            "source": self.source,
            "width": self.width,
            "height": self.height,
            "taken_at": self.takenAt
        ]
    }
}
