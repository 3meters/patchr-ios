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
        
        var photo = Photo.insertInManagedObjectContext(DataController.instance.managedObjectContext) as! Photo
        photo.prefix = prefix
        photo.source = source
        
        return photo;
    }
}

extension Patch {
    
    static func bindView(view: UIView, object: AnyObject, tableView: UITableView?, sizingOnly: Bool = false) -> UIView {
        
        let patch = object as! Entity
        let view = view as! PatchView
        
        view.name.text = patch.name
        if patch.type != nil {
            view.type.text = patch.type.uppercaseString + " PATCH"
        }
        
        if view.placeName != nil {
            view.placeName.hidden = true
            view.placeName.text = nil
            if let patchTemp = object as? Patch {
                if patchTemp.place != nil {
                    view.placeName.text = patchTemp.place.name.uppercaseString
                    view.placeName.hidden = false
                }
            }
        }
        
        if view.visibility != nil {
            view.visibility?.tintColor(Colors.brandColor)
            view.visibility.hidden = (patch.visibility == "public")
        }
        
        if (view.status != nil) {
            view.status.hidden = true
            view.statusWidth.constant = CGFloat(0)
            if (patch.userWatchStatusValue == .Pending && !SCREEN_NARROW) {
                view.status.hidden = false
                view.statusWidth.constant = CGFloat(70)
            }
            else {
                
            }
        }
        
        view.messageCount.text = "--"
        view.watchingCount.text = "--"
        
        if let numberOfMessages = patch.numberOfMessages {
            if view.messageCount != nil {
                view.messageCount.text = numberOfMessages.stringValue
            }
        }
        
        if let numberOfWatching = patch.countWatching {
            if view.watchingCount != nil {
                view.watchingCount.text = numberOfWatching.stringValue
            }
        }
        
        /* Distance */
        if view.distance != nil {
            view.distance.text = "--"
            if let lastLocation = LocationController.instance.lastLocationFromManager() {
                if let loc = patch.location {
                    var patchLocation = CLLocation(latitude: loc.latValue, longitude: loc.lngValue)
                    let dist = Float(lastLocation.distanceFromLocation(patchLocation))  // in meters
                    view.distance.text = LocationController.instance.distancePretty(dist)
                }
            }
        }
        
        if !sizingOnly {
            view.photo.setImageWithPhoto(patch.getPhotoManaged(), animate: view.photo.image == nil)
        }
        
        return view
    }
    
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
    
    static func bindView(view: UIView, object: AnyObject, tableView: UITableView?, sizingOnly: Bool = false) -> UIView {
        
        let message = object as! Entity
        let view = view as! MessageView
        
        view.entity = message
        
        view.description_.text = nil
        view.userName.text = nil
        view.patchName.text = nil
        view.patchNameHeight.constant = 0
        
        let linkColor = Colors.brandColorDark
        let linkActiveColor = Colors.brandColorLight
        
        if let label = view.description_ as? TTTAttributedLabel {
            label.linkAttributes = [kCTForegroundColorAttributeName : linkColor]
            label.activeLinkAttributes = [kCTForegroundColorAttributeName : linkActiveColor]
            label.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue|NSTextCheckingType.Address.rawValue
        }
        
        view.description_.text = message.description_
        
        view.photo.image = nil
        view.photo.hidden = true
        view.photoTopSpace.constant = 0
        view.photoHeight.constant = 0
        
        if let photo = message.photo {
            if !sizingOnly {
                view.photo.setImageWithPhoto(photo, animate: view.photo.image == nil)
            }
            view.photo.hidden = false
            view.photoTopSpace.constant = 8
            view.photoHeight.constant = view.photo.bounds.size.width * 0.5625
        }
        
        if let creator = message.creator {
            view.userName.text = creator.name
            if !sizingOnly {
                view.userPhoto.setImageWithPhoto(creator.getPhotoManaged(), animate: view.userPhoto.image == nil)
            }
            else {
                view.userPhoto.image = nil
            }
        }
        else {
            view.userName.text = "Deleted"
            if !sizingOnly {
                view.userPhoto.setImageWithPhoto(Entity.getDefaultPhoto("user", id: nil))
            }
        }
        
        /* Likes button */
        view.likeButton.bindEntity(message)
        view.likeButton.imageView!.tintColor(Colors.brandColor)
        
        view.likes.hidden = true
        if message.countLikes != nil {
            if message.countLikes?.integerValue != 0 {
                let likesTitle = message.countLikes?.integerValue == 1
                    ? "\(message.countLikes) like"
                    : "\(message.countLikes ?? 0) likes"
                view.likes.text = likesTitle
                view.likes.hidden = false
            }
        }
        
        view.createdDate.text = Utils.messageDateFormatter.stringFromDate(message.createdDate)
        
        view.setNeedsUpdateConstraints()
        view.updateConstraintsIfNeeded()
        
        return view
    }
    
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
        
