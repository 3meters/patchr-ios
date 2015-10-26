//
//  Extensions.swift
//  Patchr
//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation

extension ServiceBase {
    
    func criteria(activityOnly: Bool = false) -> [String: AnyObject] {
        if activityOnly {
            return self.activityDate == nil ? [:] : ["activityDate":["$gt":(self.activityDate.timeIntervalSince1970 * 1000)]]
        }
        else {
            if self.activityDate == nil {
                return [:]
            }
            else {
                let activityClause = ["activityDate":["$gt":(self.activityDate.timeIntervalSince1970 * 1000)]]
                let modifiedClause = ["modifiedDate":["$gt":(self.modifiedDate.timeIntervalSince1970 * 1000)]]
                return activityOnly ? activityClause : ["$or":[activityClause, modifiedClause]]
            }
        }
    }
}

extension Entity {
    
    func distance() -> Float? {
        if let lastLocation = LocationController.instance.lastLocationFromManager(), location = self.location {
            let entityLocation = CLLocation(latitude: location.latValue, longitude: location.lngValue)
            return Float(lastLocation.distanceFromLocation(entityLocation))
        }
        return nil
    }
    
    func getPhotoManaged() -> Photo {
        var photo = self.photo
        if photo == nil {
            var id: String?
            
            /* For notification and shortcuts, we cherry pick the user id. */
            if let notification = self as? Notification {
                id = notification.userId
            }
            else if let shortcut = self as? Shortcut {
                id = shortcut.ownerId
            }
            else if let user = self as? User {
                id = user.id_
            }
            
            photo = Entity.getDefaultPhoto(self.schema, id: id)
            photo.usingDefaultValue = true
        }
        return photo
    }
    
    static func getDefaultPhoto(schema: String, id: String?) -> Photo {
        
        var prefix: String = "imgDefaultPatch"
        var source: String = PhotoSource.resource
        
        if schema == "place" {
            prefix = "imgDefaultPlace";
        }
        else if schema == "user" || schema == "notification" {
            if id != nil {
                prefix = "http://www.gravatar.com/avatar/\(id!.md5)?d=identicon&r=pg"
                source = PhotoSource.gravatar
            }
            else {
                prefix = "imgDefaultUser"
            }
        }
        
        let photo = Photo.insertInManagedObjectContext(DataController.instance.managedObjectContext) as! Photo
        photo.prefix = prefix
        photo.source = source
        
        return photo;
    }
}

extension Patch {
    
	static func bindView(view: UIView, entity: AnyObject, location: CLLocation?) -> UIView {
        
        let entity = entity as! Entity
        let view = view as! PatchView
		
		view.entity = entity

        view.name.text = entity.name
        if entity.type != nil {
            view.type.text = entity.type.uppercaseString + " PATCH"
        }
		
		if let patch = entity as? Patch {
			
			view.messagesGroup.hidden = false
			view.watchingGroup.hidden = false
			view.rule.hidden = false
			
			view.placeName.text = patch.place?.name.uppercaseString
			view.visibility.hidden = (patch.visibility == "public")
			view.status.hidden = true
			if (patch.userWatchStatusValue == .Pending && !SCREEN_NARROW) {
				view.status.hidden = false
			}
			
			view.messageCount.text = "--"
			view.watchingCount.text = "--"
			
			if let numberOfMessages = patch.numberOfMessages {
				view.messageCount.text = numberOfMessages.stringValue
			}
			
			if let numberOfWatching = patch.countWatching {
				view.watchingCount.text = numberOfWatching.stringValue
			}
		}
		else {
			/* This is a shortcut with a subset of the info */
			view.messagesGroup.hidden = true
			view.watchingGroup.hidden = true
			view.rule.hidden = true
		}
		
        /* Distance */
		if location == nil {
			view.distance.hidden = true
		}
		else {
			view.distance.hidden = false
			view.distance.text = "--"
			if let loc = entity.location {
				let patchLocation = CLLocation(latitude: loc.latValue, longitude: loc.lngValue)
				let dist = Float(location!.distanceFromLocation(patchLocation))  // in meters
				view.distance.text = LocationController.instance.distancePretty(dist)
			}
		}

		view.photo.showGradient = true
		view.photo.setImageWithPhoto(entity.getPhotoManaged(), animate: view.photo.image == nil)
		
        return view
    }
    
