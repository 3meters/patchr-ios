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
    var fallbackUrl         : URL?
    
    static func fromMessage(message: FireMessage) -> DisplayPhoto {
        
        let displayPhoto = DisplayPhoto()
        
        displayPhoto.caption = message.text
        displayPhoto.entityId = message.id
        
        if let photo = message.attachments?.values.first?.photo {
            displayPhoto.photoURL = PhotoUtils.url(prefix: photo.filename, source: photo.source, category: SizeCategory.standard) as URL!
            displayPhoto.fallbackUrl = PhotoUtils.fallbackUrl(prefix: photo.filename!)
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
        
        let userId = UserController.instance.userId
        if message.getReaction(emoji: .thumbsup, userId: userId!) {
            displayPhoto.userLikes = true
            displayPhoto.userLikesId = userId
        }
        
        return displayPhoto
    }
}