        /* Used to get the creator for the a shared message */
        var linked = [
            LinkSpec(from: .Users, type: .Create, fields: "_id,name,photo,schema,type" )
        ]
        
        /* Used to get count of messages and users watching a shared patch */
        var linkCount = [
            LinkSpec(from: .Users, type: .Watch, enabled: true),        // Count of users that are watching the patch
            LinkSpec(from: .Messages, type: .Content)    // Count of message to the patch
        ]
        
        var links = [
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
    
    static func bindView(view: UIView, object: AnyObject, tableView: UITableView?, sizingOnly: Bool = false) {
        
        let user = object as! User
        let view = view as! UserView
        
        view.userName.text = user.name
        if !sizingOnly {
            view.userPhoto.setImageWithPhoto(user.getPhotoManaged(), animate: view.userPhoto.image == nil)
        }
        view.area.text = user.area?.uppercaseString
        
        view.userName.hidden = view.userName.text == nil
        view.area.hidden = view.area.text == nil
        view.owner.hidden = view.owner.text == nil
        
        // Private patch owner controls controls
        if let view = view as? UserApprovalView {
            
            view.entity = object as? Entity
            view.removeButton?.hidden = true
            view.approved?.hidden = true
            view.approvedSwitch?.hidden = true
            
            if let currentUser = UserController.instance.currentUser {
                if user.id_ != currentUser.id_ {
                    view.removeButton?.hidden = false
                    view.approved?.hidden = false
                    view.approvedSwitch?.hidden = false
                    view.approvedSwitch?.on = false
                    if (user.link != nil && user.link.type == "watch") {
                        view.approvedSwitch?.on = user.link.enabledValue
                    }
                }
            }
        }
    }
    
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

extension Notification {
    
    static func bindView(view: UIView, object: AnyObject, tableView: UITableView?, sizingOnly: Bool = false) -> UIView {
        
        let notification = object as! Notification
        let view = view as! NotificationView
        
        view.description_.text = nil
        
        let linkColor = Colors.brandColorDark
        let linkActiveColor = Colors.brandColorLight
        
        if let label = view.description_ as? TTTAttributedLabel {
            label.linkAttributes = [kCTForegroundColorAttributeName : linkColor]
            label.activeLinkAttributes = [kCTForegroundColorAttributeName : linkActiveColor]
            label.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
        }
        
        view.description_.text = notification.summary
        
        if let photo = notification.photoBig {
            if !sizingOnly {
                view.photo.setImageWithPhoto(photo, animate: view.photo.image == nil)
            }
            view.photoTopSpace.constant = 8
            view.photoHeight.constant = view.photo.bounds.size.width * 0.5625
        }
        else {
            view.photoTopSpace.constant = 0
            view.photoHeight.constant = 0
        }
        
        if !sizingOnly {
            view.userPhoto.setImageWithPhoto(notification.getPhotoManaged(), animate: view.userPhoto.image == nil)
        }
        
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
        
        if notification.type == "media" {
            view.iconImageView.image = UIImage(named: "imgMediaLight")
        }
        else if notification.type == "message" {
            view.iconImageView.image = UIImage(named: "imgMessageLight")
        }
        else if notification.type == "watch" {
            view.iconImageView.image = UIImage(named: "imgWatchLight")
        }
        else if notification.type == "like" {
            if notification.targetId.hasPrefix("pa.") {
                view.iconImageView.image = UIImage(named: "imgStarFilledLight")
            }
            else {
                view.iconImageView.image = UIImage(named: "imgLikeLight")
            }
        }
        else if notification.type == "share" {
            view.iconImageView.image = UIImage(named: "imgShareLight")
        }
        else if notification.type == "nearby" {
            view.iconImageView.image = UIImage(named: "imgLocationLight")
        }
        
        view.iconImageView.tintColor(Colors.brandColor)
        
        view.setNeedsUpdateConstraints()
        view.updateConstraintsIfNeeded()
        
        return view
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