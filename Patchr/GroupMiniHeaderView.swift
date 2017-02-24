//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class GroupMiniHeaderView: BaseDetailView {

    var photoControl = PhotoControl()
    var title = AirLabelTitle()
    var subtitle = UILabel()
    var gradientImage: UIImage!
    var gradientView: UIImageView!
    
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
    
    func initialize() {
        
        self.clipsToBounds = true
        self.backgroundColor = Theme.colorBackgroundForm
        
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: Config.navigationDrawerWidth, height: 24)
        gradient.colors = [Colors.accentColor.cgColor, Colors.brandColor.cgColor]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradient.zPosition = 1
        gradient.shouldRasterize = true
        gradient.rasterizationScale = UIScreen.main.scale
        
        self.gradientImage = ImageUtils.imageFromLayer(layer: gradient)
        self.gradientView = UIImageView(image: self.gradientImage)

        self.photoControl.rounded = false
        self.photoControl.radius = 6
        
        /* User friendly name */
        self.title.lineBreakMode = .byTruncatingMiddle
        self.title.font = Theme.fontTextDisplay
        self.title.textAlignment = .left
        
        /* Username */
        self.subtitle.lineBreakMode = .byTruncatingMiddle
        self.subtitle.font = Theme.fontComment
        self.subtitle.textColor = Theme.colorTextSecondary
        self.subtitle.textAlignment = .left
        
        self.addSubview(self.photoControl)
        self.addSubview(self.title)
        self.addSubview(self.subtitle)
        self.addSubview(self.gradientView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let contentWidth = self.bounds.size.width - 32
        let columnWidth = contentWidth - 56
        
        self.subtitle.bounds.size.width = columnWidth
        self.subtitle.sizeToFit()
        
        self.gradientView.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 24)
        self.photoControl.anchorBottomLeft(withLeftPadding: 16, bottomPadding: 12, width: 48, height: 48)
        
        if !self.title.isHidden {
            self.title.bounds.size.width = columnWidth
            self.title.sizeToFit()
            self.title.align(toTheRightOf: self.photoControl, matchingTopWithLeftPadding: 8, width: columnWidth, height: self.title.height())
            self.subtitle.alignUnder(self.title, matchingLeftWithTopPadding: 0, width: columnWidth, height: self.subtitle.height())
        }
        else {
            self.title.align(toTheRightOf: self.photoControl, matchingTopWithLeftPadding: 8, width: columnWidth, height: 0)
            self.subtitle.alignUnder(self.title, matchingLeftWithTopPadding: 0, width: columnWidth, height: self.subtitle.height())
            self.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: (16 + 96 + 32 + 16))
        }
    }
    
    func bind(group: FireGroup?) {
        
        self.title.text?.removeAll(keepingCapacity: false)
        self.subtitle.text?.removeAll(keepingCapacity: false)

        if group != nil {

            self.title.text = group!.title
            if group!.role != nil {
                self.subtitle.text = "as \(group!.role!)"
            }

            if let photo = group!.photo {
                if photo.uploading != nil {
                    self.photoControl.bind(url: URL(string: photo.cacheKey)!, fallbackUrl: nil, name: nil, colorSeed: nil, uploading: true)
                }
                else {
                    if let url = ImageUtils.url(prefix: photo.filename, source: photo.source, category: SizeCategory.profile) {
                        let fallbackUrl = ImageUtils.fallbackUrl(prefix: photo.filename!)
                        self.photoControl.bind(url: url, fallbackUrl: fallbackUrl, name: nil, colorSeed: group!.id)
                    }
                }
            }
            else {
                self.photoControl.bind(url: nil, fallbackUrl: nil, name: group!.title, colorSeed: group!.id)
            }
        }
        else {
            self.photoControl.bind(url: nil, fallbackUrl: nil, name: nil, colorSeed: nil, color: Theme.colorBackgroundImage)
        }
        
        self.setNeedsLayout()
    }
}
