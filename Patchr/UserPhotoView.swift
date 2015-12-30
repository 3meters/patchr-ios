//
//  UserDetailView.swift
//  Patchr
//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

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
		self.name.font = Theme.fontTitle
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
	
	func bind(photoUrl: NSURL?, name: String?) {
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
				self.name.text = initialsFromName(name!).uppercaseString
				self.name.hidden = false
				let seed = numberFromName(name!)
				self.backgroundColor = randomColor(seed)
			}
		}
	}
	
	func bindToEntity(entity: Entity!) {
		if entity != nil {
			if entity.photo != nil {
				let photoUrl = PhotoUtils.url(entity.photo!.prefix!, source: entity.photo!.source!, category: SizeCategory.profile)
				bind(photoUrl, name: entity.name)
			}
			else {
				bind(nil, name: entity.name)
			}
		}
		else {
			bind(nil, name: nil)
		}
	}
	
	func initialsFromName(fullname: String) -> String {
		let words = fullname.componentsSeparatedByString(" ")
		var initials = ""
		for word in words {
			initials.append(word[0])
		}
		return initials.length > 2 ? initials[0...1] : initials
	}
	
	func numberFromName(fullname: String) -> UInt32 {
		var accum: UInt32 = 0
		for character in fullname.characters {
			let s = (String(character).unicodeScalars)
			accum += s[s.startIndex].value
		}
		return accum
	}
	
	func randomColor(seed: UInt32?) -> UIColor {
		if seed != nil {
			srand(seed!)
			let hue = CGFloat(Double(rand() % 256) / 256.0) // 0.0 to 1.0
			let saturation = CGFloat(Double(rand() % 128) / 266.0 + 0.5) // 0.5 to 1.0, away from white
			let brightness = CGFloat(Double(rand() % 128) / 256.0 + 0.5) // 0.5 to 1.0, away from black
			return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
		}
		else {
			let hue = CGFloat(Double(arc4random() % 256) / 256.0) // 0.0 to 1.0
			let saturation = CGFloat(Double(arc4random() % 128) / 266.0 + 0.5) // 0.5 to 1.0, away from white
			let brightness = CGFloat(Double(arc4random() % 128) / 256.0 + 0.5) // 0.5 to 1.0, away from black
			return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
		}
	}
}
