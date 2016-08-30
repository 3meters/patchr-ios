//
//  AirImageView.swift
//  Patchr
//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class AirLikeButton: AirToggleButton {
    
    var entity			: Entity?
	var entityId		: String?
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
        self.imageOff = Utils.imageHeartOff.imageWithRenderingMode(.AlwaysTemplate)
        self.imageOn = Utils.imageHeartOn.imageWithRenderingMode(.AlwaysTemplate)
        
        super.initialize()
    }

	func bindEntity(entity: Entity?) {
		self.entity = entity
        if entity != nil {
			self.entityId = self.entity!.id_
			self.userLikes = self.entity!.userLikesValue
			self.userLikesId = self.entity!.userLikesId
            toggleOn(self.userLikes, animate: false)
        }
        else {
            toggleOn(false, animate: false)
        }
	}
	
	func bind(displayPhoto: DisplayPhoto) {
		self.displayPhoto = displayPhoto
		self.entityId = displayPhoto.entityId
		self.userLikes = displayPhoto.userLikes
		self.userLikesId = displayPhoto.userLikesId
		
		if let message: Message? = Message.fetchOneById(self.entityId!, inManagedObjectContext: DataController.instance.mainContext) {
			self.entity = message
		}

		toggleOn(self.userLikes, animate: false)
	}

    override func onClick(sender: AnyObject) {
        
        if self.entity == nil && self.entityId == nil {
            return
        }
        
        self.enabled = false
        self.startProgress()
        self.imageView?.alpha = 0.0
        
        if self.userLikes {
            
            DataController.proxibase.deleteLinkById(self.userLikesId!) {
                response, error in
				
				NSOperationQueue.mainQueue().addOperationWithBlock {
					self.stopProgress()
					if let error = ServerError(error) {
						UIViewController.topMostViewController()!.handleError(error)
					}
					else {
						Reporting.track("Unliked Message")
						if DataController.instance.dataWrapperForResponse(response!) != nil {
							if self.entity != nil {
								self.entity!.userLikesId = nil
								self.entity!.userLikesValue = false
								self.entity!.countLikesValue -= 1
								try! self.entity!.managedObjectContext?.save()
							}
							
							if self.displayPhoto != nil {
								self.displayPhoto!.userLikesId = nil
								self.displayPhoto!.userLikes = false
							}
						}
					}
					
					if self.messageOff != nil {
						UIShared.Toast(self.messageOff)
					}
					
					NSNotificationCenter.defaultCenter().postNotificationName(Events.LikeDidChange, object: self, userInfo: ["entityId":self.entityId!])
					self.toggleOn(false)
					self.enabled = true
				}				
            }
        }
        else {
			
            DataController.proxibase.insertLink(UserController.instance.userId! as String, toID: self.entityId!, linkType: .Like) {
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
									if self.entity != nil {
										self.entity!.userLikesId = map["_id"] as! String
										self.entity!.userLikesValue = true
										self.entity!.countLikesValue += 1
										try! self.entity!.managedObjectContext?.save()
									}
									
									if self.displayPhoto != nil {
										self.displayPhoto!.userLikesId = map["_id"] as? String
										self.displayPhoto!.userLikes = true
									}
								}
							}
						}
					}
					
					if self.messageOn != nil {
						UIShared.Toast(self.messageOn)
					}
					
					NSNotificationCenter.defaultCenter().postNotificationName(Events.LikeDidChange, object: self, userInfo: ["entityId":self.entityId!])
					self.toggleOn(true)
					self.enabled = true
				}
            }
        }
    }
}
