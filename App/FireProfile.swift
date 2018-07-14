//
//  FireProfile.swift
//  Patchr
//
//  Created by Jay Massena on 10/14/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import Foundation

class FireProfile: NSObject {
    
    var firstName: String?
    var fullName: String?
    var lastName: String?
    var language: String?
    var phone: String?
    var photo: FirePhoto?
    
    init(dict: [String: Any]) {
        self.firstName = dict["first_name"] as? String
        self.lastName = dict["last_name"] as? String
        self.fullName = dict["full_name"] as? String
        self.language = dict["language"] as? String
        self.phone = dict["phone"] as? String
        if (dict["photo"] as? [String : Any]) != nil {
            self.photo = FirePhoto(dict: dict["photo"] as! [String : Any])
        }
    }
}
