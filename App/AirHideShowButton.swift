//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class AirHideShowButton: AirToggleButton {
    
    /* Show or hide password */
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    override func initialize(){
        self.imageOff = UIImage(named: "imgWatch2Light")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        self.imageOn = UIImage(named: "imgWatch2FilledLight")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
		self.imageView?.contentMode = UIViewContentMode.scaleToFill
		toggle(on: false)
    }
}
