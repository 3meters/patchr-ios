//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import FirebaseAuth

class ChromeViewRuled: ChromeViewBase {
    
    var rule = UIView(frame: .zero)

    /*--------------------------------------------------------------------------------------------
    * MARK: - Events
    *--------------------------------------------------------------------------------------------*/

    override func layoutSubviews() {
        /* Scrolling does not cause this to be called. */
        super.layoutSubviews()
        let viewWidth = self.bounds.size.width
        self.rule.anchorBottomCenter(withBottomPadding: 0, width: viewWidth, height: 1.0)
    }

    /*--------------------------------------------------------------------------------------------
    * MARK: - Methods
    *--------------------------------------------------------------------------------------------*/
    
    override func initialize() {
        super.initialize()
        self.padding = UIEdgeInsetsMake(12, 12, 12, 12)
        self.backgroundColor = Colors.white
        self.rule.backgroundColor = Theme.colorRule
        self.addSubview(self.rule)
    }
}
