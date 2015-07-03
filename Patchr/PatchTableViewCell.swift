//
//  PatchTableViewCell.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class PatchTableViewCell: UITableViewCell {


    @IBOutlet weak var photo: AirImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var type: UILabel!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var visibility: UIImageView!
    @IBOutlet weak var placeName: UILabel!
    @IBOutlet weak var messageCount: UILabel!
    @IBOutlet weak var watchingCount: UILabel!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var photoHeight: NSLayoutConstraint!
    @IBOutlet weak var statusWidth: NSLayoutConstraint!
    
    override var layoutMargins: UIEdgeInsets {
		get { return UIEdgeInsetsZero }
		set (newVal) {}
	}
    
    override func prepareForReuse() {
        name?.text = nil
        type?.text = nil
        placeName?.text = nil
        messageCount?.text = nil
        watchingCount?.text = nil
        distance?.text = nil
    }
}
