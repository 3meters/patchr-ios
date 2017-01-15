//
//  Created by Jay Massena on 7/15/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import UIKit
import BEMCheckBox
import Contacts

@IBDesignable
class InviteListCell: UITableViewCell {
    
    @IBOutlet weak var iconImage: UIImageView?
    @IBOutlet weak var photoControl: PhotoControl?
    @IBOutlet weak var title: UILabel?
    @IBOutlet weak var subtitle: UILabel?
    @IBOutlet weak var invitedAs: UILabel?
    @IBOutlet weak var invitedBy: UILabel?
    @IBOutlet weak var actionAt: UILabel?
    @IBOutlet weak var resendButton: AirButton?
    @IBOutlet weak var revokeButton: AirButton?
    
    var allowSelection = true
    
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
        self.subtitle?.text = nil
        self.subtitle?.isHidden = false
        self.resendButton?.isHidden = true
        self.revokeButton?.isHidden = true
        self.allowSelection = true
    }
    
    func bind(user: FireUser, invite: [String: Any]) {
        
        if let acceptedAt = invite["accepted_at"] as? Int,
            let inviter = invite["inviter"] as? [String: Any],
            let username = inviter["username"] as? String,
            let group = invite["group"] as? [String: Any] {
    
            self.iconImage?.tintColor = MaterialColor.lightGreen.darken1
            self.title?.text = user.profile?.fullName ?? user.username!
            
            if user.username != nil {
                self.subtitle?.text = "@\(user.username!) • \(user.email!)"
            }
            
            if let channels = invite["channels"] as? [String: Any] {
                var channelsLabel = ""
                for channelName in channels.values {
                    if !channelsLabel.isEmpty {
                        channelsLabel += ", "
                    }
                    channelsLabel += "#\(channelName as! String)"
                }
                self.invitedAs?.text = "Invited as guest of channels: \(channelsLabel)"
            }
            else {
                let groupTitle = group["title"] as! String
                self.invitedAs?.text = "Invited as member of \"\(groupTitle)\" group"
            }
            
            self.invitedBy?.text = "Invited by \(username)"
            self.actionAt?.text = "Accepted \(UIShared.dateMediumString(timestamp: acceptedAt))"
            self.actionAt?.textColor = MaterialColor.lightGreen.darken1
            
            let fullName = user.profile?.fullName ?? user.username
            let userId = user.id!
            if let photo = user.profile?.photo, photo.uploading == nil {
                if let url = PhotoUtils.url(prefix: photo.filename, source: photo.source, category: SizeCategory.profile) {
                    let fallbackUrl = PhotoUtils.fallbackUrl(prefix: photo.filename!)
                    self.photoControl!.bind(url: url, fallbackUrl: fallbackUrl, name: fullName, colorSeed: userId)
                }
            }
            else {
                self.photoControl?.bind(url: nil, fallbackUrl: nil, name: fullName, colorSeed: user.id)
            }
        }
    }
    
    func bind(invite: [String: Any]) {
        /* Pending */
        if let invitedAt = invite["invited_at"] as? Int,
            let inviter = invite["inviter"] as? [String: Any],
            let username = inviter["username"] as? String,
            let email = invite["email"] as? String,
            let group = invite["group"] as? [String: Any] {
            
            self.iconImage?.tintColor = Colors.accentColor
            
            self.title?.text = email
            if let channels = invite["channels"] as? [String: Any] {
                var channelsLabel = ""
                for channelName in channels.values {
                    if !channelsLabel.isEmpty {
                        channelsLabel += ", "
                    }
                    channelsLabel += "#\(channelName as! String)"
                }
                self.invitedAs?.text = "Invited as guest of channels: \(channelsLabel)"
            }
            else {
                let groupTitle = group["title"] as! String
                self.invitedAs?.text = "Invited as member of \"\(groupTitle)\" group"
            }
            
            self.invitedBy?.text = "Invited by \(username)"
            self.actionAt?.text = "Invited on \(UIShared.dateMediumString(timestamp: invitedAt))"
            self.actionAt?.textColor = Colors.accentColorTextLight
        }
    }
}
