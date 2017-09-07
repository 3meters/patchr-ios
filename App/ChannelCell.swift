//
//  Created by Jay Massena on 7/15/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import FirebaseDatabase
import Foundation
import UIKit

@IBDesignable
class ChannelCell: UICollectionViewCell {
    
    @IBOutlet weak var badge: UILabel?
    @IBOutlet weak var photoView: AirImageView?
    @IBOutlet weak var titleLabel: UILabel?
    
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
        self.badge?.layer.cornerRadius = (self.badge?.frame.size.height)! / 2
        self.selectedBackgroundView?.fillSuperview()
    }
    
    func initialize() {
        self.clipsToBounds = true
        self.badge?.backgroundColor = Theme.colorBackgroundBadge
        self.backgroundColor = Theme.colorBackgroundCell
    }
    
    func reset() {
        self.photoView?.reset()
        self.titleLabel?.text = nil
        self.badge?.backgroundColor = Theme.colorBackgroundBadge
        self.badge?.text = nil
        self.badge?.isHidden = true
        self.channel = nil
        self.channelQuery?.remove()
        self.channelQuery = nil
        self.unreadQuery?.remove()
        self.unreadQuery = nil
        self.photosQuery?.remove()
        self.photosQuery = nil
    }
    
    func bind(channel: FireChannel, searching: Bool = false) {
        self.channel = channel
        self.titleLabel?.text = channel.title!
        if let photo = channel.photo {
            self.photo = photo
            let url = ImageProxy.url(photo: photo, category: SizeCategory.profile)
            if !(self.photoView?.associated(withUrl: url))! {
                self.photoView?.setImageWithUrl(url: url, uploading: (photo.uploading != nil), animate: true)
            }
        }
        else {
            self.photoView?.image = nil
            let seed = Utils.numberFromName(fullname: channel.title!.lowercased())
            self.photoView?.backgroundColor = ColorArray.randomColor(seed: seed)
            self.photosQuery = PhotosQuery(channelId: channel.id!, limit: 1)
            self.photosQuery?.observe(with: { error, photo in
                if error == nil {
                    if photo != nil {
                        let url = ImageProxy.url(photo: photo!, category: SizeCategory.profile)
                        if !(self.photoView?.associated(withUrl: url))! {
                            self.photoView?.setImageWithUrl(url: url, uploading: false, animate: true)
                        }
                    }
                }
            })
        }
        
        self.setNeedsLayout()    // Needed because binding can change element layout
        self.layoutIfNeeded()
        self.sizeToFit()
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

enum SelectedStyle: Int {
    case prominent
    case normal
    case minimal
}
