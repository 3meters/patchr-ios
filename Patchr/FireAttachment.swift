//
//  FireProfile.swift
//  Patchr
//
//  Created by Jay Massena on 10/14/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import Foundation

class FireAttachment: NSObject {
    
    var title: String?
    var photo: FirePhoto?
    
    static func from(dict: [String: Any]?) -> FireAttachment? {
        if dict != nil {
            let attachment = FireAttachment()
            attachment.title = dict!["title"] as? String
            attachment.photo = FirePhoto.from(dict: dict!["photo"] as! [String : Any]?)
            return attachment
        }
        return nil
    }
}
