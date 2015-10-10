//
//  PatchTableViewCell.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class PatchView: BaseView {

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var photo: AirImageView!
    @IBOutlet weak var photoHeight: NSLayoutConstraint!
    @IBOutlet weak var type: UILabel!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var visibility: UIImageView!
    @IBOutlet weak var placeName: UILabel!
    @IBOutlet weak var messageCount: UILabel!
    @IBOutlet weak var watchingCount: UILabel!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var statusWidth: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override var layoutMargins: UIEdgeInsets {
		get { return UIEdgeInsetsZero }
		set (newVal) {}
	}
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.photo.gradient?.frame = CGRectMake(0, 0, self.photo.bounds.size.width + 10, self.photo.bounds.size.height + 10)
        self.photo.gradient?.hidden = false
    }
}
