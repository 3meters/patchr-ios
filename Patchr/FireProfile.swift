//
//  FireProfile.swift
//  Patchr
//
//  Created by Jay Massena on 10/14/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import Foundation

class FireProfile: NSObject {
    
    var developer: Bool?
    var firstName: String?
    var fullName: String?
    var lastName: String?
    var phone: String?
    var photo: FirePhoto?
    
    static func from(dict: [String: Any]?) -> FireProfile? {
        if dict != nil {
            let profile = FireProfile()
            profile.firstName = dict!["first_name"] as? String
            profile.lastName = dict!["last_name"] as? String
            profile.fullName = dict!["full_name"] as? String
            profile.phone = dict!["phone"] as? String
            profile.developer = dict!["developer"] as? Bool
            profile.photo = FirePhoto.from(dict: dict!["photo"] as! [String : Any]?)
            return profile
        }
        return nil
    }
}
