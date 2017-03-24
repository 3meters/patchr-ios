//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class AirLabelStack: AirRuleView {
    
    var caption = AirLabelDisplay()
    var label = AirLabelDisplay()
    
	override func initialize() {
        super.initialize()
        self.caption.textColor = Colors.gray66pcntColor
        self.addSubview(self.caption)
        self.addSubview(self.label)
	}
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.label.sizeToFit()
        self.label.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 12, height: self.label.height())
        self.caption.sizeToFit()
        self.caption.align(above: self.label, matchingLeftWithBottomPadding: 4, width: self.caption.width(), height: self.caption.height())
    }
}
