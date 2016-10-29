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
class ChannelListCell: UITableViewCell {
    
    @IBOutlet weak var title: UILabel?
    @IBOutlet weak var icon: UIImageView?
    
    var channel: FireChannel!
    
    func bind(channel: FireChannel) {
        self.channel = channel
        
        self.title?.text = "# \(channel.name!)"
        self.icon?.isHidden = (channel.visibility != "private")
    }
}
