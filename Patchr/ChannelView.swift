//
//  PatchCell.swift
//  Patchr
//
//  Created by Jay Massena on 10/17/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import SDWebImage
import FontAwesome_swift

class ChannelView: BaseView {

    var visibility		= UILabel()
	var name			= UILabel()
	var photo			= AirImageView(frame: CGRectZero)
	
	override init(frame: CGRect) {
		/* Called when instantiated from code */
		super.init(frame: frame)
		initialize()
	}

	required init?(coder aDecoder: NSCoder) {
		/* Called when instantiated from storyboard or nib */
		super.init(coder: aDecoder)
		initialize()
	}
	
	func initialize() {
		
		self.clipsToBounds = true
		
		self.layer.backgroundColor = Theme.colorBackgroundTile.CGColor
		
		/* Patch photo */
		self.photo.contentMode = UIViewContentMode.ScaleAspectFill
		self.photo.clipsToBounds = true
		self.photo.userInteractionEnabled = true
		self.photo.backgroundColor = Colors.gray80pcntColor
		self.photo.sizeCategory = SizeCategory.thumbnail
		self.addSubview(self.photo)
		
		/* Patch name */
		self.name.font = Theme.fontText
		self.name.numberOfLines = 1
		self.addSubview(self.name)
		
		/* Patch visibility */
        self.visibility.font = UIFont.fontAwesomeOfSize(16)
		self.addSubview(self.visibility)
	}
	
	override func bindToEntity(entity: AnyObject, location: CLLocation?) {
		
		let entity = entity as! Entity
		
		self.entity = entity
		
		self.name.text = entity.name.lowercaseString.stringByReplacingOccurrencesOfString(" ", withString: "-")
		
		if let patch = entity as? Patch {
            self.visibility.text = (patch.visibility != nil && patch.visibility == "public") ? String.fontAwesomeIconWithName(.Hashtag) : String.fontAwesomeIconWithName(.Lock)
		}
				
		self.photo.backgroundColor = Colors.gray80pcntColor

		if entity.photo != nil {
			let photoUrl = PhotoUtils.url(entity.photo!.prefix!, source: entity.photo!.source!, category: SizeCategory.profile)
			bindPhoto(photoUrl, name: entity.name)
		}
		else {
			bindPhoto(nil, name: entity.name)
		}

		self.setNeedsLayout()
	}
	
	private func bindPhoto(photoUrl: NSURL?, name: String?) {
		
		if self.photo.image != nil
			&& self.photo.linkedPhotoUrl != nil
			&& photoUrl != nil
			&& self.photo.linkedPhotoUrl?.absoluteString == photoUrl?.absoluteString {
			return
		}

		self.photo.image = nil
		
		if photoUrl != nil {
			self.photo.setImageWithUrl(photoUrl!, animate: false)
			self.photo.showGradient = true
		}
		else if name != nil {
			let seed = Utils.numberFromName(name!)
			self.photo.backgroundColor = Utils.randomColor(seed)
			self.photo.showGradient = true
		}
	}

	override func layoutSubviews() {
		super.layoutSubviews()
				
		let columnWidth = self.width() - (36 + 64 + 8)
		let nameSize = self.name.sizeThatFits(CGSizeMake(columnWidth, CGFloat.max))
		
        self.visibility.anchorCenterLeftWithLeftPadding(16, width: 20, height: 20)
		self.name.alignToTheRightOf(self.visibility, matchingCenterWithLeftPadding: 0, width: 200, height: nameSize.height)
        self.photo.anchorCenterRightWithRightPadding(68, width: 64, height: 40)
	}
}