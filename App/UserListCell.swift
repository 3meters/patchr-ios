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
    @IBOutlet weak var settingsButton: AirButton?
    @IBOutlet weak var agoLabel: UILabel!
    @IBOutlet weak var widgetWidth: NSLayoutConstraint!
    @IBOutlet weak var profileView: UIView!
    
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
        self.settingsButton?.isHidden = true
        self.widgetWidth.constant = 0
        self.allowSelection = true
        self.userQuery?.remove()
        self.userQuery = nil
    }
    
    func bind(contact: CNContact) {
        
        self.roleLabel?.isHidden = true
        self.settingsButton?.isHidden = true
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
    
    func bind(user: FireUser?, target: String = "channel") {
        
        if let user = user {
            self.user = user
            
            self.presenceView?.bind(online: user.presence)
            if let offlineSince = user.presence as? Int64 {
                let offlineAgo = DateUtils.timeAgoShort(date: DateUtils.from(timestamp: offlineSince))
                self.agoLabel.text = offlineAgo
                self.agoLabel.isHidden = false
            }
            
            if user.id == UserController.instance.userId! {
                self.title?.text = "\(user.title) \("you_parens".localized())"
            }
            else {
                self.title?.text = user.title
            }
            
            if user.username != nil {
                self.subtitle?.text = "@\(user.username!)"
            }
            
            if target == "channel", let membership = user.membership {
                if membership.role == "owner" {
                    self.roleLabel?.text = "owner".localized()
                    self.roleLabel?.textColor = MaterialColor.deepOrange.base
                }
                else if membership.role == "editor" {
                    self.roleLabel?.text = "contributor".localized()
                    self.roleLabel?.textColor = MaterialColor.lightGreen.base
                }
                else if membership.role == "reader" {
                    self.roleLabel?.text = "reader".localized()
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
        else {
            self.title?.text = "deleted".localized()
            self.subtitle?.text = "deleted".localized()
            self.photoControl!.bind(url: nil, name: "deleted".localized(), colorSeed: nil, color: Theme.colorBackgroundImage)
        }
    }
}
