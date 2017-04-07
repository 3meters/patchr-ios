import Foundation
import IDMPhotoBrowser
import SDWebImage
import FLAnimatedImage

class DisplayPhoto: IDMPhoto {

    weak var message: FireMessage? // Supports like button

    /* Used to build caption in gallery browsing */
	
    var createdDateLabel: String?
	var createdDateValue: Date?
	var creatorName: String?
	var creatorUrl: URL?
	var userLikes = false
	var userLikesId: String?
    
    var size: CGSize? // Used as hint for grid layout
    
    convenience init(from message: FireMessage) {
        self.init()
        self.caption = message.text // Used by photo browser, on base class
        self.message = message
        
        if let photo = message.attachments?.values.first?.photo {
            self.photoURL = Cloudinary.url(prefix: photo.filename!) // On base class
            if photo.width != nil && photo.height != nil {
                self.size = CGSize(width: CGFloat(photo.width!), height: CGFloat(photo.height!))
            }
        }
        
        let createdDate = DateUtils.from(timestamp: message.createdAt!)
        self.createdDateValue = createdDate
        self.createdDateLabel = DateUtils.timeAgoShort(date: createdDate)
        
        if let creator = message.creator {
            self.creatorName = creator.username
            if let userPhoto = creator.profile?.photo {
                self.creatorUrl = Cloudinary.url(prefix: userPhoto.filename!, category: SizeCategory.profile)
            }
        }
        
        let userId = UserController.instance.userId!
        if message.getReaction(emoji: .thumbsup, userId: userId) {
            self.userLikes = true
            self.userLikesId = userId
        }
    }
}
