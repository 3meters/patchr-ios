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
class PatchListCell: UITableViewCell {
    
    @IBOutlet weak var photoView: PhotoView?
    @IBOutlet weak var title: UILabel?
    @IBOutlet weak var subtitle: UILabel?
    
    var patch: FireGroup!
    
    func bind(patch: FireGroup) {
        self.patch = patch
        self.title?.text = patch.title!
        self.subtitle?.text = "status: \(patch.role!)"
        
        if patch.photo != nil {
            let photoUrl = PhotoUtils.url(prefix: patch.photo!.filename!, source: patch.photo!.source!, category: SizeCategory.profile)
            self.photoView?.bindPhoto(photoUrl: photoUrl, name: nil)
        }
        else {
            self.photoView?.bindPhoto(photoUrl: nil, name: patch.title)
        }
    }
}
