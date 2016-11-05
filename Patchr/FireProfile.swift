//
//  FireProfile.swift
//  Patchr
//
//  Created by Jay Massena on 10/14/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import Foundation

class FireProfile: NSObject {
    
    var email: String?
    var firstName: String?
    var lastName: String?
    var fullName: String?
    var phone: String?
    var skype: String?
    var photo: FirePhoto?
    
    static func from(dict: [String: Any]?) -> FireProfile? {
        if dict != nil {
            let profile = FireProfile()
            profile.email = dict!["email"] as? String
            profile.firstName = dict!["first_name"] as? String
            profile.lastName = dict!["last_name"] as? String
            profile.fullName = dict!["full_name"] as? String
            profile.phone = dict!["phone"] as? String
            profile.skype = dict!["skype"] as? String
            profile.photo = FirePhoto.from(dict: dict!["photo"] as! [String : Any]?)
            return profile
        }
        return nil
    }
    
    internal var dict: [String: Any] {
        return [
            "email": self.email,
            "first_name": self.firstName,
            "last_name": self.lastName,
            "full_name": self.fullName,
            "phone": self.phone,
            "skype": self.skype,
            "photo": self.photo?.dict
        ]
    }
}
