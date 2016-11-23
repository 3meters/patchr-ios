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
    
    var group: FireGroup!
    
    func reset() {
        self.photoView?.photo.image = nil
        self.title?.text = nil
        self.subtitle?.text = nil
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
