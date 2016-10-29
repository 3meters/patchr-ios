import Foundation
import IDMPhotoBrowser

class DisplayPhoto: IDMPhoto {
	
    var createdDateLabel	: String?
	var createdDateValue	: Date?
	var creatorName			: String?
	var creatorUrl			: URL?
	var entityId			: String?
	var userLikes			= false
	var userLikesId			: String?
	var size				: CGSize?
    
    static func fromMessage(message: FireMessage) -> DisplayPhoto {
        
        let displayPhoto = DisplayPhoto()
        
        displayPhoto.caption = message.text
        displayPhoto.entityId = message.id
        
        if let photo = message.attachments?.first?.photo {
            displayPhoto.photoURL = PhotoUtils.url(prefix: photo.filename, source: photo.source, category: SizeCategory.standard) as URL!
            if photo.width != nil && photo.height != nil {
                displayPhoto.size = CGSize(width: CGFloat(photo.width!), height: CGFloat(photo.height!))
            }
        }
        
        let createdDate = NSDate(timeIntervalSince1970: Double(message.createdAt!) / 1000)
        displayPhoto.createdDateValue = createdDate as Date
        displayPhoto.createdDateLabel = UIShared.timeAgoShort(date: createdDate)
        
        if let creator = message.creator {
            displayPhoto.creatorName = creator.username
            if let userPhoto = creator.profile?.photo {
                displayPhoto.creatorUrl = PhotoUtils.url(prefix: userPhoto.filename, source: userPhoto.source, category: SizeCategory.profile)! as URL
            }
        }
        
//        displayPhoto.userLikes = entity.userLikesValue
//        displayPhoto.userLikesId = entity.userLikesId
        
        return displayPhoto
    }
	
	static func fromEntity(entity: Entity) -> DisplayPhoto {
		
		guard entity.photo != nil else {
			fatalError("Entity must have a photo")
		}
		
		let displayPhoto = DisplayPhoto()
		
		displayPhoto.caption = entity.description_
		displayPhoto.entityId = entity.id_
		
		if let photo = entity.photo {
			displayPhoto.photoURL = PhotoUtils.url(prefix: photo.prefix, source: photo.source, category: SizeCategory.standard) as URL!
			if photo.width != nil && photo.height != nil {
                displayPhoto.size = CGSize(width: CGFloat(photo.widthValue), height: CGFloat(photo.heightValue))
			}
		}
		
		displayPhoto.createdDateValue = entity.createdDate
		displayPhoto.createdDateLabel = UIShared.timeAgoShort(date: entity.createdDate as NSDate)
		
		if let creator = entity.creator {
			displayPhoto.creatorName = creator.name
			if let userPhoto = creator.photo{
				displayPhoto.creatorUrl = PhotoUtils.url(prefix: userPhoto.prefix, source: userPhoto.source, category: SizeCategory.profile)! as URL
			}
		}
		
		displayPhoto.userLikes = entity.userLikesValue
		displayPhoto.userLikesId = entity.userLikesId
		
		return displayPhoto
	}
}