    static func extras(inout parameters: [String:AnyObject]) -> [String:AnyObject] {
        if let links = Patch.links() {
            parameters["links"] = links
        }
        if let linked = Patch.linked() {
            parameters["linked"] = linked
        }
        if let linkCount = Patch.linkCount() {
            parameters["linkCount"] = linkCount
        }
        return parameters
    }
    
    static func links() -> [[String:AnyObject]]? {
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if let userId = userDefaults.stringForKey(PatchrUserDefaultKey("userId")) {
            let links = [
                LinkSpec(from: .Users, type: .Like, fields: "_id,type,schema", filter: ["_from": userId]),
                LinkSpec(from: .Users, type: .Watch, fields: "_id,type,enabled,mute,schema", filter: ["_from": userId]),
                LinkSpec(from: .Messages, type: .Content, limit: 1, fields: "_id,type,schema", filter: ["_creator": userId]),
            ]
            
            let array = links.map {
                $0.toDictionary() // Returns an array of maps
            }
            
            return array
        }
        
        return nil
    }
    
    static func linked() -> [[String:AnyObject]]? {
        
        let links = [
            LinkSpec(to: .Places, type: .Proximity, fields: "_id,name,photo,schema,type" ), // Place the patch is linked to
            LinkSpec(from: .Users, type: .Create, fields: "_id,name,photo,schema,type" ), // User who created the patch
        ]
        
        let array = links.map {
            $0.toDictionary() // Returns an array of maps
        }
        
        return array
    }
    
    static func linkCount() -> [[String:AnyObject]]? {
        
        let links = [
            LinkSpec(from: .Messages, type: .Content),  // Count of messages linked to the patch
            LinkSpec(from: .Users, type: .Like),        // Count of users that like the patch
            LinkSpec(from: .Users, type: .Watch, enabled: true)        // Count of users that are watching the patch
        ]
        
        let array = links.map {
            $0.toDictionary() // Returns an array of maps
        }
        
        return array
    }
}

extension Message {
    
    static func bindView(view: UIView, entity: AnyObject) -> UIView {
        
        let entity = entity as! Entity
        let view = view as! MessageView
        
        view.entity = entity
        
        let linkColor = Colors.brandColorDark
        let linkActiveColor = Colors.brandColorLight
		
		view.description_?.linkAttributes = [kCTForegroundColorAttributeName : linkColor]
		view.description_?.activeLinkAttributes = [kCTForegroundColorAttributeName : linkActiveColor]
		view.description_?.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue|NSTextCheckingType.Address.rawValue
		
		if let description = entity.description_ {
			view.description_?.text = description
		}
		
		let options: SDWebImageOptions = [.RetryFailed, .LowPriority,  .ProgressiveDownload]
		
        if let photo = entity.photo {
			let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!, category: SizeCategory.standard, size: nil)
			view.photo?.sd_setImageWithURL(photoUrl, forState: UIControlState.Normal, placeholderImage: nil, options: options)
        }
		
		view.userName.text = entity.creator?.name ?? "Deleted"
		
