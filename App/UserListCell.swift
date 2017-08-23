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
    
    @IBOutlet weak var photoControl: PhotoControl?
    @IBOutlet weak var title: UILabel?
    @IBOutlet weak var subtitle: UILabel?
    @IBOutlet weak var roleLabel: UILabel?
    @IBOutlet weak var presenceView = PresenceView()
    @IBOutlet weak var checkBox: AirCheckBox?
    @IBOutlet weak var actionButton: AirButton?
    @IBOutlet weak var agoLabel: UILabel!
    
    var allowSelection = true
    
    var user: FireUser!
    var contact: CNContact!
    var userQuery: UserQuery!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        let color = self.photoControl?.backgroundColor
        super.setSelected(selected, animated: animated)
        self.photoControl?.backgroundColor = color
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let color = self.photoControl?.backgroundColor
        super.setHighlighted(highlighted, animated: animated)
        self.photoControl?.backgroundColor = color
    }
    
    func reset() {
        self.title?.text = nil
        self.photoControl?.reset()
        self.subtitle?.text = nil
        self.subtitle?.isHidden = false
        self.roleLabel?.text = nil
        self.roleLabel?.isHidden = false
        self.presenceView?.showOffline()
        self.agoLabel.isHidden = true
        self.actionButton?.isHidden = true
        self.allowSelection = true
        self.userQuery?.remove()
        self.userQuery = nil
    }
    
    func bind(contact: CNContact) {
        
        self.roleLabel?.isHidden = true
        self.actionButton?.isHidden = true
        self.presenceView?.isHidden = true
        self.agoLabel.isHidden = true
        self.checkBox?.isHidden = false
        self.accessoryType = .none
        self.photoControl?.initialsCount = 2
        self.photoControl?.nameLabel.font = Theme.fontText
        self.contact = contact
        
        let email = contact.emailAddresses.first?.value as String!
        let fullName = CNContactFormatter.string(from: contact, style: .fullName)
        let title = fullName ?? email!
        
        if contact.imageDataAvailable {
            self.photoControl?.setImage(image: UIImage(data: contact.thumbnailImageData!))
            self.photoControl?.nameLabel.isHidden = true
        }
        else {
            self.photoControl?.bind(url: nil, name: title, colorSeed: email!)
        }
        self.title?.text = title
        self.subtitle?.text = email!
    }
    
    func bind(user: FireUser, target: String = "channel") {
        
        self.user = user
        self.presenceView?.bind(online: user.presence)
        if let offlineSince = user.presence as? Int64 {
            let offlineAgo = DateUtils.timeAgoShort(date: DateUtils.from(timestamp: offlineSince))
            self.agoLabel.text = offlineAgo
            self.agoLabel.isHidden = false
        }
        
        if user.id == UserController.instance.userId! {
            self.title?.text = "\(user.fullName!) (you)"
        }
        else {
            self.title?.text = user.fullName!
        }
        
        if user.username != nil {
            self.subtitle?.text = "@\(user.username!)"
        }
        
        if target == "channel", let membership = user.membership {
            if membership.role == "owner" {
                self.roleLabel?.text = "owner"
                self.roleLabel?.textColor = MaterialColor.deepOrange.base
            }
            else if membership.role == "editor" {
                self.roleLabel?.text = "contributor"
                self.roleLabel?.textColor = MaterialColor.lightGreen.base
            }
            else if membership.role == "reader" {
                self.roleLabel?.text = "reader"
                self.roleLabel?.textColor = MaterialColor.lightBlue.base
            }
        }
        else if target == "reaction" {
            self.roleLabel?.isHidden = true
        }
        
        let fullName = user.profile?.fullName ?? user.username
        if let photo = user.profile?.photo {
            let url = ImageProxy.url(photo: photo, category: SizeCategory.profile)
            self.photoControl!.bind(url: url, name: fullName, colorSeed: user.id)
        }
        else {
            self.photoControl?.bind(url: nil, name: fullName, colorSeed: user.id)
        }
    }
}