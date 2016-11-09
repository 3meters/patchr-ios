//
//  AirImageView.swift
//  Patchr
//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class AirStarButton: AirToggleButton {
    
    var channel: FireChannel!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    override func initialize(){
        self.imageOff = Utils.imageStarOff.withRenderingMode(.alwaysTemplate)
        self.imageOn = Utils.imageStarOn.withRenderingMode(.alwaysTemplate)        
        super.initialize()
    }

    func bind(channel: FireChannel) {
        self.channel = channel
        toggle(on: channel.starred!, animate: false)
    }

    override func onClick(sender: AnyObject) {
        self.channel.star(on: !self.toggledOn)
        toggle(on: !self.toggledOn, animate: true)
    }
}
