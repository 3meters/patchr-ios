//
//  PatchTableViewCell.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class ThumbnailCollectionViewCell: UICollectionViewCell {
    
    var imageResult: ImageResult?
    
    @IBOutlet weak var thumbnail: AirImageView!
    
    override var layoutMargins: UIEdgeInsets {
        get { return UIEdgeInsetsZero }
        set (newVal) {}
    }
    
    override func prepareForReuse() {
        thumbnail.image = nil
    }
}
