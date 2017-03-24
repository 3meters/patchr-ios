//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

@IBDesignable
class PhotoControl: UIControl {

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
    
    func reset() {
        self.photoView.reset()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.backgroundColor = Colors.accentColorLight
        self.nameLabel.isHidden = true
        let bundle = Bundle(for: PhotoControl.self)
        self.photoView.image = UIImage(named: "imgDummyUser", in: bundle, compatibleWith: self.traitCollection)
    }
    
	override func layoutSubviews() {
		super.layoutSubviews()
        self.layer.cornerRadius = self.rounded ? self.width() * 0.5 : self.radius
		self.photoView.fillSuperview()
        self.photoView.progressView.anchorInCenter(withWidth: 20, height: 20)
		self.nameLabel.fillSuperview()
	}
    
    func setImage(image: UIImage?) {
        self.photoView.image = image
        self.photoView.isHidden = (image == nil)
        self.nameLabel.isHidden = (image != nil)
    }
	
    func bind(url: URL?, name: String?, colorSeed: String?, color: UIColor? = nil, uploading: Bool = false) {
        
        if url != nil && self.photoView.associated(withUrl: url!) {
            return
        }
		
        self.nameLabel.text = nil
		self.photoView.isHidden = true
		self.nameLabel.isHidden = false
		
		if url != nil {
            self.photoView.setImageWithUrl(url: url!) { [weak self] success in
                if success {
                    self?.nameLabel.isHidden = true
                    self?.photoView.isHidden = false
                }
            }
		}
		else {
            self.photoView.fromUrl = nil
            if name != nil {
                self.nameLabel.text = Utils.initialsFromName(fullname: name!, count: self.initialsCount).uppercased()
            }
            if color != nil {
                self.backgroundColor = color
            }
            else {
                let seed = Utils.numberFromName(fullname: colorSeed ?? name ?? "lastchance")
                let color = ColorArray.randomColor(seed: seed)
                self.backgroundColor = color
            }
		}
	}
}
