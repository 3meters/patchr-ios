//
//  AirImageView.swift
//  Patchr
//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class AirToggleButton: AirImageButton {
    
    var imageOff: UIImage?
    var imageOn: UIImage?
    var messageOn: String?
    var messageOff: String?
    
    var toggledOn: Bool = false
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
	
	func onClick(sender: AnyObject) { }
		
    override func initialize() {
        super.initialize()
        toggle(on: false, animate: false)
        self.progressAuto = false
        self.addTarget(self, action: #selector(onClick(sender:)), for: .touchUpInside)
    }
    
    func toggle(on: Bool, animate: Bool = true) {
        if on {
            self.setImage(imageOn, for: .normal)
        }
        else {
            self.setImage(imageOff, for: .normal)
        }
        self.toggledOn = on
		if animate {
			Animation.bounce(view: self)
		}
    }
}
