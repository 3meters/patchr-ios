import Foundation
import IDMPhotoBrowser

class DisplayPhoto: IDMPhoto {
	
    var createdDateLabel: String?
	var createdDateValue: Date?
	var creatorName: String?
	var creatorUrl: URL?
    var entityId: String?
	var userLikes = false
	var userLikesId: String?
	var size: CGSize?
    var fallbackUrl: URL?
    var uploading: String?
    
    static func fromMessage(message: FireMessage) -> DisplayPhoto {
        
        let displayPhoto = DisplayPhoto()
        
        displayPhoto.caption = message.text
        displayPhoto.entityId = message.id
        
        if let photo = message.attachments?.values.first?.photo {
            displayPhoto.uploading = photo.uploading
            if photo.uploading != nil {
                displayPhoto.photoURL = URL(string: photo.cacheKey)
            }
            else {
                displayPhoto.photoURL = ImageUtils.url(prefix: photo.filename, source: photo.source, category: SizeCategory.standard) as URL!
                displayPhoto.fallbackUrl = ImageUtils.fallbackUrl(prefix: photo.filename!)
            }
            if photo.width != nil && photo.height != nil {
                displayPhoto.size = CGSize(width: CGFloat(photo.width!), height: CGFloat(photo.height!))
            }
        }
        let createdDate = DateUtils.from(timestamp: message.createdAt!)
        displayPhoto.createdDateValue = createdDate
        displayPhoto.createdDateLabel = DateUtils.timeAgoShort(date: createdDate)
        
        if let creator = message.creator {
            displayPhoto.creatorName = creator.username
            if let userPhoto = creator.profile?.photo {
                displayPhoto.creatorUrl = ImageUtils.url(prefix: userPhoto.filename, source: userPhoto.source, category: SizeCategory.profile)! as URL
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
