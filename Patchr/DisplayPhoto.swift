import Foundation
import IDMPhotoBrowser
import SDWebImage

class DisplayPhoto: IDMPhoto {

    var message: FireMessage?
    var image: UIImage?

    /* Used to build caption in gallery browsing */
	
    var createdDateLabel: String?
	var createdDateValue: Date?
	var creatorName: String?
	var creatorUrl: URL?
	var userLikes = false
	var userLikesId: String?
    
    var size: CGSize? // Used as hint for grid layout
    
    override func loadUnderlyingImageAndNotify() {
        
        if self.image != nil {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: IDMPhoto_LOADING_DID_END_NOTIFICATION), object: self)
            }
            return
        }
        
        let progress: SDWebImageDownloaderProgressBlock = { loadedSize, expectedSize, url in
            let progress = CGFloat(loadedSize) / CGFloat(expectedSize)
            DispatchQueue.main.async {
                self.progressUpdateBlock?(progress)
            }
        }
        
        let completed: SDInternalCompletionBlock = { [weak self] image, data, error, cacheType, finished, imageUrl in
            if self != nil {
                if error == nil && finished {
                    self!.image = image
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: IDMPhoto_LOADING_DID_END_NOTIFICATION), object: self)
                    }
                }
            }
        }
        
        SDWebImageManager.shared().loadImage(with: self.photoURL
            , options: [.retryFailed, .lowPriority, .avoidAutoSetImage]
            , progress: progress
            , completed: completed)
    }
    
    override func underlyingImage() -> UIImage! {
        return self.image
    }
    
    override func unloadUnderlyingImage() {
        self.image = nil
    }
    
    static func fromMessage(message: FireMessage) -> DisplayPhoto {
        
        let displayPhoto = DisplayPhoto()
        
        displayPhoto.caption = message.text // Used by photo browser
        displayPhoto.message = message
        
        if let photo = message.attachments?.values.first?.photo {
            displayPhoto.photoURL = Cloudinary.url(prefix: photo.filename!)
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
