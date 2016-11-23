//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class ChannelDetailView: UIView {
    
    var photoRect: CGRect!

    var contentGroup = UIView()
    var titleGroup = UIView()
    var photo = AirImageView(frame: CGRect.zero)
    var name = AirLabelDisplay()
    var lockImage = AirImageView(frame: CGRect.zero)
    var mutedImage = AirMuteView(frame: CGRect.zero)
    var starButton = AirStarButton(frame: CGRect.zero)
    var infoGroup = AirRuleView()
    var purpose = AirLabelDisplay(frame: CGRect.zero)
    var gradient = CAGradientLayer()

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
        let viewHeight = viewWidth * 0.625

        self.contentGroup.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: viewHeight) // 16:10
        self.titleGroup.anchorBottomLeft(withLeftPadding: 12, bottomPadding: 16, width: viewWidth - 24, height: 72)
        
        self.name.bounds.size.width = self.titleGroup.width()
        self.name.sizeToFit()
        self.name.anchorBottomLeft(withLeftPadding: 0, bottomPadding: 0, width: self.name.width(), height: self.name.height())
        self.lockImage.align(toTheRightOf: self.name, matchingCenterWithLeftPadding: 4, width: !self.lockImage.isHidden ? 16 : 0, height: 16)
        self.mutedImage.align(toTheRightOf: self.lockImage, matchingCenterWithLeftPadding: 4, width: !self.mutedImage.isHidden ? 20 : 0, height: 20)
        self.starButton.align(toTheRightOf: self.mutedImage, matchingCenterWithLeftPadding: 4, width: 24, height: 24)

        let gradientHeight = self.contentGroup.width() * 0.35
        self.gradient.frame = CGRect(x:0, y:self.contentGroup.height() - gradientHeight, width:self.contentGroup.width(), height:gradientHeight)

        /* Purpose */
        if !self.purpose.isHidden {
            self.infoGroup.isHidden = false
            self.purpose.bounds.size.width = viewWidth - 32
            self.purpose.sizeToFit()
            self.purpose.anchorTopLeft(withLeftPadding: 12, topPadding: 12, width: self.purpose.width(), height: self.purpose.height())
            self.infoGroup.alignUnder(self.contentGroup, matchingLeftAndRightWithTopPadding: 0, height: self.purpose.height() + 32)
        }
        else {
            self.infoGroup.isHidden = true
            self.infoGroup.alignUnder(self.contentGroup, matchingLeftAndRightWithTopPadding: 0, height: 0)
        }
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func initialize() {
        
        self.titleGroup.addSubview(self.name)
        self.titleGroup.addSubview(self.lockImage)
        self.titleGroup.addSubview(self.mutedImage)
        self.titleGroup.addSubview(self.starButton)
        
        self.contentGroup.addSubview(self.photo)
        self.contentGroup.addSubview(self.titleGroup)
        
        self.infoGroup.backgroundColor = Theme.colorBackgroundTile
        self.infoGroup.addSubview(self.purpose)
        
        self.clipsToBounds = false
        self.backgroundColor = Theme.colorBackgroundForm
        
        self.photo.parallaxIntensity = -40
        self.photo.sizeCategory = SizeCategory.standard
        self.photo.clipsToBounds = true
        self.photo.contentMode = UIViewContentMode.scaleAspectFill
        self.photo.backgroundColor = Theme.colorBackgroundImage
        
        /* Apply gradient to banner */
        let topColor: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.0))        // Top
        let stop2Color: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.33))    // Middle
        let bottomColor: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.66))        // Bottom
        self.gradient.colors = [topColor.cgColor, stop2Color.cgColor, bottomColor.cgColor]
        self.gradient.locations = [0.0, 0.5, 1.0]
        
        /* Travels from top to bottom */
        self.gradient.startPoint = CGPoint(x: 0.5, y: 0.0)    // (0,0) upper left corner, (1,1) lower right corner
        self.gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        self.gradient.isHidden = true
        self.contentGroup.layer.insertSublayer(self.gradient, at: 1)
        
        self.name.font = UIFont(name: "HelveticaNeue-Light", size: 28)!
        self.name.textColor = Colors.white
        self.name.numberOfLines = 2
        
        self.purpose.numberOfLines = 0
        
        self.lockImage.image = Utils.imageLock
        self.lockImage.tintColor = Colors.white
        self.mutedImage.image = Utils.imageMuted
        self.mutedImage.tintColor = Colors.white
        
        self.addSubview(contentGroup)
        self.addSubview(infoGroup)
        
        self.contentGroup.clipsToBounds = true
    }
    
    func reset() {
        self.gradient.isHidden = true
        self.photo.image = nil
        self.photo.backgroundColor = Theme.colorBackgroundImage
        self.name.text = nil
        self.purpose.text = nil
        self.mutedImage.isHidden = true
        self.starButton.isHidden = true
        self.lockImage.isHidden = true        
    }
    
    func bind(channel: FireChannel!) {
        
        /* Name, type and photo */
        
        self.name.text = "#\(channel.name!)"
        self.purpose.isHidden = true
        
        if channel.purpose != nil && !channel.purpose!.isEmpty {
            self.purpose.text = channel.purpose!
            self.purpose.isHidden = false
        }

        self.starButton.isHidden = false
        
        if let photo = channel.photo, !photo.uploading {
            self.starButton.tintColor = Colors.brandColor
            if let photoUrl = PhotoUtils.url(prefix: photo.filename, source: photo.source, category: SizeCategory.standard) {
                self.photo.setImageWithUrl(url: photoUrl)
                self.gradient.isHidden = false
                self.photo.backgroundColor = Theme.colorBackgroundImage
            }
        }
        else {
            self.gradient.isHidden = true
            self.photo.image = nil
            self.starButton.tintColor = Colors.white
            if channel.name == "general" || channel.general! {
                self.photo.backgroundColor = Colors.brandColorLight
            }
            else if channel.name == "chatter" {
                self.photo.backgroundColor = Colors.accentColorFill
            }
            else {
                let seed = Utils.numberFromName(fullname: channel.name!)
                self.photo.backgroundColor = ColorArray.randomColor(seed: seed)
            }
        }

        /* Public/private */
        self.lockImage.isHidden = (channel.visibility == "open")
        self.mutedImage.isHidden = true
        
        /* Per user indicators */
        self.starButton.bind(channel: channel)
        self.mutedImage.bind(channel: channel)

        self.setNeedsLayout()    // Needed because binding can change element layout
        self.layoutIfNeeded()
        self.sizeToFit()
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
