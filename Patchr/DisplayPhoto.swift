import Foundation
import IDMPhotoBrowser

class DisplayPhoto: IDMPhoto {
	
    var createdDate	: String?
	var creatorName	: String?
	var creatorUrl	: NSURL?
	var entityId	: String?
	var userLikes	= false
	var userLikesId : String?
	
	static func fromMap(map: [String: AnyObject]) -> DisplayPhoto {
		
		let displayPhoto = DisplayPhoto()
		
		displayPhoto.caption = map["description"] as? String
		displayPhoto.entityId = map["_id"] as? String
		
		if let photoMap = map["photo"] as? [String: AnyObject] {
			displayPhoto.photoURL = PhotoUtils.url(photoMap["prefix"] as! String, source: photoMap["source"] as! String, category: SizeCategory.standard)
		}
		
		if let createdDate = map["createdDate"] as? Int {
			displayPhoto.createdDate = UIShared.timeAgoShort(NSDate(timeIntervalSince1970: NSTimeInterval(createdDate / 1000)))
		}		
		
		if let creatorMap = map["creator"] as? [String: AnyObject] {
			displayPhoto.creatorName = creatorMap["name"] as? String
			if let userPhotoMap = creatorMap["photo"] as? [String: AnyObject] {
				displayPhoto.creatorUrl = PhotoUtils.url(userPhotoMap["prefix"] as! String, source: userPhotoMap["source"] as! String, category: SizeCategory.thumbnail)
			}
		}
		
		if let linksArray = map["links"] as? [[String: AnyObject]] where linksArray.count > 0 {
			var linkMap = linksArray[0]
			if let type = linkMap["type"] as? String where type == "like" {
				displayPhoto.userLikes = true
				displayPhoto.userLikesId = linkMap["_id"] as? String
			}
		}
		
		return displayPhoto
	}
}