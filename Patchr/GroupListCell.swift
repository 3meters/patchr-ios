//
//  Created by Jay Massena on 7/15/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class GroupListCell: UITableViewCell {
    
    @IBOutlet weak var photoControl: PhotoControl?
    @IBOutlet weak var title: UILabel?
    @IBOutlet weak var subtitle: UILabel?
    @IBOutlet weak var badge: UILabel?
    
    var group: FireGroup!
    var selectedOn = false
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.badge?.layer.cornerRadius = (self.badge?.frame.size.height)! / 2
    }
    
    func initialize() {
        self.badge?.backgroundColor = Theme.colorBackgroundBadge
    }
    
    func selected(on: Bool) {
        self.selectedOn = on
        if on {
            self.backgroundColor = Theme.colorBackgroundSelected
            self.title?.font = UIFont(name: "HelveticaNeue-Medium", size: (self.title?.font.pointSize)!)
            self.subtitle?.textColor = Colors.black
            self.layer.borderColor = Colors.gray80pcntColor.cgColor
            self.layer.borderWidth = 1.0
            self.accessoryType = self.badge!.isHidden ? .checkmark : .none
        }
        else {
            self.backgroundColor = Colors.white
            self.title?.font = UIFont(name: "HelveticaNeue-Light", size: (self.title?.font.pointSize)!)
            self.subtitle?.textColor = Theme.colorTextSecondary
            self.layer.borderColor = Colors.clear.cgColor
            self.layer.borderWidth = 0.0
            self.accessoryType = .none
        }
    }
    
    func reset() {
        selected(on: false)
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

        let groupId = group.id!
        let userId = UserController.instance.userId!
        UnreadQuery(level: .group, userId: userId, groupId: groupId).observe(with: { total in
            if total > 0 {
                self.badge?.text = "\(total)"
                self.badge?.isHidden = false
                self.accessoryType = .none
            }
            else {
                self.badge?.isHidden = true
                self.accessoryType = self.selectedOn ? .checkmark : .none
            }
        })
        
        if let photo = group.photo {
            if photo.uploading != nil {
                self.photoControl?.bind(url: URL(string: photo.cacheKey)!, fallbackUrl: nil, name: nil, colorSeed: nil, uploading: true)
            }
            else {
                if let url = ImageUtils.url(prefix: photo.filename!, source: photo.source!, category: SizeCategory.profile) {
                    let fallbackUrl = ImageUtils.fallbackUrl(prefix: photo.filename!)
                    self.photoControl!.bind(url: url, fallbackUrl: fallbackUrl , name: nil, colorSeed: group.id)
                }
            }
        }
        else {
            self.photoControl!.bind(url: nil, fallbackUrl: nil, name: group.title, colorSeed: group.id)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        let colorPhoto = self.photoControl?.backgroundColor
        super.setSelected(selected, animated: animated)
        self.photoControl?.backgroundColor = colorPhoto
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let colorPhoto = self.photoControl?.backgroundColor
        super.setHighlighted(highlighted, animated: animated)
        self.photoControl?.backgroundColor = colorPhoto
    }
    
}
