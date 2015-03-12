//
//  PatchTableViewCell.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class PatchTableViewCell: UITableViewCell {


    @IBOutlet weak var imageViewThumb: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var visibilityImageView: UIImageView!
    
    override var layoutMargins: UIEdgeInsets { get { return UIEdgeInsetsZero } set(newVal) {} }
}
