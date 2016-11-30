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
    @IBOutlet weak var statusWidth: NSLayoutConstraint!
    @IBOutlet weak var lockWidth: NSLayoutConstraint!
    
    var channel: FireChannel!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.badge?.layer.cornerRadius = (self.badge?.frame.size.width)! / 2
    }
    
    func reset() {
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
