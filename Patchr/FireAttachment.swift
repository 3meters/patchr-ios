//
//  FireProfile.swift
//  Patchr
//
//  Created by Jay Massena on 10/14/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import Foundation

class FireAttachment: NSObject, DictionaryConvertible {
    
    var title: String?
    var photo: FirePhoto?
    
    required convenience init?(dict: [String: Any], id: String?) {
        self.init()
        self.title = dict["title"] as? String
        if (dict["photo"] as? NSDictionary) != nil {
            self.photo = FirePhoto(dict: dict["photo"] as! [String: Any], id: nil)
        }
    }
    
    internal var dict: [String: Any] {
        return [
            "title": self.title,
            "photo": self.photo?.dict
        ]
    }
}
