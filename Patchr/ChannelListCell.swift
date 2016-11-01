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
    @IBOutlet weak var star: UIImageView?
    @IBOutlet weak var lock: UIImageView?
    
    var channel: FireChannel!
    
    func bind(channel: FireChannel) {
        self.channel = channel
        
        self.title?.text = "# \(channel.name!)"
        self.lock?.isHidden = (channel.visibility != "private")
        self.star?.isHidden = !(channel.favorite!)
    }
}
