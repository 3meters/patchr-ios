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
    
    func reset() {
        self.photoView?.photo.image = nil
        self.title?.text = nil
        self.subtitle?.text = nil
    }
    
    func bind(group: FireGroup) {
        self.group = group
        self.title?.text = group.title!
        self.subtitle?.text = "\(group.role!)"
        if group.role == "admin" {
            self.subtitle?.textColor = Colors.brandColorTextLight
        }
        else if group.role == "guest" {
            self.subtitle?.textColor = Colors.accentColorTextLight
        }
        else {
            self.subtitle?.textColor = Theme.colorTextSecondary
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
