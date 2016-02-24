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
}

extension Patch {

    func userIsMember() -> Bool {
        return (self.userWatchStatusValue == .Member)
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
		
		parameters["refs"] = ["_creator":"_id,name,photo,schema,type"]
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
		return nil
    }
    
    static func linkCount() -> [[String:AnyObject]]? {
        
        let links = [
            LinkSpec(from: .Messages, type: .Content),				// Count of messages linked to the patch
            LinkSpec(from: .Users, type: .Watch, enabled: true),     // Count of users that are watching the patch
			LinkSpec(from: .Users, type: .Watch, enabled: false)     // Count of users that are pending
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
		
		parameters["refs"] = ["_creator":"_id,name,photo,schema,type"]
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
        
        /* Used to get count of messages and users watching a shared patch */
        let linkCount = [
            LinkSpec(from: .Users, type: .Watch, enabled: true),	// Count of users that are watching the patch
            LinkSpec(from: .Messages, type: .Content)				// Count of message to the patch
        ]
		
		/* Used to get the creator for the a shared message */
		let refs = ["_creator": "_id,name,photo,schema,type"]
		
        let links = [
            LinkSpec(to: .Patches, type: .Content, fields: "_id,name,photo,schema,type", limit: 1), // Patch the message is linked to
            LinkSpec(to: .Messages, type: .Share, limit: 1, refs: refs),							// Message this message is sharing
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
            LinkSpec(to: .Patches, type: .Create),					// Count of patches the user created
            LinkSpec(to: .Patches, type: .Watch, enabled: true),	// Count of patches the user is watching
        ]
        
        let array = links.map {
            $0.toDictionary() // Returns an array of maps
        }
        
        return array
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

extension NSManagedObjectContext {
	
	convenience init(parentContext parent: NSManagedObjectContext, concurrencyType: NSManagedObjectContextConcurrencyType) {
		self.init(concurrencyType: concurrencyType)
		parentContext = parent
	}
	
	func deleteAllObjects() {		
		if let entitiesByName = self.persistentStoreCoordinator?.managedObjectModel.entitiesByName {
			for (_, entityDescription) in entitiesByName {
				deleteAllObjectsForEntity(entityDescription)
			}
		}
	}
	
	func deleteAllObjectsForEntity(entity: NSEntityDescription) {
		
		let fetchRequest = NSFetchRequest()
		fetchRequest.entity = entity
		fetchRequest.includesPropertyValues = false
		
		do {
			let fetchResults = try executeFetchRequest(fetchRequest)
			if let managedObjects = fetchResults as? [NSManagedObject] {
				for object in managedObjects {
					deleteObject(object)
				}
				try save()
			}
		}
		catch let error as NSError {
			fatalError("Fetch failed: \(error.localizedDescription)")
		}
	}
}