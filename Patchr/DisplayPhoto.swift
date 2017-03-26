import Foundation
import IDMPhotoBrowser
import SDWebImage
import FLAnimatedImage

class DisplayPhoto: IDMPhoto {

    var message: FireMessage? // Supports like button

    /* Used to build caption in gallery browsing */
	
    var createdDateLabel: String?
	var createdDateValue: Date?
	var creatorName: String?
	var creatorUrl: URL?
	var userLikes = false
	var userLikesId: String?
    
    var size: CGSize? // Used as hint for grid layout
    
    static func fromMessage(message: FireMessage) -> DisplayPhoto {
        
        let displayPhoto = DisplayPhoto()
        
        displayPhoto.caption = message.text // Used by photo browser, on base class
        displayPhoto.message = message
        
        if let photo = message.attachments?.values.first?.photo {
            displayPhoto.photoURL = Cloudinary.url(prefix: photo.filename!) // On base class
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
                displayPhoto.creatorUrl = Cloudinary.url(prefix: userPhoto.filename!, category: SizeCategory.profile)
            }
        }
        
        let userId = UserController.instance.userId!
        if message.getReaction(emoji: .thumbsup, userId: userId) {
            displayPhoto.userLikes = true
            displayPhoto.userLikesId = userId
        }
        
        return displayPhoto
    }
}
