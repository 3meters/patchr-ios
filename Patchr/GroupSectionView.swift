//
//  Created by Jay Massena on 7/15/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import UIKit

public protocol SectionToggledDelegate: NSObjectProtocol {
    func toggled(expanded: Bool, target: UIView) -> Void
}

@IBDesignable
class GroupSectionView: UITableViewHeaderFooterView {

    weak open var delegate: SectionToggledDelegate?

    @IBOutlet weak var photoView: PhotoView?
    @IBOutlet weak var title: UILabel?
    @IBOutlet weak var subtitle: UILabel?
    @IBOutlet weak var badge: UILabel?
    @IBOutlet weak var expando: UIImageView!
    @IBOutlet weak var buttonScrim: AirScrimButton?
    
    var rule = UIView()
    
    var group: FireGroup!
    var expanded = false
    var section = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        initialize()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.badge?.layer.cornerRadius = (self.badge?.frame.size.width)! / 2
        self.rule.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 1)
        self.buttonScrim?.fillSuperview()
    }
    
    func toggleAction(sender: AnyObject?) {
        setExpanded(expanded: !self.expanded)
    }
    
    func initialize() {
        self.rule.backgroundColor = Colors.white
        self.addSubview(self.rule)
        self.buttonScrim?.addTarget(self, action: #selector(toggleAction(sender:)), for: .touchUpInside)
    }
    
    func setExpanded(expanded: Bool) {
        self.expando.rotate(expanded ? CGFloat(M_PI_2) : CGFloat(0.0))
        self.expanded = expanded
        self.delegate?.toggled(expanded: self.expanded, target: self)
    }
    
    func reset() {
        self.delegate = nil
        self.photoView?.photoView.image = nil
        self.title?.text = nil
        self.subtitle?.text = nil
        self.badge?.backgroundColor = Theme.colorBackgroundBadge
        self.badge?.text = nil
        self.badge?.isHidden = true
        self.group = nil
    }
    
    func bind(group: FireGroup) {
        self.group = group
        self.title?.text = group.title!
        self.subtitle?.text = "\(group.role!)"
        
        if let photo = group.photo, photo.uploading == nil {
            let photoUrl = PhotoUtils.url(prefix: photo.filename!, source: photo.source!, category: SizeCategory.profile)
            self.photoView?.bind(url: photoUrl, fallbackUrl: PhotoUtils.fallbackUrl(prefix: photo.filename!), name: nil, colorSeed: group.id)
        }
        else {
            self.photoView?.bind(url: nil, fallbackUrl: nil, name: group.title, colorSeed: group.id)
        }
    }
}
