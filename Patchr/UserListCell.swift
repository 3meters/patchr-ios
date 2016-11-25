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
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        let color = self.photoView?.backgroundColor
        super.setSelected(selected, animated: animated)
        self.photoView?.backgroundColor = color
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let color = self.photoView?.backgroundColor
        super.setHighlighted(highlighted, animated: animated)
        self.photoView?.backgroundColor = color
    }
    
    func reset() {
        self.photoView?.photo.image = nil
        self.title?.text = nil
        self.subtitle?.text = nil
        self.role?.text = nil
        self.presenceView?.showOffline()
    }
    
    func bind(user: FireUser) {
        
        self.user = user
        self.presenceView?.bind(online: user.presence)
        self.title?.text = user.profile?.fullName ?? user.username
        
        if user.username != nil {
            self.subtitle?.text = "@\(user.username!)"
        }

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
        
        let fullName = user.profile?.fullName ?? user.username
        if let photo = user.profile?.photo, !photo.uploading {
            let photoUrl = PhotoUtils.url(prefix: photo.filename, source: photo.source, category: SizeCategory.profile)
            self.photoView?.bind(photoUrl: photoUrl, name: fullName, colorSeed: user.id)
        }
        else {
            self.photoView?.bind(photoUrl: nil, name: fullName, colorSeed: user.id)
        }
    }
}
