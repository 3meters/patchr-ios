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

	var name		= AirLabelDisplay()
	var photo		= AirImageView(frame: CGRectZero)
	
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
		
		if self.photo.image != nil
			&& self.photo.linkedPhotoUrl != nil
			&& photoUrl != nil
			&& self.photo.linkedPhotoUrl?.absoluteString == photoUrl?.absoluteString {
			return
		}
		
		let animate = true
		
		self.photo.hidden = true
		self.photo.image = nil
		self.name.text = nil
		self.name.hidden = false
		
		self.backgroundColor = Colors.gray80pcntColor
		
		if photoUrl != nil {
			
			self.photo.sd_setImageWithURL(photoUrl,
				placeholderImage: nil,
				options: [.RetryFailed, .LowPriority, .AvoidAutoSetImage, .ProgressiveDownload],
				completed: { [weak self] image, error, cacheType, url in
					
					if self != nil && error == nil {
						dispatch_async(dispatch_get_main_queue()) {
							
							self?.photo.linkedPhotoUrl = photoUrl
							self?.name.hidden = true
							self?.photo.hidden = false
							
							if animate && self != nil {
								UIView.transitionWithView(self!,
									duration: 0.4,
									options: UIViewAnimationOptions.TransitionCrossDissolve,
									animations: {
										self?.photo.image = image
									},
									completion: nil)
							}
							else {
								self?.photo.image = image
							}
						}
					}
				}
			)
		}
		else if name != nil {
			self.name.text = Utils.initialsFromName(name!).uppercaseString
			let seed = Utils.numberFromName(name!)
			self.backgroundColor = Utils.randomColor(seed)
		}
	}
}
