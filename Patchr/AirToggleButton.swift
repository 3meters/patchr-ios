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
    var tintOff: UIColor = Colors.brandColor
    var tintOn: UIColor = Colors.brandColor
    var tintPending: UIColor = Colors.brandColor
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
    
    override func initialize(){
        super.initialize()
        self.spot?.removeFromSuperlayer()
        toggleOn(false)
        self.progressAuto = false
        self.imageView?.contentMode = UIViewContentMode.ScaleToFill
        self.addTarget(self, action: Selector("onClick:"), forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    func toggleOn(on: Bool, pending: Bool = false) {
        if on {
            self.setImage(imageOn, forState: .Normal)
            self.tintColor = self.tintOn
            self.imageView?.tintColor(self.tintOn)
        }
        else {
            self.setImage(imageOff, forState: .Normal)
            self.tintColor = self.tintOff
            self.imageView?.tintColor(pending ? self.tintPending : self.tintOff)
        }
        self.toggledOn = on
    }
}
