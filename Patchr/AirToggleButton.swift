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
		
    override func initialize(){
        super.initialize()
        toggleOn(false, animate: false)
        self.progressAuto = false
        self.addTarget(self, action: #selector(AirToggleButton.onClick(_:)), forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    func toggleOn(on: Bool, animate: Bool = true) {
        if on {
            self.setImage(imageOn, forState: .Normal)
        }
        else {
            self.setImage(imageOff, forState: .Normal)
        }
        self.toggledOn = on
		if animate {
			Animation.bounce(self)
		}
    }
}
