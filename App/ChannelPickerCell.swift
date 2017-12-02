//
//  Created by Jay Massena on 7/15/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable class ChannelPickerCell: UITableViewCell {
    
    @IBOutlet weak var coverImageView: AirImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var photo: FirePhoto!
    var needsPhoto = false
    
    var channel: FireChannel!
    var channelQuery: ChannelQuery? // Passed in by table data source

    override var layoutMargins: UIEdgeInsets {
        get { return .zero }
        set (newVal) {}
    }

    /*--------------------------------------------------------------------------------------------
     * MARK: - Events
     *--------------------------------------------------------------------------------------------*/

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.titleLabel?.text = "Bilbo Massena"
    }

    /*--------------------------------------------------------------------------------------------
     * MARK: - Methods
	 *--------------------------------------------------------------------------------------------*/

    func reset() {
        self.coverImageView?.reset()
        self.titleLabel?.text = nil
        self.channel = nil
        self.channelQuery?.remove()
        self.channelQuery = nil
    }

    func bind(channel: FireChannel) {
        self.channel = channel
        self.titleLabel?.text = channel.title!
        if let photo = channel.photo {
            self.photo = photo
            self.needsPhoto = true
            let url = ImageProxy.url(photo: photo, category: SizeCategory.profile)
            if !(self.coverImageView?.associated(withUrl: url))! {
                self.coverImageView?.setImageWithUrl(url: url, uploading: (photo.uploading != nil), animate: true) { success in
                    if success {
                        self.needsPhoto = false
                    }
                }
            }
        }
        else {
            self.coverImageView?.image = nil
            let seed = Utils.numberFromName(fullname: channel.title!.lowercased())
            self.coverImageView?.backgroundColor = ColorArray.randomColor(seed: seed)
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
