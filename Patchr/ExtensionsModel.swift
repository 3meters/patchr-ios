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
    
    func distanceFrom(var fromLocation: CLLocation?) -> Float? {
        if fromLocation == nil {
            fromLocation = LocationController.instance.lastLocationFromManager()
        }
        if let location = self.location where fromLocation != nil {
            let entityLocation = location.cllocation
            return Float(fromLocation!.distanceFromLocation(entityLocation))
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
        }
        return photo
    }
    
    static func getDefaultPhoto(schema: String, id: String?) -> Photo {
		/*
		 * Default photos are stored but never directly set to entity.photo.
		 * We store them because the code expects a managed object and managed
		 * objects expect to be associated with a managed object context.
		 */
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
				prefix = "imgDefaultUser"	// Used primarily when user has been deleted
            }
        }
		
		var photo = Photo.fetchOneById(prefix, inManagedObjectContext: DataController.instance.mainContext)
		
		if photo == nil {
			photo = Photo.insertInManagedObjectContext(DataController.instance.mainContext) as! Photo
			photo.id_ = prefix
			photo.prefix = prefix
			photo.source = source
			DataController.instance.saveContext(false)
		}
		
        return photo;
    }
}

extension Patch {
        
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
		
		//parameters["refs"] = ["_owner": ["_id": 1, "name": 1, "photo": 1,"schema": 1,"type": 1]]
        return parameters
    }
    
    static func links() -> [[String:AnyObject]]? {
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if let userId = userDefaults.stringForKey(PatchrUserDefaultKey("userId")) {
            let links = [
				/* Like, watch and message count state for current user */
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
            LinkSpec(from: .Users, type: .Create, fields: "_id,name,photo,schema,type" ),	// User who created the patch
        ]
        
        let array = links.map {
            $0.toDictionary() // Returns an array of maps
        }
        
        return array
    }
    
    static func linkCount() -> [[String:AnyObject]]? {
        
        let links = [
            LinkSpec(from: .Messages, type: .Content),				// Count of messages linked to the patch
            LinkSpec(from: .Users, type: .Watch, enabled: true)     // Count of users that are watching the patch
        ]
        
        let array = links.map {
            $0.toDictionary() // Returns an array of maps
        }
        
        return array
    }
}

extension Message {
	
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
				LinkSpec(from: .Users, type: .Like, fields: "_id,type,schema", filter: ["_from": userId])	// Has the current user liked the message
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
            LinkSpec(from: .Users, type: .Watch, enabled: true),	// Count of users that are watching the patch
            LinkSpec(from: .Messages, type: .Content)				// Count of message to the patch
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
            LinkSpec(to: .Patches, type: .Create), // Count of patches the user created
            LinkSpec(to: .Patches, type: .Watch, enabled: true), // Count of patches the user is watching
        ]
        
        let array = links.map {
            $0.toDictionary() // Returns an array of maps
        }
        
        return array
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