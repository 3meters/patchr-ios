//
//  PatchSearchCell.swift
//  Patchr
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
    
    func bind(group: FireGroup) {
        self.group = group
        self.title?.text = group.title!
        self.subtitle?.text = "status: \(group.role!)"
        
        if group.photo != nil {
            let photoUrl = PhotoUtils.url(prefix: group.photo!.filename!, source: group.photo!.source!, category: SizeCategory.profile)
            self.photoView?.bindPhoto(photoUrl: photoUrl, name: nil)
        }
        else {
            self.photoView?.bindPhoto(photoUrl: nil, name: group.title)
        }
    }
}
