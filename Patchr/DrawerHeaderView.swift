import UIKit

@IBDesignable
class DrawerHeaderView: UIView {

    @IBOutlet weak var title: UILabel!
	@IBOutlet weak var photoControl: PhotoControl!
    @IBOutlet weak var switchButton: UIButton!
    @IBOutlet weak var badge: UILabel!
    @IBOutlet weak var unreadGroup: UIView!
    @IBOutlet weak var backImage: UIImageView!
    @IBOutlet weak var unreadButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        initialize()
    }
    
    func initialize() {
        self.badge?.backgroundColor = Theme.colorBackgroundBadge
        self.badge?.text = nil
        self.backImage.tintColor = Colors.brandColorLight
        self.unreadGroup.alpha = 0.0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.badge?.layer.cornerRadius = (self.badge?.frame.size.height)! / 2
    }
    
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
    
    func unread(count: Int?) {
        if count == nil || count! == 0 {
            self.unreadGroup.alpha = 0.0
            self.photoControl.alpha = 1.0
        }
        else {
            self.badge.text = "\(count!)"
            self.unreadGroup.alpha = 1.0
            self.photoControl.alpha = 0.0
        }
    }
}
