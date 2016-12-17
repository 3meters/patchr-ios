//
//  Created by Jay Massena on 7/15/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class ChannelListCell: UITableViewCell {
    
    @IBOutlet weak var title: AirLabel?
    @IBOutlet weak var star: UIImageView?
    @IBOutlet weak var lock: UIImageView?
    @IBOutlet weak var status: UILabel?
    @IBOutlet weak var badge: UILabel?
    @IBOutlet weak var selectedBackground: UIView?
    @IBOutlet weak var statusWidth: NSLayoutConstraint!
    @IBOutlet weak var lockWidth: NSLayoutConstraint!
    
    var channel: FireChannel!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    func initialize() {
        self.selectedBackground?.backgroundColor = Theme.colorBackgroundBadge
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.badge?.layer.cornerRadius = (self.badge?.frame.size.height)! / 2
        self.title?.layer.cornerRadius = (self.title?.frame.size.height)! / 2
        self.selectedBackground?.layer.cornerRadius = (self.selectedBackground?.frame.size.height)! / 2
    }
    
    func selected(on: Bool) {
        if on {
            self.selectedBackground?.backgroundColor = Theme.colorBackgroundSelectedChannel
            self.selectedBackground?.isHidden = false
            self.title?.textColor = Colors.white
            self.lock?.tintColor = Colors.white
            self.star?.tintColor = Colors.white
            self.tintColor = Colors.white
            self.accessoryType = self.badge!.isHidden ? .checkmark : .none
        }
        else {
            self.selectedBackground?.backgroundColor = Colors.clear
            self.selectedBackground?.isHidden = true
            self.title?.backgroundColor = Colors.clear
            self.title?.textColor = Theme.colorText
            self.lock?.tintColor = Colors.brandColorLight
            self.star?.tintColor = Colors.brandColorLight
            self.accessoryType = .none
            self.tintColor = Colors.brandColor
        }
    }
    
    func reset() {
        selected(on: false)
        self.title?.text = nil
        self.star?.isHidden = true
        self.lock?.isHidden = true
        self.status?.isHidden = true
        self.badge?.backgroundColor = Theme.colorBackgroundBadge
        self.badge?.text = nil
        self.badge?.isHidden = true
        self.channel = nil
    }
    
    func bind(channel: FireChannel) {
        self.channel = channel
        
        self.title?.text = "# \(channel.name!)"
        self.lock?.isHidden = (channel.visibility != "private")
        self.star?.isHidden = !(channel.starred != nil && channel.starred!)
        
        if channel.joinedAt == nil {
            self.status?.isHidden = false
        }
        self.statusWidth!.constant = (self.status?.isHidden)! ? 0 : 95
        self.layoutIfNeeded()
    }
}
