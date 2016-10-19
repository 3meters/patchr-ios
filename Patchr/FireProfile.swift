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
    var photo: FirePhoto?
    
    static func setPropertiesFromDictionary(dictionary: NSDictionary, onObject profile: FireProfile) -> FireProfile {
        profile.email = dictionary["email"] as? String
        profile.firstName = dictionary["first_name"] as? String
        profile.lastName = dictionary["last_name"] as? String
        profile.fullName = dictionary["full_name"] as? String
        if let photoMap = dictionary["photo"] as? NSDictionary {
            profile.photo = FirePhoto.setPropertiesFromDictionary(dictionary: photoMap, onObject: FirePhoto())
        }
        return profile
    }
}
