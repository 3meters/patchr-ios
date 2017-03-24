//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import FirebaseAuth

class MemberDetailView: UIView {
    
    var contentGroup = UIView()
    var titleGroup = UIView()
    
    var photoView = AirImageView(frame: CGRect.zero)
    var title = AirLabelDisplay()
    var subtitle = AirLabelDisplay()
    var presenceView = PresenceView()
    
    var user: FireUser!
    
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
        
        self.contentGroup.fillSuperview()
        self.photoView.fillSuperview(withLeftPadding: -24, rightPadding: -24, topPadding: -36, bottomPadding: -36)
        self.photoView.progressView.anchorInCenter(withWidth: 20, height: 20)

        self.titleGroup.anchorBottomLeft(withLeftPadding: 16, bottomPadding: 16, width: viewWidth - 32, height: 72)
        self.subtitle.bounds.size.width = self.titleGroup.width()
        self.subtitle.sizeToFit()
        self.subtitle.anchorBottomLeft(withLeftPadding: 0, bottomPadding: 0, width: self.subtitle.width(), height: self.subtitle.height())
        self.presenceView.align(toTheRightOf: self.subtitle, matchingCenterWithLeftPadding: 8, width: 12, height: 12, topPadding: 2)
        self.title.bounds.size.width = self.titleGroup.width()
        self.title.sizeToFit()
        self.title.align(above: self.subtitle, matchingLeftWithBottomPadding: 4, width: self.title.width(), height: self.title.height())
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func initialize() {
        
        self.titleGroup.addSubview(self.title)
        self.titleGroup.addSubview(self.subtitle)
        self.titleGroup.addSubview(self.presenceView)

        self.contentGroup.addSubview(self.photoView)
        self.contentGroup.addSubview(self.titleGroup)
        
        self.clipsToBounds = false
        self.backgroundColor = Theme.colorBackgroundForm
        
        self.photoView.parallaxIntensity = -40
        self.photoView.clipsToBounds = true
        self.photoView.contentMode = .scaleAspectFill
        self.photoView.backgroundColor = Theme.colorBackgroundImage
        self.photoView.showGradient = true
        
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
        
        self.user = user
        self.presenceView.bind(online: user.presence)
        self.title.text = user.profile?.fullName ?? user.username
        
        if user.username != nil {
            self.subtitle.text = "@\(user.username!)"
        }
        
        let fullName = user.profile?.fullName ?? user.username
        
        if let photo = user.profile?.photo {
            let url = Cloudinary.url(prefix: photo.filename)
            if !self.photoView.associated(withUrl: url) {
                self.photoView.gradientLayer.isHidden = true
                self.photoView.setImageWithUrl(url: url) { success in
                    if success {
                        self.photoView.gradientLayer.isHidden = false
                    }
                }
            }
        }
        else if fullName != nil {
            self.photoView.showGradient = false
            let seed = Utils.numberFromName(fullname: user.id!)
            self.photoView.backgroundColor = ColorArray.randomColor(seed: seed)
        }
        else {
            self.photoView.showGradient = false
            self.photoView.backgroundColor = Colors.accentColorFill
        }
        
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
