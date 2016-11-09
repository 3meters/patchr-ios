//
//  PatchSearchCell.swift
//  Patchr
//
//  Created by Jay Massena on 7/15/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class UserListCell: UITableViewCell {
    
    @IBOutlet weak var photoView: PhotoView?
    @IBOutlet weak var title: UILabel?
    @IBOutlet weak var subtitle: UILabel?
    @IBOutlet weak var role: UILabel?
    @IBOutlet weak var presenceView = PresenceView()
    
    var user: FireUser!
    
    func bind(user: FireUser) {
        
        self.user = user
        self.presenceView?.bind(online: user.presence)
        self.title?.text = user.profile?.fullName
        self.subtitle?.text = "@\(user.username!)"
        self.role?.text = user.role
        
        if user.role == "admin" {
            self.role?.textColor = Colors.brandColorTextLight
        }
        else if user.role == "guest" {
            self.role?.textColor = Colors.accentColorTextLight
        }
        else {
            self.role?.textColor = Theme.colorTextSecondary
        }
        
        let fullName = user.profile?.fullName
        let photoUrl = PhotoUtils.url(prefix: user.profile?.photo?.filename, source: user.profile?.photo?.source, category: SizeCategory.profile)
        self.photoView?.bind(photoUrl: photoUrl, name: fullName, colorSeed: user.id)
    }
}
