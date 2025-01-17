import Foundation
import IDMPhotoBrowser
import SDWebImage

class DisplayPhoto: IDMPhoto {

    var message: FireMessage? // Supports reaction button

    /* Used to build caption in gallery browsing */
	
    var createdDateLabel: String?
	var createdDateValue: Date?
	var creatorName: String?
	var creatorUrl: URL?
	var userLikes = false

    var size: CGSize? // Used as hint for grid layout
    
    convenience init(from message: FireMessage) {
        self.init()
        self.caption = message.text // Used by photo browser, on base class
        self.message = message
        
        if let photo = message.attachments?.values.first?.photo {
            self.photoURL = ImageProxy.url(photo: photo, category: SizeCategory.standard) // On base class
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
                self.creatorUrl = ImageProxy.url(photo: userPhoto, category: SizeCategory.profile)
            }
        }
        
        let userId = UserController.instance.userId!
        if message.getReaction(emoji: ":thumbsup:", userId: userId) {
            self.userLikes = true
        }
    }
}
