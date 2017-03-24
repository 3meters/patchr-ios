import UIKit

@IBDesignable
class ChannelsHeaderView: UIView {

    @IBOutlet weak var title: UILabel?
	@IBOutlet weak var photoControl: PhotoControl?
    @IBOutlet weak var switchButton: UIButton?
    @IBOutlet weak var searchBar: UISearchBar?
    
    func bind(group: FireGroup!) {
        
        self.title?.text = group.title
        
        if let photo = group.photo {
            let photoUrl = Cloudinary.url(prefix: photo.filename!, category: SizeCategory.profile)
            self.photoControl?.bind(url: photoUrl, name: nil, colorSeed: group.id)
        }
        else {
            self.photoControl?.bind(url: nil, name: group.title, colorSeed: group.id)
        }
	}
}
