//
//  MessageTableViewCell.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-12.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class MessageTableViewCell: MediaTableViewCell {
    
    @IBOutlet weak var patchNameLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var likesLabel: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updatePreferredMaxLayoutWidth(self.patchNameLabel)
        updatePreferredMaxLayoutWidth(self.userNameLabel)
        updatePreferredMaxLayoutWidth(self.likesLabel)
    }
}
