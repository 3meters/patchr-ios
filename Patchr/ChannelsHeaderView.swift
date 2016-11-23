import UIKit

@IBDesignable
class ChannelsHeaderView: UIView {

    @IBOutlet weak var title           : UILabel?
    @IBOutlet weak var subtitle        : UILabel?
	@IBOutlet weak var photoView       : PhotoView?
    @IBOutlet weak var switchButton    : UIButton?
    
    func bind(group: FireGroup!) {
        
        self.title?.text = group.title
        
        if let username = group.username {
            self.subtitle?.text = username
        }
        
        if let photo = group.photo, !photo.uploading {
            let photoUrl = PhotoUtils.url(prefix: photo.filename!, source: photo.source!, category: SizeCategory.profile)
            self.photoView?.bind(photoUrl: photoUrl, name: nil, colorSeed: group.id)
        }
        else {
            self.photoView?.bind(photoUrl: nil, name: group.title, colorSeed: group.id)
        }
	}
}
