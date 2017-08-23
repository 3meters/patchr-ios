//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import ChameleonFramework

class ChannelDetailView: UIView {
    
    var contentGroup = UIView()
    var titleGroup = UIView()
    var infoGroup = AirRuleView()
    
    var photoView = AirImageView(frame: CGRect.zero)
    var titleLabel = AirLabelDisplay()
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

        self.titleLabel.bounds.size.width = self.titleGroup.width()
        self.titleLabel.sizeToFit()
        self.titleLabel.anchorBottomLeft(withLeftPadding: 0, bottomPadding: 0, width: self.titleLabel.width(), height: self.titleLabel.height())

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
        
        self.titleLabel.font = UIFont(name: "HelveticaNeue-Light", size: 28)!
        self.titleLabel.textColor = Colors.white
        self.titleLabel.numberOfLines = 2

        self.purposeLabel.numberOfLines = 0
        
        self.contentGroup.addSubview(self.photoView)
        self.addSubview(contentGroup)
        
        self.contentGroup.clipsToBounds = true
    }
    
    func bind(channel: FireChannel!) {
        
        if self.titleGroup.superview == nil {
            self.titleGroup.addSubview(self.titleLabel)
            self.contentGroup.addSubview(self.titleGroup)
        }
        
        /* Name, type and photo */
        
        let nameString = "\(channel.title!)"
        let attrString = NSMutableAttributedString(string: nameString)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 0.8
        attrString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, attrString.length))
        
        self.titleLabel.attributedText = attrString
        
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
        self.titleLabel.text = nil
    }
    
    func displayPhoto() {
        let photo = self.photo!
        let url = ImageProxy.url(photo: photo, category: SizeCategory.standard)
        
        if !self.photoView.associated(withUrl: url) {
            self.photoView.setImageWithUrl(url: url) { success in
                if success {
                    self.photoView.gradientLayer.isHidden = false
                    self.needsPhoto = false
                    if self.infoGroup.superview != nil {
                        if let image = self.photoView.image {
                            let colorImageAverage = AverageColorFromImage(image)
                            let colorText = ContrastColorOf(colorImageAverage, returnFlat: false)
                            self.infoGroup.backgroundColor = colorImageAverage
                            self.purposeLabel.textColor = colorText
                        }
                    }
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