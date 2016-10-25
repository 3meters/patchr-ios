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
    
    required convenience init?(dict: [String: Any], id: String?) {
        self.init()
        self.email = dict["email"] as? String
        self.firstName = dict["first_name"] as? String
        self.lastName = dict["last_name"] as? String
        self.fullName = dict["full_name"] as? String
        self.phone = dict["phone"] as? String
        self.skype = dict["skype"] as? String
        if (dict["photo"] as? NSDictionary) != nil {
            self.photo = FirePhoto(dict: dict["photo"] as! [String: Any], id: nil)
        }
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
