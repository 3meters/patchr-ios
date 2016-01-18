//
//  UserDetailView.swift
//  Patchr
//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import SDWebImage

class UserPhotoView: BaseDetailView {

	var name	= AirLabelDisplay()
	var photo	= AirImageView(frame: CGRectZero)
	
	init() {
		super.init(frame: CGRectZero)
		initialize()
	}
	
	override init(frame: CGRect) {
		/* Called when instantiated from code */
		super.init(frame: frame)
		initialize()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("This view should never be loaded from storyboard")
	}
	
	func initialize() {
		
		self.clipsToBounds = true
		self.layer.backgroundColor = Theme.colorBackgroundImage.CGColor
		
		/* User photo */
		self.photo.contentMode = .ScaleAspectFill
		
		/* User name */
		self.name.hidden = true
		self.name.font = Theme.fontHeading
		self.name.textColor = Colors.white
		self.name.textAlignment = .Center

		self.addSubview(self.photo)
		self.addSubview(self.name)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		self.layer.cornerRadius = self.width() * 0.5
		self.photo.fillSuperview()
		self.name.fillSuperview()
	}
	
	func bindToEntity(entity: Entity!) {
		if entity != nil {
			if entity.photo != nil {
				let photoUrl = PhotoUtils.url(entity.photo!.prefix!, source: entity.photo!.source!, category: SizeCategory.profile)
				bindPhoto(photoUrl, name: entity.name)
			}
			else {
				bindPhoto(nil, name: entity.name)
			}
		}
		else {
			bindPhoto(nil, name: nil)
		}
	}
	
	func bindPhoto(photoUrl: NSURL?, name: String?) {
		let options: SDWebImageOptions = [.RetryFailed, .LowPriority,  .ProgressiveDownload]
		self.photo.image = nil
		self.name.text = nil
		if photoUrl == nil && name == nil {
			/* For some reason, the user is missing or deleted */
			let photo = Entity.getDefaultPhoto("user", id: nil)
			let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!, category: SizeCategory.profile)
			self.photo.sd_setImageWithURL(photoUrl, placeholderImage: nil, options: options)
		}
		else {
			if photoUrl != nil {
				self.photo.sd_setImageWithURL(photoUrl, placeholderImage: nil, options: options)
			}
			else if name != nil {
				self.name.text = Utils.initialsFromName(name!).uppercaseString
				self.name.hidden = false
				let seed = Utils.numberFromName(name!)
				self.backgroundColor = Utils.randomColor(seed)
			}
		}
	}	
}
