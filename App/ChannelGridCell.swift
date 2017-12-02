//
//  Created by Jay Massena on 7/15/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import FirebaseDatabase
import Foundation
import UIKit
import ChameleonFramework

@IBDesignable
class ChannelGridCell: UICollectionViewCell {
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var imageView: AirImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    
    var badgeIsHidden = true {
        didSet {
            if badgeIsHidden {
                self.badgeLabel?.fadeOut()
            }
            else {
                self.badgeLabel?.fadeIn()
            }
        }
    }
    
    var photo: FirePhoto!

    var channel: FireChannel!
    var unreadQuery: UnreadQuery? // Passed in by table data source
    var channelQuery: ChannelQuery? // Passed in by table data source
    var photosQuery: PhotosQuery?
    var selectedOn = false
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.selectedBackgroundView?.fillSuperview()
    }
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Methods
     *--------------------------------------------------------------------------------------------*/
    
    func bind(channel: FireChannel!, searching: Bool = false) {
        self.channel = channel
        self.titleLabel?.text = channel.title!
        
        FireController.instance.messageCount(channelId: channel.id!, then: { [weak self] error, count in
            guard let this = self else { return }
            if error == nil {
                this.countLabel?.text = "\(count)"
            }
        })
        
        if let photoView = self.imageView {
            if let photo = channel.photo {
                self.photo = photo
                let url = ImageProxy.url(photo: photo, category: SizeCategory.profile)
                if !photoView.associated(withUrl: url) {
                    photoView.setImageWithUrl(url: url, uploading: (photo.uploading != nil), animate: true) { success in
                        if success {
                            if let image = photoView.image {
                                let colorImageAverage = AverageColorFromImage(image).lighten(byPercentage: 0.5)
                                let colorText = ContrastColorOf(colorImageAverage!, returnFlat: true)
                                self.contentView.backgroundColor = colorImageAverage
                                self.countLabel.textColor = Colors.white
                                self.titleLabel?.textColor = colorText
                            }
                        }
                    }
                }
            }
            else {
                photoView.image = nil
                //let seed = Utils.numberFromName(fullname: channel.title!.lowercased())
                //photoView.backgroundColor = ColorArray.randomColor(seed: seed)
                self.photosQuery = PhotosQuery(channelId: channel.id!, limit: 1)
                self.photosQuery?.observe(with: { [weak photoView] error, photo in
                    if error == nil {
                        if photo != nil {
                            let url = ImageProxy.url(photo: photo!, category: SizeCategory.profile)
                            if !photoView!.associated(withUrl: url) {
                                photoView!.setImageWithUrl(url: url, uploading: false, animate: true) { success in
                                    if success {
                                        if let image = photoView!.image {
                                            let colorImageAverage = AverageColorFromImage(image).lighten(byPercentage: 0.5)
                                            let colorText = ContrastColorOf(colorImageAverage!, returnFlat: true)
                                            self.contentView.backgroundColor = colorImageAverage
                                            self.countLabel.textColor = Colors.white
                                            self.titleLabel?.textColor = colorText
                                        }
                                    }
                                }
                            }
                        }
                    }
                })
            }
        }
    }
    
    func reset() {
        self.imageView?.reset()
        self.titleLabel?.text = nil
        self.countLabel?.text = nil
        self.badgeLabel?.text = nil
        self.badgeLabel?.alpha = 0
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
