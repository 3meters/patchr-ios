//
//  Created by Jay Massena on 7/15/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import UIKit
import BEMCheckBox
import Contacts

@IBDesignable
class UserListCell: UITableViewCell {
    
    @IBOutlet weak var photoView: PhotoView?
    @IBOutlet weak var title: UILabel?
    @IBOutlet weak var subtitle: UILabel?
    @IBOutlet weak var role: UILabel?
    @IBOutlet weak var presenceView = PresenceView()
    @IBOutlet weak var checkBox: AirCheckBox?
    @IBOutlet weak var actionButton: AirButton?
    
    var allowSelection = true
    
    var user: FireUser!
    var contact: CNContact!
    
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
        self.subtitle?.isHidden = false
        self.role?.text = nil
        self.role?.isHidden = false
        self.presenceView?.showOffline()
        self.actionButton?.isHidden = true
        self.allowSelection = true
    }
    
    func bind(contact: CNContact) {
        self.role?.isHidden = true
        self.actionButton?.isHidden = true
        self.presenceView?.isHidden = true
        self.photoView?.photo.isHidden = true
        self.photoView?.name.isHidden = false
        self.checkBox?.isHidden = false
        self.accessoryType = .none
        self.photoView?.initialsCount = 2
        self.photoView?.name.font = Theme.fontText
        
        self.contact = contact
        let email = contact.emailAddresses.first?.value as String!
        let fullName = CNContactFormatter.string(from: contact, style: .fullName)
        let title = fullName ?? email!
        
        if contact.imageDataAvailable {
            self.photoView?.photo.image = UIImage(data: contact.thumbnailImageData!)
            self.photoView?.photo.isHidden = false
            self.photoView?.name.isHidden = true
        }
        else {
            self.photoView?.bind(photoUrl: nil, name: title, colorSeed: email!)
        }
        self.title?.text = title
        self.subtitle?.text = email!
    }
    
    func bind(user: FireUser) {
        
        self.user = user
        self.presenceView?.bind(online: user.presence)
        if user.id == UserController.instance.userId {
            self.title?.text = "\(user.profile?.fullName ?? user.username!) (you)"
        }
        else {
            self.title?.text = user.profile?.fullName ?? user.username!
        }
        
        if user.username != nil {
            self.subtitle?.text = "@\(user.username!)"
        }

        self.role?.text = user.role
        
        if user.role == "owner" {
            self.role?.textColor = MaterialColor.deepOrange.base
        }
        else if user.role == "admin" {
            self.role?.textColor = MaterialColor.amber.base
        }
        else if user.role == "member" {
            self.role?.textColor = MaterialColor.lightGreen.base
        }
        else if user.role == "guest" {
            self.role?.textColor = MaterialColor.lightBlue.base
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
