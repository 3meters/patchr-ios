//
//  PatchTableViewCell.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class EmojiViewCell: UICollectionViewCell {
	
	var emojiCode: String!
    @IBOutlet weak var emojiLabel: UILabel!
    
    override var isHighlighted: Bool {
        get {
            return super.isHighlighted
        }
        set {
            if newValue {
                backgroundColor = Theme.colorBackgroundSelected
            }
            else {
                backgroundColor = Theme.colorBackgroundForm
            }
            super.isHighlighted = newValue
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    func initialize() {
        self.layer.cornerRadius = CGFloat(4)
    }
}
