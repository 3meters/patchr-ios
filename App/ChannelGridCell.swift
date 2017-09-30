//
//  Created by Jay Massena on 7/15/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import FirebaseDatabase
import Foundation
import UIKit

class ChannelGridCell: UICollectionViewCell {
    
    var badge = UILabel()
    var photoView = AirImageView(frame: .zero)
    var titleLabel = UILabel()
    
    var badgeIsHidden = true {
        didSet {
            if badgeIsHidden {
                self.badge.fadeOut()
            }
            else {
                self.badge.fadeIn()
            }
        }
    }
    
    var photo: FirePhoto!

    var channel: FireChannel!
    var unreadQuery: UnreadQuery? // Passed in by table data source
    var channelQuery: ChannelQuery? // Passed in by table data source
    var photosQuery: PhotosQuery?
    var selectedOn = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.contentView.bounds.size.width = self.bounds.size.width
        let photoHeight = self.contentView.width() * 0.5625        // 16:9 aspect ratio
        
        self.photoView.anchorTopCenter(withTopPadding: 0, width: self.contentView.width(), height: photoHeight)
        
        self.titleLabel.bounds.size.width = self.contentView.width() - 8
        self.titleLabel.sizeToFit()
        self.titleLabel.alignUnder(self.photoView, centeredFillingWidthWithLeftAndRightPadding: 4, topPadding: 4, height: self.titleLabel.height())
        
        self.badge.sizeToFit()
        self.badge.anchorTopRight(withRightPadding: 8, topPadding: 8, width: max(self.badge.width(), 22), height: 22)
        self.badge.layer.cornerRadius = self.badge.frame.size.height / 2
        self.badge.showShadow(offset: CGSize(width: 2, height: 4)
            , radius: 4.0
            , rounded: true
            , cornerRadius: self.badge.layer.cornerRadius)
        
        self.selectedBackgroundView?.fillSuperview()
    }
    
    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/
    
    func initialize() {
        self.clipsToBounds = true
        self.layer.cornerRadius = 4
        self.layer.borderWidth = 0.5
        self.layer.borderColor = Colors.gray80pcntColor.cgColor
        self.backgroundColor = Theme.colorBackgroundCell
        
        self.photoView.clipsToBounds = true
        self.photoView.contentMode = .scaleAspectFill
        self.photoView.backgroundColor = Theme.colorBackgroundForm
        
        self.titleLabel.font = Theme.fontCommentSmall
        self.titleLabel.textColor = Theme.colorText
        self.titleLabel.numberOfLines = 2
        self.titleLabel.textAlignment = .center
        
        self.badge.textColor = Colors.white
        self.badge.layer.backgroundColor = Theme.colorBackgroundBadge.cgColor
        self.badge.font = Theme.fontCommentSmall
        self.badge.textAlignment = .center
        self.badge.clipsToBounds = true
        
        self.contentView.addSubview(self.photoView)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.badge)
    }
    
    func bind(channel: FireChannel!, searching: Bool = false) {
        self.channel = channel
        self.titleLabel.text = channel.title!
        if let photo = channel.photo {
            self.photo = photo
            let url = ImageProxy.url(photo: photo, category: SizeCategory.profile)
            if !self.photoView.associated(withUrl: url) {
                self.photoView.setImageWithUrl(url: url, uploading: (photo.uploading != nil), animate: true)
            }
        }
        else {
            self.photoView.image = nil
            let seed = Utils.numberFromName(fullname: channel.title!.lowercased())
            self.photoView.backgroundColor = ColorArray.randomColor(seed: seed)
            self.photosQuery = PhotosQuery(channelId: channel.id!, limit: 1)
            self.photosQuery?.observe(with: { [weak self] error, photo in
                guard let this = self else { return }
                if error == nil {
                    if photo != nil {
                        let url = ImageProxy.url(photo: photo!, category: SizeCategory.profile)
                        if !this.photoView.associated(withUrl: url) {
                            this.photoView.setImageWithUrl(url: url, uploading: false, animate: true)
                        }
                    }
                }
            })
        }
        
        self.setNeedsLayout()    // Needed because binding can change element layout
        self.layoutIfNeeded()
        self.sizeToFit()
    }
    
    func reset() {
        self.photoView.reset()
        self.titleLabel.text = nil
        self.badge.text = "3"
        self.badge.alpha = 0
        self.badgeIsHidden = true
        self.channel = nil
        self.channelQuery?.remove()
        self.channelQuery = nil
        self.unreadQuery?.remove()
        self.unreadQuery = nil
        self.photosQuery?.remove()
        self.photosQuery = nil
    }
    
    override var layoutMargins: UIEdgeInsets {
        get { return UIEdgeInsets.zero }
        set (newVal) {}
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
