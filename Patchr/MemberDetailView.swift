//
//  UserDetailView.swift
//  Patchr
//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class MemberDetailView: UIView {
    
    var photoRect: CGRect!

    var contentGroup = UIView()
    var titleGroup = UIView()
    var photo = AirImageView(frame: CGRect.zero)
    var title = AirLabelDisplay()
    var subtitle = AirLabelDisplay()
    var presenceView = PresenceView()
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
        self.titleGroup.anchorBottomLeft(withLeftPadding: 16, bottomPadding: 16, width: viewWidth - 32, height: 72)

        self.photo.frame = CGRect(x: -24, y: -36, width: viewWidth + 48, height: viewHeight + 72)
        
        self.subtitle.bounds.size.width = self.titleGroup.width()
        self.subtitle.sizeToFit()
        self.subtitle.anchorBottomLeft(withLeftPadding: 0, bottomPadding: 0, width: self.subtitle.width(), height: self.subtitle.height())
        
        self.presenceView.align(toTheRightOf: self.subtitle, matchingCenterWithLeftPadding: 8, width: 12, height: 12)

        self.title.bounds.size.width = self.titleGroup.width()
        self.title.sizeToFit()
        self.title.align(above: self.subtitle, matchingLeftWithBottomPadding: 4, width: self.title.width(), height: self.title.height())

        let gradientHeight = self.contentGroup.width() * 0.35
        self.gradient.frame = CGRect(x:0, y:self.contentGroup.height() - gradientHeight, width:self.contentGroup.width(), height:gradientHeight)
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func initialize() {
        
        self.titleGroup.addSubview(self.title)
        self.titleGroup.addSubview(self.subtitle)
        self.titleGroup.addSubview(self.presenceView)

        self.contentGroup.addSubview(self.photo)
        self.contentGroup.addSubview(self.titleGroup)
        
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
        
        self.title.font = UIFont(name: "HelveticaNeue-Light", size: 28)!
        self.title.textColor = Colors.white
        self.title.numberOfLines = 2

        self.subtitle.font = UIFont(name: "HelveticaNeue-Light", size: 18)!
        self.subtitle.textColor = Colors.white
        self.subtitle.numberOfLines = 1

        self.addSubview(contentGroup)

        self.contentGroup.clipsToBounds = true
    }
    
    func bind(user: FireUser!) {
        
        if let group = StateController.instance.group, let profile = user.profile {
            if profile.fullName != nil {
                self.title.text = profile.fullName
                self.subtitle.text = "@\(group.username!)"
            }
            else {
                self.title.text = group.username
            }
            
            /* Name, type and photo */
            self.presenceView.bind(online: user.presence)
            
            if let photo = profile.photo, !photo.uploading {
                if let photoUrl = PhotoUtils.url(prefix: photo.filename, source: photo.source, category: SizeCategory.standard) {
                    self.photo.setImageWithUrl(url: photoUrl)
                    self.gradient.isHidden = false
                }
            }
            else if profile.fullName != nil {
                let seed = Utils.numberFromName(fullname: user.id!)
                self.photo.backgroundColor = ColorArray.randomColor(seed: seed)
            }
            else {
                self.photo.backgroundColor = Colors.accentColorFill
            }
            
            self.setNeedsLayout()    // Needed because binding can change element layout
            self.layoutIfNeeded()
            self.sizeToFit()
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
