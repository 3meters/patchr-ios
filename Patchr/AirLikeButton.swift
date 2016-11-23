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

class AirLikeButton: AirToggleButton {
    
    var message         : FireMessage!
	var entityId		: String?
    var messageId       : String?
	var userLikes		= false
	var userLikesId		: String?
    
	var displayPhoto	: DisplayPhoto?

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    override func initialize(){
        self.imageOff = Utils.imageHeartOff.withRenderingMode(.alwaysTemplate)
        self.imageOn = Utils.imageHeartOn.withRenderingMode(.alwaysTemplate)
        
        super.initialize()
    }

    func bind(message: FireMessage) {
        self.message = message
        let userId = UserController.instance.userId
        let thumbsup = message.getReaction(emoji: .thumbsup, userId: userId!)
        self.toggle(on: thumbsup, animate: true)
    }

    func bind(displayPhoto: DisplayPhoto) {
		toggle(on: displayPhoto.userLikes, animate: false)
	}

    override func onClick(sender: AnyObject) {
        self.isEnabled = false
        if self.toggledOn {
            message.removeReaction(emoji: .thumbsup)
            self.toggle(on: false, animate: true)
            Reporting.track("Reaction Off")
            self.isEnabled = true
        }
        else {
            message.addReaction(emoji: .thumbsup)
            self.toggle(on: true, animate: true)
            Reporting.track("Reaction On")
            self.isEnabled = true
        }
    }
}
