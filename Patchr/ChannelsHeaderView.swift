//
//  UserDetailView.swift
//  Patchr
//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

@IBDesignable
class ChannelsHeaderView: UIView {

    @IBOutlet weak var title           : UILabel?
    @IBOutlet weak var subtitle        : UILabel?
	@IBOutlet weak var photoView       : PhotoView?
    @IBOutlet weak var switchButton    : UIButton?
    
    func bind(group: FireGroup!) {
        self.title?.text = group.title
		self.subtitle?.text = group.name
        
        if let photo = group.photo, !photo.uploading {
            let photoUrl = PhotoUtils.url(prefix: photo.filename!, source: photo.source!, category: SizeCategory.profile)
            self.photoView?.bind(photoUrl: photoUrl, name: nil, colorSeed: group.id)
        }
        else {
            self.photoView?.bind(photoUrl: nil, name: group.title, colorSeed: group.id)
        }
	}
}
