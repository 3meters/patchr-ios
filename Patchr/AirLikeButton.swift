//
//  AirImageView.swift
//  Patchr
//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class AirLikeButton: AirToggleButton {
    
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
        self.imageOff = Utils.imageHeartOff.imageWithRenderingMode(.AlwaysTemplate)
        self.imageOn = Utils.imageHeartOn.imageWithRenderingMode(.AlwaysTemplate)
        
        super.initialize()
    }

	func bindEntity(entity: Entity?) {
		self.entity = entity
        if entity != nil {
            toggleOn(entity!.userLikesValue, animate: false)
        }
        else {
            toggleOn(false, animate: false)
        }
	}

    override func onClick(sender: AnyObject) {
        
        if self.entity == nil {
            return
        }
        
        if !UserController.instance.authenticated {
            if self.entity is Message {
				UserController.instance.showGuestGuard(controller: nil, message: Utils.LocalizedString("GUARD_LIKE"))
            }
            return
        }
        
        self.enabled = false
        self.startProgress()
        self.imageView?.alpha = 0.0
        
        if self.entity!.userLikesValue {
            
            DataController.proxibase.deleteLinkById(entity!.userLikesId!) {
                response, error in
				
				NSOperationQueue.mainQueue().addOperationWithBlock {
					self.stopProgress()
					if let error = ServerError(error) {
						UIViewController.topMostViewController()!.handleError(error)
					}
					else {
						Reporting.track("Unliked Message")
						if DataController.instance.dataWrapperForResponse(response!) != nil {
							self.entity!.userLikesId = nil
							self.entity!.userLikesValue = false
							self.entity!.countLikesValue -= 1
							try! self.entity!.managedObjectContext?.save()
						}
					}
					
					if self.messageOff != nil {
						UIShared.Toast(self.messageOff)
					}
					NSNotificationCenter.defaultCenter().postNotificationName(Events.LikeDidChange, object: self, userInfo: ["entityId":self.entity!.id_])
					self.toggleOn(self.entity!.userLikesValue)
					self.enabled = true
				}				
            }
        }
        else {
			
            DataController.proxibase.insertLink(UserController.instance.userId! as String, toID: entity!.id_, linkType: .Like) {
                response, error in

				NSOperationQueue.mainQueue().addOperationWithBlock {
					self.stopProgress()
					if let error = ServerError(error) {
						UIViewController.topMostViewController()!.handleError(error)
					}
					else {
						if let serviceData = DataController.instance.dataWrapperForResponse(response!) {
							if serviceData.countValue == 1 {
								Reporting.track("Liked Message")
								if let entityDictionaries = serviceData.data as? [[String:NSObject]] {
									let map = entityDictionaries[0]
									self.entity!.userLikesId = map["_id"] as! String
								}
								self.entity!.userLikesValue = true
								self.entity!.countLikesValue += 1
								try! self.entity!.managedObjectContext?.save()
							}
						}
					}
					if self.messageOn != nil {
						UIShared.Toast(self.messageOn)
					}
					NSNotificationCenter.defaultCenter().postNotificationName(Events.LikeDidChange, object: self, userInfo: ["entityId":self.entity!.id_])
					self.toggleOn(self.entity!.userLikesValue)
					self.enabled = true
				}
            }
        }
    }
}
