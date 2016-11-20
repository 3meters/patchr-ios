//
//  UserDetailView.swift
//  Patchr
//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import SDWebImage

@IBDesignable
class PhotoView: UIControl {

    var name = AirLabelDisplay()
	var photo = AirImageView(frame: CGRect.zero)
    var target: AnyObject?
    
    @IBInspectable var initialsCount: Int = 2
    @IBInspectable var rounded: Bool = true {
        didSet {
            self.layer.cornerRadius = self.rounded ? self.width() * 0.5 : self.radius
        }
    }
    @IBInspectable var radius: CGFloat = 0 {
        didSet {
            self.layer.cornerRadius = self.radius
        }
    }
	
	override init(frame: CGRect) {
		/* Called when instantiated from code */
		super.init(frame: frame)
		initialize()
	}
	
	required init?(coder aDecoder: NSCoder) {
        /* Called when instantiated from nib/storyboard */
        super.init(coder: aDecoder)
        initialize()
	}
	
	func initialize() {
		
		self.clipsToBounds = true
        self.backgroundColor = Theme.colorBackgroundImage
		
		/* User photo */
		self.photo.contentMode = .scaleAspectFill
		
		/* User name */
		self.name.font = Theme.fontHeading
		self.name.textColor = Colors.white
		self.name.textAlignment = .center
        
        self.addSubview(self.photo)
        self.addSubview(self.name)
	}
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.backgroundColor = Colors.accentColorLight
        self.name.isHidden = true
        let bundle = Bundle(for: PhotoView.self)
        self.photo.image = UIImage(named: "imgDummyUser", in: bundle, compatibleWith: self.traitCollection)
    }
    
	override func layoutSubviews() {
		super.layoutSubviews()
        self.layer.cornerRadius = self.rounded ? self.width() * 0.5 : self.radius
		self.photo.fillSuperview()
		self.name.fillSuperview()
	}
    
	func bindToEntity(entity: Entity!) {
        /* Zombie */
	}
	
    func bind(photoUrl: URL?, name: String?, colorSeed: String?, color: UIColor? = nil) {
		
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
		else {
            if name != nil {
                self.name.text = Utils.initialsFromName(fullname: name!, count: self.initialsCount).uppercased()
            }
            if color != nil {
                self.backgroundColor = color
            }
            else {
                let seed = Utils.numberFromName(fullname: colorSeed ?? name ?? "lastchance")
                self.backgroundColor = ColorArray.randomColor(seed: seed)
            }
		}
	}
}
