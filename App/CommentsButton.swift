//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import Emoji
import STPopup

class CommentsButton: AirButton {
    
    var message: FireMessage!

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Events
     *--------------------------------------------------------------------------------------------*/
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Methods
     *--------------------------------------------------------------------------------------------*/

    override func initialize() {
        super.initialize()
        self.titleLabel!.font = Theme.fontCommentSmall
        self.setTitleColor(Theme.colorButtonBorder, for: .normal)
        self.setTitleColor(Theme.colorButtonTitleHighlighted, for: .highlighted)
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    }
    
    func bind(message: FireMessage) {
        self.message = message
    }
    
    func reset() {
        self.setTitleColor(Theme.colorButtonBorder, for: .normal)
        self.setTitleColor(Theme.colorButtonTitleHighlighted, for: .highlighted)
    }
}
