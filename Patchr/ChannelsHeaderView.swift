import UIKit

@IBDesignable
class ChannelsHeaderView: UIView {

    @IBOutlet weak var title: UILabel?
	@IBOutlet weak var photoView: PhotoView?
    @IBOutlet weak var switchButton: UIButton?
    @IBOutlet weak var searchBar: UISearchBar?
    
    func bind(group: FireGroup!) {
        
        self.title?.text = group.title
        
        if let photo = group.photo, photo.uploading == nil {
            let photoUrl = PhotoUtils.url(prefix: photo.filename!, source: photo.source!, category: SizeCategory.profile)
            self.photoView?.bind(url: photoUrl, fallbackUrl: PhotoUtils.fallbackUrl(prefix: photo.filename!), name: nil, colorSeed: group.id)
        }
        else {
            self.photoView?.bind(url: nil, fallbackUrl: nil, name: group.title, colorSeed: group.id)
        }
	}
}
