import Foundation
import IDMPhotoBrowser
import SDWebImage

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
    var uploading: Bool?
    var message: FireMessage?
    var cacheUrl: URL?
    var image: UIImage?
    
    override func underlyingImage() -> UIImage! {
        return self.image
    }
    
    override func loadUnderlyingImageAndNotify() {
        if self.uploading != nil, let cacheUrl = self.cacheUrl {
            ImageUtils.imageFromCache(url: cacheUrl) { image in
                self.image = image
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: IDMPhoto_LOADING_DID_END_NOTIFICATION), object: self)
                }
            }
        }
        else {
            let options: SDWebImageOptions = [.retryFailed, .lowPriority, .avoidAutoSetImage, .delayPlaceholder /* .ProgressiveDownload */]
            SDWebImageManager.shared().downloadImage(with: self.photoURL, options: options, progress: nil) {
                image, error, cacheType, finished, imageUrl in
                if error != nil && self.fallbackUrl != nil {
                    SDWebImageManager.shared().downloadImage(with: self.fallbackUrl!, options: options, progress: nil) {
                        image, error, cacheType, finished, imageUrl in
                        if error == nil && finished {
                            self.image = image
                        }
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: IDMPhoto_LOADING_DID_END_NOTIFICATION), object: self)
                        }
                    }
                }
                else if finished {
                    self.image = image
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: IDMPhoto_LOADING_DID_END_NOTIFICATION), object: self)
                    }
                }
            }
        }
    }
    
    override func unloadUnderlyingImage() {
        if self.cacheUrl != nil || self.photoURL != nil {
            self.image = nil
        }
    }
    
    static func fromMessage(message: FireMessage) -> DisplayPhoto {
        
        let displayPhoto = DisplayPhoto()
        
        displayPhoto.caption = message.text // Used by photo browser
        displayPhoto.entityId = message.id
        displayPhoto.message = message
        
        if let photo = message.attachments?.values.first?.photo {
            displayPhoto.uploading = photo.uploading
            displayPhoto.cacheUrl = URL(string: photo.cacheKey)
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
