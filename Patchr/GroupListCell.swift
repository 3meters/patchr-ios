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
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    func initialize() {}
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.badge?.layer.cornerRadius = (self.badge?.frame.size.width)! / 2
    }
    
    func reset() {
        self.badge?.backgroundColor = Theme.colorBackgroundBadge
        self.photoView?.photo.image = nil
        self.title?.text = nil
        self.subtitle?.text = nil
        self.badge?.text = nil
        self.badge?.isHidden = true
        self.group = nil
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        let color = self.photoView?.backgroundColor
        super.setSelected(selected, animated: animated)
        self.photoView?.backgroundColor = color
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let color = self.photoView?.backgroundColor
        super.setHighlighted(highlighted, animated: animated)
        self.photoView?.backgroundColor = color
    }
    
    func bind(group: FireGroup) {
        self.group = group
        
        self.title?.text = group.title!
        self.subtitle?.text = "\(group.role!)"
        
        if let photo = group.photo, !photo.uploading {
            let photoUrl = PhotoUtils.url(prefix: photo.filename!, source: photo.source!, category: SizeCategory.profile)
            self.photoView?.bind(photoUrl: photoUrl, name: nil, colorSeed: group.id)
        }
        else {
            self.photoView?.bind(photoUrl: nil, name: group.title, colorSeed: group.id)
        }
    }
}
