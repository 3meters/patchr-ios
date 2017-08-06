//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class ChannelPhotoView: UIView {
    
    var contentGroup = UIView()
    var photoView = AirImageView(frame: CGRect.zero)
    var photo: FirePhoto!
    var needsPhoto = false
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

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
        super.init(coder: aDecoder)
        initialize()
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    override func layoutSubviews() {
        /*
         * Scrolling does not cause this to be called.
         */
        super.layoutSubviews()

        self.contentGroup.fillSuperview()
        self.photoView.fillSuperview(withLeftPadding: -24, rightPadding: -24, topPadding: -36, bottomPadding: -36)
        self.photoView.progressView.anchorInCenter(withWidth: 150, height: 20)
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func initialize() {
        
        self.clipsToBounds = false
        self.backgroundColor = Theme.colorBackgroundForm
        
        self.photoView.parallaxIntensity = -40
        self.photoView.clipsToBounds = true
        self.photoView.contentMode = .scaleAspectFill
        self.photoView.backgroundColor = Theme.colorBackgroundImage
        self.photoView.showGradient = true
        self.photoView.gradientLayer.isHidden = true
        
        self.contentGroup.clipsToBounds = true
        self.contentGroup.addSubview(self.photoView)
        self.addSubview(contentGroup)
        
    }
    
    func bind(channel: FireChannel!) {
        
        /* Name, type and photo */
        if let photo = channel.photo {
            self.photo = photo
            self.needsPhoto = true
            self.photoView.backgroundColor = Theme.colorBackgroundImage
            displayPhoto()
        }
        else {
            self.photoView.image = nil
            self.photoView.gradientLayer.isHidden = true
            if channel.name == "general" || channel.general! {
                self.photoView.backgroundColor = Colors.brandColorLight
            }
            else if channel.name == "chatter" {
                self.photoView.backgroundColor = Colors.accentColorFill
            }
            else {
                let seed = Utils.numberFromName(fullname: channel.title!.lowercased())
                self.photoView.backgroundColor = ColorArray.randomColor(seed: seed)
            }
        }

        self.setNeedsLayout()    // Needed because binding can change element layout
        self.layoutIfNeeded()
        self.sizeToFit()
    }
    
    func reset() {
        self.photoView.reset()
    }
    
    func displayPhoto() {
        let photo = self.photo!
        let url = ImageProxy.url(photo: photo, category: SizeCategory.standard)
        
        if !self.photoView.associated(withUrl: url) {
            self.photoView.setImageWithUrl(url: url) { success in
                if success {
                    self.photoView.gradientLayer.isHidden = false
                    self.needsPhoto = false
                }
            }
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        
        var w = CGFloat(0)
        var h = CGFloat(0)
        
        for subview in self.subviews {
            let fw = subview.frame.origin.x + subview.frame.size.width
            let fh = subview.frame.origin.y + subview.frame.size.height
            w = max(fw, w)
            h = max(fh, h)
        }
        
        return CGSize(width: w, height: h)
    }
}
