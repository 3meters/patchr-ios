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
        if let currentLocation = LocationController.instance.getLocation(), location = self.location {
            let entityLocation = CLLocation(latitude: location.latValue, longitude: location.lngValue)
            return Float(currentLocation.distanceFromLocation(entityLocation))
        }
        return nil
    }
    
    func getPhotoManaged() -> Photo {
        var photo = self.photo
        if photo == nil {
            photo = Entity.getDefaultPhoto(self.schema)
            photo.usingDefaultValue = true
        }
        return photo
    }
    
    static func getDefaultPhoto(schema: String) -> Photo {
        
        var prefix: String = "imgDefaultPatch"
        if schema == "place" {
            prefix = "imgDefaultPlace";
        }
        else if schema == "user" || schema == "notification" {
            prefix = "imgDefaultUser"
        }
        
        var photo = Photo.insertInManagedObjectContext(DataController.instance.managedObjectContext) as! Photo
        photo.prefix = prefix
        photo.source = PhotoSource.resource
        
        return photo;
    }
}

extension Patch {
    
    static func extras(inout parameters: [String:AnyObject]) -> [String:AnyObject] {
        if var links = Patch.links() {
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
            var links = [
                LinkSpec(from: .Users, type: .Like, fields: "_id,type,schema", filter: ["_from": userId]),
                LinkSpec(from: .Users, type: .Watch, fields: "_id,type,enabled,schema", filter: ["_from": userId]),
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
        
        var links = [
            LinkSpec(to: .Places, type: .Proximity, fields: "_id,name,photo,schema,type" ), // Place the patch is linked to
            LinkSpec(from: .Users, type: .Create, fields: "_id,name,photo,schema,type" ), // User who created the patch
        ]
        
        let array = links.map {
            $0.toDictionary() // Returns an array of maps
        }
        
        return array
    }
    
    static func linkCount() -> [[String:AnyObject]]? {
        
        var links = [
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
    
    static func extras(inout parameters: [String:AnyObject]) -> [String:AnyObject] {
        if var links = Message.links() {
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
            var links = [
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
        
        var links = [
            LinkSpec(to: .Patches, type: .Content, fields: "_id,name,photo,schema,type", limit: 1), // Patch the message is linked to
            LinkSpec(from: .Users, type: .Create, fields: "_id,name,photo,schema,type" ), // User who created the message
            LinkSpec(to: .Messages, type: .Share, limit: 1), // Message this message is sharing
            LinkSpec(to: .Patches, type: .Share, limit: 1), // Patch this message is sharing
            LinkSpec(to: .Users, type: .Share, limit: 5)   // Users this message is shared with
        ]
        
        let array = links.map {
            $0.toDictionary() // Returns an array of maps
        }
        
        return array
    }
    
    static func linkCount() -> [[String:AnyObject]]? {
        
        var links = [
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
        if var links = User.links() {
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
        
        var links = [
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

extension Place {
    
    static func extras(inout parameters: [String:AnyObject]) -> [String:AnyObject] {
        if var links = Place.links() {
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
        if !address.isEmpty {
            addressBlock = address + "\n"
        }
        
        if !city.isEmpty && !region.isEmpty {
            addressBlock += city + ", " + region;
        }
        else if !city.isEmpty {
            addressBlock += city;
        }
        else if !region.isEmpty {
            addressBlock += region;
        }
        
        if !postalCode.isEmpty {
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