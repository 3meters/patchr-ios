//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

@IBDesignable
class PhotoControl: UIControl {

    var nameLabel = AirLabelDisplay()
	var imageView = AirImageView(frame: CGRect.zero)
    var target: AnyObject?
    
    @IBInspectable var initialsCount: Int = 2
    @IBInspectable var dummyImage: UIImage? {
        didSet {
            self.imageView.image = dummyImage
        }
    }
    
    override var cornerRadius: CGFloat {
        didSet {
            self.imageView.cornerRadius = cornerRadius
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
        
		/* User photo */
		self.imageView.contentMode = .scaleAspectFill
		
		/* User name */
		self.nameLabel.font = Theme.fontHeading
		self.nameLabel.textColor = Colors.white
		self.nameLabel.textAlignment = .center
        
        self.addSubview(self.imageView)
        self.addSubview(self.nameLabel)
	}
    
    func reset() {
        self.imageView.reset()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.backgroundColor = Colors.accentColorLight
        self.nameLabel.isHidden = true
    }
    
	override func layoutSubviews() {
		super.layoutSubviews()
		self.imageView.fillSuperview()
        self.imageView.progressView.anchorInCenter(withWidth: 150, height: 20)
		self.nameLabel.fillSuperview()
	}
    
    func setImage(image: UIImage?) {
        self.imageView.image = image
        self.imageView.isHidden = (image == nil)
        self.nameLabel.isHidden = (image != nil)
    }
	
    func bind(url: URL?, name: String?, colorSeed: String?, color: UIColor? = nil, uploading: Bool = false) {
        
        if url != nil && self.imageView.associated(withUrl: url!) {
            return
        }
		
        self.nameLabel.text = nil
		self.imageView.isHidden = true
		self.nameLabel.isHidden = false
		
		if url != nil {
            self.imageView.setImageWithUrl(url: url!) { [weak self] success in
                guard let this = self else { return }
                if success {
                    this.nameLabel.isHidden = true
                    this.imageView.isHidden = false
                }
            }
		}
		else {
            self.imageView.fromUrl = nil
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
