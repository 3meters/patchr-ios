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
        self.imageOff = UIImage(named: "imgSoundOff2Light")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        self.imageOn = UIImage(named: "imgSoundOn2Light")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        
        super.initialize()
    }

	func bindEntity(entity: Entity?) {
		self.entity = entity
        if let patch = self.entity as? Patch {
            toggleOn(on: !patch.userWatchMutedValue, animate: false)
        }
	}

    override func onClick(sender: AnyObject) {
    
        if self.entity == nil {
            return
        }
        
        self.isEnabled = false
        self.startProgress()
        self.imageView?.alpha = 0.0
        
        let muted = !self.entity!.userWatchMutedValue
        
        DataController.proxibase.muteLinkById(linkId: self.entity!.userWatchId!, muted: muted, completion: {
            response, error in
			
			OperationQueue.main.addOperation {
				self.stopProgress()
				if let error = ServerError(error) {
					UIViewController.topMostViewController()!.handleError(error)
				}
				else {
					self.entity!.userWatchMutedValue = muted
					self.toggleOn(on: !muted)
					Reporting.track(muted ? "Muted Patch" : "Unmuted Patch")
					
					if muted && self.messageOff != nil {
						UIShared.Toast(message: self.messageOff)
					}
					
					if !muted && self.messageOn != nil {
						UIShared.Toast(message: self.messageOn)
					}
				}				
				self.isEnabled = true
			}
        })
    }
}
