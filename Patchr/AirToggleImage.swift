//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class AirToggleImage: AirImageView {
    
    var imageOff: UIImage?
    var imageOn: UIImage?
    
    var toggledOn: Bool = false
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
		
    override func initialize(){
        super.initialize()
        self.enableLogging = false
        toggle(on: false, animate: false)
    }
    
    func toggle(on: Bool, animate: Bool = true) {
        self.image = on ? self.imageOn : self.imageOff
        self.toggledOn = on
		if animate {
			Animation.bounce(view: self)
		}
    }
}