		if let photo = entity.creator?.getPhotoManaged() {
			let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!, category: SizeCategory.profile, size: nil)
			view.userPhoto.sd_setImageWithURL(photoUrl, placeholderImage: nil, options: options)
		}
		else {
			let photo = Entity.getDefaultPhoto("user", id: nil)
			let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!, category: SizeCategory.profile, size: nil)
			view.userPhoto.sd_setImageWithURL(photoUrl, placeholderImage: nil, options: options)
		}
		
		if let message = entity as? Message {
			
			/* Patch */
			if message.patch != nil {
				view.patchName.text = message.patch.name
			}
			/* Likes button */
			view.likeButton.bindEntity(message)
			
			if message.countLikes != nil {
				if message.countLikes?.integerValue != 0 {
					let likesTitle = message.countLikes?.integerValue == 1
						? "\(message.countLikes) like"
						: "\(message.countLikes ?? 0) likes"
					view.likes.text = likesTitle
				}
			}
		}
		
        view.createdDate.text = Utils.messageDateFormatter.stringFromDate(entity.createdDate)
		
        return view
    }
    
    static func extras(inout parameters: [String:AnyObject]) -> [String:AnyObject] {
        if let links = Message.links() {
            parameters["links"] = links
        }
        if let linked = Message.linked() {
            parameters["linked"] = linked
        }
        if let linkCount = Message.linkCount() {
            parameters["linkCount"] = linkCount
        }
        return parameters
    }

    static func links() -> [[String:AnyObject]]? {
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if let userId = userDefaults.stringForKey(PatchrUserDefaultKey("userId")) {
            let links = [
                LinkSpec(from: .Users, type: .Like, fields: "_id,type,schema", filter: ["_from": userId])
            ]
            let array = links.map {
                $0.toDictionary() // Returns an array of maps
            }
            return array
        }
        
        return nil
    }
    
    static func linked() -> [[String:AnyObject]]? {
        
        /* Used to get the creator for the a shared message */
        let linked = [
            LinkSpec(from: .Users, type: .Create, fields: "_id,name,photo,schema,type" )
        ]
        
        /* Used to get count of messages and users watching a shared patch */
        let linkCount = [
            LinkSpec(from: .Users, type: .Watch, enabled: true),        // Count of users that are watching the patch
            LinkSpec(from: .Messages, type: .Content)    // Count of message to the patch
        ]
        
        let links = [
            LinkSpec(to: .Patches, type: .Content, fields: "_id,name,photo,schema,type", limit: 1), // Patch the message is linked to
            LinkSpec(from: .Users, type: .Create, fields: "_id,name,photo,schema,type" ),           // User who created the message
            LinkSpec(to: .Messages, type: .Share, limit: 1, linked: linked),                        // Message this message is sharing
            LinkSpec(to: .Patches, type: .Share, limit: 1, linkCount: linkCount),                   // Patch this message is sharing
            LinkSpec(to: .Users, type: .Share, limit: 5)                                            // Users this message is shared with
        ]
        
        let array = links.map {
            $0.toDictionary() // Returns an array of maps
        }
        
        return array
    }
    
    static func linkCount() -> [[String:AnyObject]]? {
        
        let links = [
            LinkSpec(from: .Users, type: .Like)
        ]
        
        let array = links.map {
            $0.toDictionary() // Returns an array of maps
        }
        
        return array
    }
}

extension User {
    
    static func bindView(view: UIView, entity: AnyObject) {
        
        let entity = entity as! Entity
        let view = view as! UserView
		
		view.entity = entity
		
        view.name.text = entity.name
        view.photo.setImageWithPhoto(entity.getPhotoManaged(), animate: view.photo.image == nil)
		
		if let user = entity as? User {
			view.area.text = user.area?.uppercaseString
			view.area.hidden = (view.area.text == nil)
			view.owner.hidden = true
			view.removeButton.hidden = true
			view.approved.hidden = true
			view.approvedSwitch.hidden = true
		}		
    }
	
    static func extras(inout parameters: [String:AnyObject]) -> [String:AnyObject] {
        if let links = User.links() {
            parameters["links"] = links
        }
        if let linked = User.linked() {
            parameters["linked"] = linked
        }
        if let linkCount = User.linkCount() {
            parameters["linkCount"] = linkCount
        }
        return parameters
    }
    
    static func links() -> [[String:AnyObject]]? {
        return nil
    }
    
    static func linked() -> [[String:AnyObject]]? {
        return nil
    }
    
    static func linkCount() -> [[String:AnyObject]]? {
        
        let links = [
            LinkSpec(to: .Patches, type: .Like), // Count of patches the user has liked
            LinkSpec(to: .Patches, type: .Create), // Count of patches the user created
            LinkSpec(to: .Patches, type: .Watch, enabled: true), // Count of patches the user is watching
        ]
        
        let array = links.map {
            $0.toDictionary() // Returns an array of maps
        }
        
        return array
    }
}

extension Notification {
    
