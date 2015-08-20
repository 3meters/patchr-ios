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
        self.imageOff = UIImage(named: "imgHeartLight")!
        self.imageOn = UIImage(named: "imgHeartFilledLight")!
        
        super.initialize()
    }

	func bindEntity(entity: Entity?) {
		self.entity = entity
        if entity != nil {
            toggleOn(entity!.userLikesValue)
        }
        else {
            toggleOn(false)
        }
	}

    func onClick(sender: AnyObject) {
        
        if self.entity == nil {
            return
        }
        
        if !UserController.instance.authenticated {
            if self.entity is Message {
                Shared.Toast("Sign in to like messages")
            }
            else if self.entity is Patch {
                Shared.Toast("Sign in to favorite patches")
            }
            return
        }
        
        self.enabled = false
        self.startProgress()
        self.imageView?.alpha = 0.0
        
        if entity!.userLikesValue {
            
            DataController.proxibase.deleteLinkById(entity!.userLikesId!) {
                response, error in
                
                self.stopProgress()
                if let error = ServerError(error) {
                    UIViewController.topMostViewController()!.handleError(error)
                }
                else {
                    if let serviceData = DataController.instance.dataWrapperForResponse(response!) {
                        self.entity!.userLikesId = nil
                        self.entity!.userLikesValue = false
                        self.entity!.countLikesValue--
                    }
                }
                
                if self.messageOff != nil {
                    Shared.Toast(self.messageOff)
                }
                NSNotificationCenter.defaultCenter().postNotificationName(Events.LikeDidChange, object: nil)
                self.toggleOn(self.entity!.userLikesValue)
                self.enabled = true
            }
        }
        else {
            
            DataController.proxibase.insertLink(UserController.instance.userId! as String, toID: entity!.id_, linkType: .Like) {
                response, error in
                
                self.stopProgress()
                if let error = ServerError(error) {
                    UIViewController.topMostViewController()!.handleError(error)
                }
                else {
                    if let serviceData = DataController.instance.dataWrapperForResponse(response!) {
                        if serviceData.countValue == 1 {
                            if let entityDictionaries = serviceData.data as? [[String:NSObject]] {
                                let map = entityDictionaries[0]
                                self.entity!.userLikesId = map["_id"] as! String
                            }
                            self.entity!.userLikesValue = true
                            self.entity!.countLikesValue++
                        }
                    }
                }
                if self.messageOn != nil {
                    Shared.Toast(self.messageOn)
                }
                NSNotificationCenter.defaultCenter().postNotificationName(Events.LikeDidChange, object: nil)
                self.toggleOn(self.entity!.userLikesValue)
                self.enabled = true
            }
        }
    }
}
