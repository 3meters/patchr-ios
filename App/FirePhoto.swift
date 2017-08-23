//
//  FirePhoto.swift
//  Teeny
//
//  Created by Jay Massena on 10/14/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import Foundation

class FirePhoto: NSObject {
    
    var filename: String!
    var height: Int?
    var source: String!
    var takenAt: Int64?
    var uploading: Bool?
    var width: Int?
    
    init(dict: [String: Any]) {
        self.filename = dict["filename"] as! String
        self.source = dict["source"] as! String
        self.width = dict["width"] as? Int
        self.height = dict["height"] as? Int
        self.takenAt = dict["taken_at"] as? Int64
        self.uploading = dict["uploading"] as? Bool
    }
}
