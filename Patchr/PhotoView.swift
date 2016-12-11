//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import SDWebImage

@IBDesignable
class PhotoView: UIControl {

    var nameLabel = AirLabelDisplay()
	var photoView = AirImageView(frame: CGRect.zero)
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
		self.photoView.contentMode = .scaleAspectFill
		
		/* User name */
		self.nameLabel.font = Theme.fontHeading
		self.nameLabel.textColor = Colors.white
		self.nameLabel.textAlignment = .center
        
        self.addSubview(self.photoView)
        self.addSubview(self.nameLabel)
	}
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.backgroundColor = Colors.accentColorLight
        self.nameLabel.isHidden = true
        let bundle = Bundle(for: PhotoView.self)
        self.photoView.image = UIImage(named: "imgDummyUser", in: bundle, compatibleWith: self.traitCollection)
    }
    
	override func layoutSubviews() {
		super.layoutSubviews()
        self.layer.cornerRadius = self.rounded ? self.width() * 0.5 : self.radius
		self.photoView.fillSuperview()
		self.nameLabel.fillSuperview()
	}
	
    func bind(url: URL?, fallbackUrl: URL?, name: String?, colorSeed: String?, color: UIColor? = nil) {
		
		if self.photoView.image != nil
			&& self.photoView.linkedPhotoUrl != nil
			&& url != nil
			&& self.photoView.linkedPhotoUrl?.absoluteString == url?.absoluteString {
			return
		}
		
		let animate = true
		
		self.photoView.isHidden = true
		self.photoView.image = nil
		self.nameLabel.text = nil
		self.nameLabel.isHidden = false
		
		if url != nil {
			
			let options: SDWebImageOptions = [.retryFailed, .lowPriority, .avoidAutoSetImage,/* .ProgressiveDownload*/]
			
            self.photoView.sd_setImage(with: url as URL!, placeholderImage: nil, options: options) { [weak self] image, error, cacheType, url in
                if error != nil && fallbackUrl != nil {
                    Log.w("*** Image fetch failed: " + error!.localizedDescription)
                    Log.w("*** Failed url: \(url!.absoluteString)")
                    Log.w("*** Trying fallback url for image: \(fallbackUrl!)")
                    self?.photoView.sd_setImage(with: fallbackUrl!, placeholderImage: nil, options: options) { [weak self] image, error, cacheType, url in
                        if error == nil {
                            Log.w("*** Success using fallback url for image: \(fallbackUrl!)")
                        }
                        DispatchQueue.main.async() {
                            self?.photoView.linkedPhotoUrl = fallbackUrl
                            self?.nameLabel.isHidden = true
                            self?.photoView.isHidden = false
                            
                            if animate && self != nil {
                                UIView.transition(with: self!
                                    , duration: 0.4
                                    , options: UIViewAnimationOptions.transitionCrossDissolve
                                    , animations: { self?.photoView.image = image }
                                    , completion: nil)
                            }
                            else {
                                self?.photoView.image = image
                            }
                        }
                    }
                }
                else {
                    DispatchQueue.main.async() {
                        self?.photoView.linkedPhotoUrl = url
                        self?.nameLabel.isHidden = true
                        self?.photoView.isHidden = false
                        
                        if animate && self != nil {
                            UIView.transition(with: self!
                                , duration: 0.4
                                , options: UIViewAnimationOptions.transitionCrossDissolve
                                , animations: { self?.photoView.image = image }
                                , completion: nil)
                        }
                        else {
                            self?.photoView.image = image
                        }
                    }
                }
            }
		}
		else {
            if name != nil {
                self.nameLabel.text = Utils.initialsFromName(fullname: name!, count: self.initialsCount).uppercased()
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