    static func bindView(view: UIView, entity: AnyObject) -> UIView {
		
		let notification = entity as! Notification
		let view = view as! NotificationView
		
		view.entity = notification
		
		if let description = notification.summary {
			view.description_?.text = description
		}
		
		let linkColor = Colors.brandColorDark
		let linkActiveColor = Colors.brandColorLight

		view.description_?.linkAttributes = [kCTForegroundColorAttributeName : linkColor]
		view.description_?.activeLinkAttributes = [kCTForegroundColorAttributeName : linkActiveColor]
		view.description_?.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue|NSTextCheckingType.Address.rawValue
		
		let options: SDWebImageOptions = [.RetryFailed, .LowPriority,  .ProgressiveDownload]
		
		if let photo = notification.photoBig {
			let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!, category: SizeCategory.standard, size: nil)
			view.photo?.sd_setImageWithURL(photoUrl, forState: UIControlState.Normal, placeholderImage: nil, options: options)
		}
		
		let photo = notification.getPhotoManaged()
		let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!, category: SizeCategory.profile, size: nil)
		view.userPhoto.sd_setImageWithURL(photoUrl, placeholderImage: nil, options: options)
		
		view.createdDate.text = Utils.messageDateFormatter.stringFromDate(notification.createdDate)

		/* Age indicator */
		view.ageDot.layer.backgroundColor = Colors.accentColor.CGColor
		let now = NSDate()

		/* Age of notification in hours */
		let interval = Int(now.timeIntervalSinceDate(NSDate(timeIntervalSince1970: notification.createdDate.timeIntervalSince1970)) / 3600)
		if interval > 12 {
			view.ageDot.alpha = 0.0
		}
		else if interval > 1 {
			view.ageDot.alpha = 0.25
		}
		else {
			view.ageDot.alpha = 1.0
		}

		/* Type indicator image */
		if notification.type == "media" {
			view.iconImageView.image = Utils.imageMedia
		}
		else if notification.type == "message" {
			view.iconImageView.image = Utils.imageMessage
		}
		else if notification.type == "watch" {
			view.iconImageView.image = Utils.imageWatch
		}
		else if notification.type == "like" {
			if notification.targetId.hasPrefix("pa.") {
				view.iconImageView.image = Utils.imageStar
			}
			else {
				view.iconImageView.image = Utils.imageLike
			}
		}
		else if notification.type == "share" {
			view.iconImageView.image = Utils.imageShare
		}
		else if notification.type == "nearby" {
			view.iconImageView.image = Utils.imageLocation
		}        
		view.iconImageView.tintColor(Colors.brandColor)
				
        return view
    }
}

extension Place {
    
    static func extras(inout parameters: [String:AnyObject]) -> [String:AnyObject] {
        if let links = Place.links() {
            parameters["links"] = links
        }
        if let linked = Place.linked() {
            parameters["linked"] = linked
        }
        if let linkCount = Place.linkCount() {
            parameters["linkCount"] = linkCount
        }
        return parameters
    }
    
    static func links() -> [[String:AnyObject]]? {
        return nil
    }
    
    static func linked() -> [[String:AnyObject]]? {
        return nil
    }
    
    static func linkCount() -> [[String:AnyObject]]? {
        return nil
    }
    
    func addressBlock() -> String {
        var addressBlock = ""
        if address != nil && address.isEmpty {
            addressBlock = address + "\n"
        }
        
        if city != nil && region != nil && !city.isEmpty && !region.isEmpty {
            addressBlock += city + ", " + region;
        }
        else if city != nil && !city.isEmpty {
            addressBlock += city;
        }
        else if region != nil && !region.isEmpty {
            addressBlock += region;
        }
        
        if postalCode != nil && !postalCode.isEmpty {
            addressBlock += " " + postalCode;
        }
        return addressBlock;
    }    
}

extension Shortcut {
    
    static func decorateId(entityId: String) -> String {
        if entityId.rangeOfString("sh.") == nil {
            return "sh." + entityId
        }
        return entityId
    }
}

extension Photo {
    
    func asMap() -> [String:AnyObject] {
        let photo: [String:AnyObject] = [
            "prefix":self.prefix,
            "source":self.source,
            "width":Int(self.widthValue),
            "height":Int(self.heightValue)]
        return photo
    }
}