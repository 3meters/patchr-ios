//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class ChannelDetailView: UIView {
    
    var contentGroup = UIView()
    var titleGroup = UIView()
    var infoGroup = AirRuleView()
    
    var photoView = AirImageView(frame: CGRect.zero)
    var name = AirLabelDisplay()
    var lockImage = UIImageView(frame: CGRect.zero)
    var mutedImage = AirMuteView(frame: CGRect.zero)
    var starButton = AirStarButton(frame: CGRect.zero)
    var optionsButton = UIButton(frame: CGRect.zero)
    var purposeLabel = AirLabelDisplay(frame: CGRect.zero)
    
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
        fatalError("This view should never be loaded from storyboard")
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    override func layoutSubviews() {
        /*
         * Scrolling does not cause this to be called.
         */
        super.layoutSubviews()

        let viewWidth = self.bounds.size.width
        
        if self.infoGroup.superview != nil {
            self.purposeLabel.bounds.size.width = viewWidth - 32
            self.purposeLabel.sizeToFit()
            self.contentGroup.fillSuperview(withLeftPadding: 0, rightPadding: 0, topPadding: 0, bottomPadding: self.purposeLabel.height() + 24)
        }
        else {
            self.contentGroup.fillSuperview()
        }

        self.photoView.fillSuperview(withLeftPadding: -24, rightPadding: -24, topPadding: -36, bottomPadding: -36)
        self.photoView.progressView.anchorInCenter(withWidth: 150, height: 20)
        self.titleGroup.anchorBottomLeft(withLeftPadding: 12, bottomPadding: 16, width: viewWidth - 72, height: 72)
        
        let indicatorsWidth = (!self.lockImage.isHidden ? 20 : 0) + (!self.mutedImage.isHidden ? 24 : 0)
        self.name.bounds.size.width = self.titleGroup.width() - CGFloat(indicatorsWidth + 28)
        self.name.sizeToFit()
        self.name.anchorBottomLeft(withLeftPadding: 0, bottomPadding: 0, width: self.name.width(), height: self.name.height())
        
        self.lockImage.align(toTheRightOf: self.name, matchingCenterWithLeftPadding: 4, width: !self.lockImage.isHidden ? 16 : 0, height: 16)
        self.mutedImage.align(toTheRightOf: self.lockImage, matchingCenterWithLeftPadding: 4, width: !self.mutedImage.isHidden ? 20 : 0, height: 20)
        self.starButton.align(toTheRightOf: self.mutedImage, matchingCenterWithLeftPadding: 4, width: !self.starButton.isHidden ? 24 : 0, height: 24)
        
        self.optionsButton.anchorBottomRight(withRightPadding: 12, bottomPadding: 20, width: 24, height: 24)

        /* Purpose */
        if self.infoGroup.superview != nil {
            self.purposeLabel.anchorTopLeft(withLeftPadding: 12, topPadding: 12, width: self.purposeLabel.width(), height: self.purposeLabel.height())
            self.infoGroup.alignUnder(self.contentGroup, matchingLeftAndRightWithTopPadding: 0, height: self.purposeLabel.height() + 24)
        }
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func initialize() {
        
        self.clipsToBounds = false
        self.backgroundColor = Theme.colorBackgroundForm
        
        self.infoGroup.backgroundColor = Theme.colorBackgroundTile
        self.infoGroup.addSubview(self.purposeLabel)
        
        self.photoView.parallaxIntensity = -40
        self.photoView.clipsToBounds = true
        self.photoView.contentMode = .scaleAspectFill
        self.photoView.backgroundColor = Theme.colorBackgroundImage
        self.photoView.showGradient = true
        self.photoView.gradientLayer.isHidden = true
        
        self.name.font = UIFont(name: "HelveticaNeue-Light", size: 28)!
        self.name.textColor = Colors.white
        self.name.numberOfLines = 2
        
        self.purposeLabel.numberOfLines = 0
        
        self.optionsButton.setImage(UIImage(named: "imgOverflowVerticalLight"), for: .normal)
        self.optionsButton.showsTouchWhenHighlighted = true

        self.lockImage.image = Utils.imageLock
        self.lockImage.tintColor = Colors.white
        self.mutedImage.image = Utils.imageMuted
        self.mutedImage.tintColor = Colors.white
        
        self.contentGroup.addSubview(self.photoView)
        self.addSubview(contentGroup)
        
        self.contentGroup.clipsToBounds = true
    }
    
    func bind(channel: FireChannel!) {
        
        if self.titleGroup.superview == nil {
            self.titleGroup.addSubview(self.name)
            self.titleGroup.addSubview(self.lockImage)
            self.titleGroup.addSubview(self.mutedImage)
            self.titleGroup.addSubview(self.starButton)
            self.contentGroup.addSubview(self.titleGroup)
            self.contentGroup.addSubview(self.optionsButton)
        }
        
        /* Name, type and photo */
        
        self.name.text = "#\(channel.name!)"
        
        if channel.purpose != nil && !channel.purpose!.isEmpty {
            self.addSubview(self.infoGroup)
            self.purposeLabel.text = channel.purpose!
        }
        else {
            if self.infoGroup.superview != nil {
                self.infoGroup.removeFromSuperview()
            }
        }
        
        if let photo = channel.photo {
            self.photo = photo
            self.needsPhoto = true
            self.starButton.tintColor = Colors.brandColor
            self.optionsButton.tintColor = Colors.brandColor
            self.photoView.backgroundColor = Theme.colorBackgroundImage
            displayPhoto()
        }
        else {
            self.photoView.image = nil
            self.photoView.gradientLayer.isHidden = true
            self.starButton.tintColor = Colors.white
            self.optionsButton.tintColor = Colors.white
            if channel.name == "general" || channel.general! {
                self.photoView.backgroundColor = Colors.brandColorLight
            }
            else if channel.name == "chatter" {
                self.photoView.backgroundColor = Colors.accentColorFill
            }
            else {
                let seed = Utils.numberFromName(fullname: channel.name!)
                self.photoView.backgroundColor = ColorArray.randomColor(seed: seed)
            }
        }

        /* Public/private */
        self.lockImage.isHidden = (channel.visibility == "open")
        self.mutedImage.isHidden = true
        self.starButton.isHidden = (channel.joinedAt == nil)
        
        /* Per user indicators */
        self.starButton.bind(channel: channel)
        self.mutedImage.bind(channel: channel)

        self.setNeedsLayout()    // Needed because binding can change element layout
        self.layoutIfNeeded()
        self.sizeToFit()
    }
    
    func displayPhoto() {
        let photo = self.photo!
        let url = Cloudinary.url(prefix: photo.filename)
        
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
