//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import FirebaseAuth

class ChromeViewTile: ChromeViewBase {
    
    var border = UIView(frame: .zero)
    
    /*--------------------------------------------------------------------------------------------
    * MARK: - Events
    *--------------------------------------------------------------------------------------------*/

    override func layoutSubviews() {
        /* Scrolling does not cause this to be called. */
        super.layoutSubviews()
        self.border.fillSuperview(withLeftPadding: 6, rightPadding: 6, topPadding: 3, bottomPadding: 3)
        self.border.layer.cornerRadius = 3
        self.border.showShadow(offset: CGSize(width: 0, height: 1)
            , radius: 2.0
            , rounded: true
            , opacity: 0.2
            , cornerRadius: 3)
    }

    /*--------------------------------------------------------------------------------------------
    * MARK: - Methods
    *--------------------------------------------------------------------------------------------*/
    
    override func initialize() {
        super.initialize()
        self.padding = UIEdgeInsetsMake(12, 12, 12, 12)
        self.backgroundColor = Colors.white
        self.border.backgroundColor = Colors.white
        self.addSubview(self.border)
    }
}
