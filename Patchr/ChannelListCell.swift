//
//  Created by Jay Massena on 7/15/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class ChannelListCell: UITableViewCell {
    
    @IBOutlet weak var title: UILabel?
    @IBOutlet weak var star: UIImageView?
    @IBOutlet weak var lock: UIImageView?
    @IBOutlet weak var status: UILabel?
    @IBOutlet weak var badge: UILabel?
    @IBOutlet weak var statusWidth: NSLayoutConstraint?
    @IBOutlet weak var lockWidth: NSLayoutConstraint?
    
    var channel: FireChannel!
    var unreadQuery: UnreadQuery?   // Passed in by table data source
    var channelQuery: ChannelQuery?
    var selectedOn = false
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.badge?.layer.cornerRadius = (self.badge?.frame.size.height)! / 2
    }
    
    func selected(on: Bool, style: SelectedStyle = .prominent) {
        self.selectedOn = on
        if on {
            self.accessoryType = .checkmark
            if style != .minimal {
                self.title?.font = UIFont(name: "HelveticaNeue-Medium", size: (self.title?.font.pointSize)!)
            }
            if style == .prominent {
                self.backgroundColor = Theme.colorBackgroundSelected
            }
        }
        else {
            self.accessoryType = .none
            self.title?.font = UIFont(name: "HelveticaNeue-Light", size: (self.title?.font.pointSize)!)
            self.backgroundColor = Colors.white
        }
    }
    
    func reset() {
        self.selected(on: false)
        self.title?.text = nil
        self.star?.isHidden = true
        self.lock?.isHidden = true
        self.status?.isHidden = true
        self.badge?.backgroundColor = Theme.colorBackgroundBadge
        self.badge?.text = nil
        self.badge?.isHidden = true
        self.channel = nil
        self.channelQuery?.remove()
        self.channelQuery = nil
        self.unreadQuery?.remove()
        self.unreadQuery = nil
    }
    
    func bind(channel: FireChannel, searching: Bool = false) {
        self.channel = channel
        
        self.title?.text = "# \(channel.name!)"
        self.title?.sizeToFit()
        self.lock?.isHidden = (channel.visibility != "private")
        self.star?.isHidden = !(channel.starred != nil && channel.starred!)
        self.lockWidth?.constant = (self.lock?.isHidden)! ? 0 : 16

        if searching {
            if channel.joinedAt != nil {
                self.status?.isHidden = false
                self.status?.text = "in"
                self.status?.textColor = Colors.accentColorTextLight
                self.statusWidth?.constant = 24
            }
            else {
                self.status?.isHidden = true
                self.statusWidth?.constant = 0
            }
        }
        self.layoutIfNeeded()
    }
}

enum SelectedStyle: Int {
    case prominent
    case normal
    case minimal
}
