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
    @IBOutlet weak var title: UILabel?
    @IBOutlet weak var subtitle: UILabel?
    @IBOutlet weak var invitedAs: UILabel?
    @IBOutlet weak var invitedBy: UILabel?
    @IBOutlet weak var actionAt: UILabel?
    @IBOutlet weak var resendButton: AirButton?
    @IBOutlet weak var revokeButton: AirButton?
    
    var userQuery: UserQuery!
    var data: AnyObject?
    var allowSelection = true
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
    }
    
    func reset() {
        self.title?.text = nil
        self.subtitle?.text = nil
        self.invitedAs?.text = nil
        self.invitedBy?.text = nil
        self.actionAt?.text = nil
        self.subtitle?.isHidden = false
        self.resendButton?.isHidden = true
        self.revokeButton?.isHidden = true
        self.allowSelection = true
        self.userQuery?.remove()
        self.userQuery = nil
    }
    
    func bind(user: FireUser, invite: [String: Any]) {
        
        if let acceptedAt = invite["accepted_at"] as? Int64,
            let inviter = invite["inviter"] as? [String: Any],
            let username = inviter["username"] as? String,
            let group = invite["group"] as? [String: Any] {
    
            self.iconImage?.tintColor = MaterialColor.lightGreen.darken1
            self.title?.text = user.profile?.fullName ?? user.username!
            
            if user.username != nil {
                if user.email != nil {
                    self.subtitle?.text = "@\(user.username!) • \(user.email!)"
                }
                else if user.role != nil {
                    self.subtitle?.text = "@\(user.username!) • (email hidden)"
                }
                else {
                    self.subtitle?.text = "@\(user.username!)"
                }
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
            self.actionAt?.text = "Accepted \(DateUtils.dateMediumString(timestamp: acceptedAt))"
            self.actionAt?.textColor = MaterialColor.lightGreen.darken1
        }
    }
    
    func bind(invite: [String: Any]) {
        /* Pending */
        if let invitedAt = invite["invited_at"] as? Int64,
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
            self.actionAt?.text = "Invited on \(DateUtils.dateMediumString(timestamp: invitedAt))"
            self.actionAt?.textColor = Colors.accentColorTextLight
        }
    }
}
