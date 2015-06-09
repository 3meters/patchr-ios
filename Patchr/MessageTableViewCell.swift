//
//  MessageTableViewCell.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-12.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class MessageTableViewCell: MediaTableViewCell {
    
    @IBOutlet weak var patchName: UILabel!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var likes: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()

        updatePreferredMaxLayoutWidth(self.patchName)
        updatePreferredMaxLayoutWidth(self.userName)
        updatePreferredMaxLayoutWidth(self.likes)
    }
}
