//
//  FireProfile.swift
//  Patchr
//
//  Created by Jay Massena on 10/14/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import Foundation

class FireAttachment: NSObject {
    
    var id: String?
    var photo: FirePhoto?
    var title: String?
    
    init(dict: [String: Any], id: String?) {
        self.id = id!
        self.title = dict["title"] as? String
        if (dict["photo"] as? [String : Any]) != nil {
            self.photo = FirePhoto(dict: dict["photo"] as! [String : Any])
        }
    }
}
