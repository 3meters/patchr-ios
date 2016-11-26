//
//  AirImageView.swift
//  Patchr
//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import Firebase

class AirMuteView: AirToggleImage {
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    override func initialize(){
        self.imageOn = UIImage(named: "imgSoundOff2Light")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        self.imageOff = UIImage(named: "imgSoundOn2Light")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        super.initialize()
    }

    func bind(channel: FireChannel) {
        toggle(on: (channel.muted != nil && channel.muted!), animate: false)
        self.isHidden = (channel.muted == nil || !channel.muted!)
        self.superview?.superview?.superview?.setNeedsLayout() /* Don't love this hack to reach up the view heirarchy */
    }
}
