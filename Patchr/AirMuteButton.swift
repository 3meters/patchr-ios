//
//  AirImageView.swift
//  Patchr
//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class AirMuteButton: AirToggleButton {
    
    var entity: Entity?

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    override func initialize(){
        self.imageOff = UIImage(named: "imgSoundOff2Light")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        self.imageOn = UIImage(named: "imgSoundOn2Light")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        
        super.initialize()
    }

	func bindEntity(entity: Entity?) {
		self.entity = entity
        if let patch = self.entity as? Patch {
            toggleOn(!patch.userWatchMutedValue)
        }
	}

    func onClick(sender: AnyObject) {
    
        if self.entity == nil {
            return
        }
        
        if !UserController.instance.authenticated {
			UserController.instance.showGuestGuard(nil, message: nil)
            return
        }
        
        self.enabled = false
        self.startProgress()
        self.imageView?.alpha = 0.0
        
        let muted = !self.entity!.userWatchMutedValue
        
        DataController.proxibase.muteLinkById(self.entity!.userWatchId!, muted: muted, completion: {
            response, error in
			
			NSOperationQueue.mainQueue().addOperationWithBlock {
				self.stopProgress()
				if let error = ServerError(error) {
					UIViewController.topMostViewController()!.handleError(error)
				}
				else {
					self.entity!.userWatchMutedValue = muted
					self.toggleOn(!muted)
					
					if muted && self.messageOff != nil {
						UIShared.Toast(self.messageOff)
					}
					
					if !muted && self.messageOn != nil {
						UIShared.Toast(self.messageOn)
					}
				}				
				self.enabled = true
			}
        })
    }
}
