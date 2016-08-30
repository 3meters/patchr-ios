import Foundation
import IDMPhotoBrowser

class DisplayPhoto: IDMPhoto {
	
    var createdDateLabel	: String?
	var createdDateValue	: NSDate?
	var creatorName			: String?
	var creatorUrl			: NSURL?
	var entityId			: String?
	var userLikes			= false
	var userLikesId			: String?
	var size				: CGSize?
	
	static func fromEntity(entity: Entity) -> DisplayPhoto {
		
		guard entity.photo != nil else {
			fatalError("Entity must have a photo")
		}
		
		let displayPhoto = DisplayPhoto()
		
		displayPhoto.caption = entity.description_
		displayPhoto.entityId = entity.id_
		
		if let photo = entity.photo {
			displayPhoto.photoURL = PhotoUtils.url(photo.prefix, source: photo.source, category: SizeCategory.standard)
			if photo.width != nil && photo.height != nil {
				displayPhoto.size = CGSizeMake(CGFloat(photo.widthValue), CGFloat(photo.heightValue))
			}
		}
		
		displayPhoto.createdDateValue = entity.createdDate
		displayPhoto.createdDateLabel = UIShared.timeAgoShort(entity.createdDate)
		
		if let creator = entity.creator {
			displayPhoto.creatorName = creator.name
			if let userPhoto = creator.photo{
				displayPhoto.creatorUrl = PhotoUtils.url(userPhoto.prefix, source: userPhoto.source, category: SizeCategory.profile)
			}
		}
		
		displayPhoto.userLikes = entity.userLikesValue
		displayPhoto.userLikesId = entity.userLikesId
		
		return displayPhoto
	}
	
	static func fromMap(map: [String: AnyObject]) -> DisplayPhoto {
		
		let displayPhoto = DisplayPhoto()
		
		displayPhoto.caption = map["description"] as? String
		displayPhoto.entityId = map["_id"] as? String
		
		if let photoMap = map["photo"] as? [String: AnyObject] {
			displayPhoto.photoURL = PhotoUtils.url(photoMap["prefix"] as! String, source: photoMap["source"] as! String, category: SizeCategory.standard)
		}
		
		if let createdDate = map["createdDate"] as? Int {
			displayPhoto.createdDateValue = NSDate(timeIntervalSince1970: NSTimeInterval(createdDate / 1000))
			displayPhoto.createdDateLabel = UIShared.timeAgoShort(displayPhoto.createdDateValue!)
		}		
		
		if let creatorMap = map["creator"] as? [String: AnyObject] {
			displayPhoto.creatorName = creatorMap["name"] as? String
			if let userPhotoMap = creatorMap["photo"] as? [String: AnyObject] {
				displayPhoto.creatorUrl = PhotoUtils.url(userPhotoMap["prefix"] as! String, source: userPhotoMap["source"] as! String, category: SizeCategory.profile)
			}
		}
		
		if let linksArray = map["links"] as? [[String: AnyObject]] where linksArray.count > 0 {
			var linkMap = linksArray[0]
			if let type = linkMap["type"] as? String where type == "like" {
			}
		}
		
		return displayPhoto
	}
}