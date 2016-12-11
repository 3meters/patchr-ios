//
//  Created by Jay Massena on 7/15/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class GroupListCell: UITableViewCell {
    
    @IBOutlet weak var photoView: PhotoView?
    @IBOutlet weak var title: UILabel?
    @IBOutlet weak var subtitle: UILabel?
    @IBOutlet weak var badge: UILabel?
    
    var group: FireGroup!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.badge?.layer.cornerRadius = (self.badge?.frame.size.width)! / 2
    }
    
    func reset() {
        self.photoView?.photoView.image = nil
        self.title?.text = nil
        self.subtitle?.text = nil
        self.badge?.backgroundColor = Theme.colorBackgroundBadge
        self.badge?.text = nil
        self.badge?.isHidden = true
        self.group = nil
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        let colorPhoto = self.photoView?.backgroundColor
        super.setSelected(selected, animated: animated)
        self.photoView?.backgroundColor = colorPhoto
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let colorPhoto = self.photoView?.backgroundColor
        super.setHighlighted(highlighted, animated: animated)
        self.photoView?.backgroundColor = colorPhoto
    }
    
    func bind(group: FireGroup) {
        self.group = group
        
        self.title?.text = group.title!
        self.subtitle?.text = "\(group.role!)"
        
        if let photo = group.photo, photo.uploading == nil {
            let photoUrl = PhotoUtils.url(prefix: photo.filename!, source: photo.source!, category: SizeCategory.profile)
            self.photoView?.bind(url: photoUrl, fallbackUrl: PhotoUtils.fallbackUrl(prefix: photo.filename!), name: nil, colorSeed: group.id)
        }
        else {
            self.photoView?.bind(url: nil, fallbackUrl: nil, name: group.title, colorSeed: group.id)
        }
    }
}
