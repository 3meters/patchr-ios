//
//  AirImageView.swift
//  Patchr
//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class AirWatchButton: AirToggleButton {
    
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
        self.imageOff = UIImage(named: "imgWatch2Light")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        self.imageOn = UIImage(named: "imgWatch2FilledLight")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        
        super.initialize()
    }

	func bindEntity(entity: Entity?) {
		self.entity = entity
        if let patch = self.entity as? Patch {
            toggleOn(patch.userWatchStatusValue == .Member, pending: patch.userWatchStatusValue == .Pending)
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
             Shared.Toast("Sign in to watch patches")
            return
        }
        
        self.enabled = false
        self.startProgress()
        self.imageView?.alpha = 0.0
        let patch = self.entity as? Patch
        
        if patch!.userWatchStatusValue == .Member {
            /* TODO: If not owner then confirm leave */
            DataController.proxibase.deleteLinkById(patch!.userWatchId!) {
                response, error in
                
                self.stopProgress()
                if let error = ServerError(error) {
                    UIViewController.topMostViewController()!.handleError(error)
                }
                else {
                    if let serviceData = DataController.instance.dataWrapperForResponse(response!) {
                        patch!.userWatchId = nil
                        patch!.userWatchStatusValue = .NonMember
                        patch!.countWatchingValue--
                    }
                }
                NSNotificationCenter.defaultCenter().postNotificationName(Events.WatchDidChange, object: nil)
                self.toggleOn(patch!.userWatchStatusValue == .Member)
                self.enabled = true
            }
        }
        else if patch!.userWatchStatusValue == .Pending {
            DataController.proxibase.deleteLinkById(patch!.userWatchId!) {
                response, error in
                
                self.stopProgress()
                if let error = ServerError(error) {
                    UIViewController.topMostViewController()!.handleError(error)
                }
                else {
                    if let serviceData = DataController.instance.dataWrapperForResponse(response!) {
                        patch!.userWatchId = nil
                        patch!.userWatchStatusValue = .NonMember
                    }
                }
                NSNotificationCenter.defaultCenter().postNotificationName(Events.WatchDidChange, object: nil)
                self.toggleOn(patch!.userWatchStatusValue == .Member)
                self.enabled = true
            }
        }
        else if patch!.userWatchStatusValue == .NonMember {
            /* Service automatically sets enabled = false if user is not the patch owner */
            DataController.proxibase.insertLink(UserController.instance.userId! as String, toID: patch!.id_, linkType: .Watch) {
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
                                patch!.userWatchId = map["_id"] as! String
                                if let enabled = map["enabled"] as? Bool {
                                    if enabled {
                                        patch!.userWatchStatusValue = .Member
                                        patch!.countWatchingValue++
                                    }
                                    else {
                                        patch!.userWatchStatusValue = .Pending
                                    }
                                }
                            }
                        }
                    }
                }
                NSNotificationCenter.defaultCenter().postNotificationName(Events.WatchDidChange, object: nil)
                self.toggleOn(patch!.userWatchStatusValue == .Member, pending: patch!.userWatchStatusValue == .Pending)
                self.enabled = true
            }
        }
    }
}
