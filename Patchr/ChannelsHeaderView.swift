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
    
	func bind(patch: FireGroup!) {
        self.title?.text = patch.title
		self.subtitle?.text = patch.name
        
        if patch.photo != nil {
            let photoUrl = PhotoUtils.url(prefix: patch.photo!.filename!, source: patch.photo!.source!, category: SizeCategory.profile)
            self.photoView?.bindPhoto(photoUrl: photoUrl, name: nil)
        }
        else {
            self.photoView?.bindPhoto(photoUrl: nil, name: patch.title)
        }
	}
}
