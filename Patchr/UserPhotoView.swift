//
//  UserDetailView.swift
//  Patchr
//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import SDWebImage

class UserPhotoView: UIControl {

	var name		= AirLabelDisplay()
	var photo		= AirImageView(frame: CGRect.zero)
	
	init() {
		super.init(frame: CGRect.zero)
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
		self.layer.backgroundColor = Theme.colorBackgroundImage.cgColor
		
		/* User photo */
		self.photo.contentMode = .scaleAspectFill
		
		/* User name */
		self.name.font = Theme.fontHeading
		self.name.textColor = Colors.white
		self.name.textAlignment = .center

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
				let photoUrl = PhotoUtils.url(prefix: entity.photo!.prefix!, source: entity.photo!.source!, category: SizeCategory.profile)
				bindPhoto(photoUrl: photoUrl, name: entity.name)
			}
			else {
				bindPhoto(photoUrl: nil, name: entity.name)
			}
		}
		else {
			bindPhoto(photoUrl: nil, name: nil)
		}
	}
	
	func bindPhoto(photoUrl: URL?, name: String?) {
		
		if self.photo.image != nil
			&& self.photo.linkedPhotoUrl != nil
			&& photoUrl != nil
			&& self.photo.linkedPhotoUrl?.absoluteString == photoUrl?.absoluteString {
			return
		}
		
		let animate = true
		
		self.photo.isHidden = true
		self.photo.image = nil
		self.name.text = nil
		self.name.isHidden = false
		
		self.backgroundColor = Colors.gray80pcntColor
		
		if photoUrl != nil {
			
			let options: SDWebImageOptions = [.retryFailed, .lowPriority, .avoidAutoSetImage,/* .ProgressiveDownload*/]
			
			self.photo.sd_setImage(with: photoUrl as URL!
				, placeholderImage: nil
				, options: options
				, completed: { [weak self] image, error, cacheType, url in
											
					if self != nil && error == nil {
						
						DispatchQueue.main.async() {
							
							self?.photo.linkedPhotoUrl = photoUrl
							self?.name.isHidden = true
							self?.photo.isHidden = false
							
							if animate && self != nil {
								UIView.transition(with: self!,
									duration: 0.4,
									options: UIViewAnimationOptions.transitionCrossDissolve,
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
			self.name.text = Utils.initialsFromName(fullname: name!).uppercased()
			let seed = Utils.numberFromName(fullname: name!)
			self.backgroundColor = Utils.randomColor(seed: seed)
		}
	}
}
