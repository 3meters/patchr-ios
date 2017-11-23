//
//  CaptionView.swift
//  Patchr
//
//  Created by Jay Massena on 5/12/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import UIKit
import IDMPhotoBrowser

class CommentView: UIView {
	
    @IBOutlet weak var photoControl: PhotoControl!
    @IBOutlet weak var usernameLabel: AirLabel!
    @IBOutlet weak var createdDateLabel: AirLabel!
    @IBOutlet weak var textLabel: AirLabel!
    
    var maxWidth = CGFloat(0)
    var inputUserQuery: UserQuery!
    
    required init(coder aDecoder: NSCoder) {
        /* Called when instantiated from XIB or Storyboard */
        super.init(coder: aDecoder)!
        initialize()
    }
    
    override init(frame: CGRect) {
        /* Called when instantiated from code */
        super.init(frame: frame)
        initialize()
    }
    
    func initialize() {}
    
    func bind(comment: FireMessage) {
        
        if let text = comment.text {
            self.textLabel?.isHidden = false
            self.textLabel?.text = text
        }

        if let user = comment.creator {
            /* Username */
            self.usernameLabel.text = user.username
            
            /* User photo */
            if let profilePhoto = user.profile?.photo {
                let url = ImageProxy.url(photo: profilePhoto, category: SizeCategory.profile)
                if !self.photoControl.imageView.associated(withUrl: url) {
                    let fullName = user.title
                    self.photoControl.imageView.image = nil
                    self.photoControl.bind(url: url, name: fullName, colorSeed: user.id)
                }
            }
            else {
                let fullName = user.title
                self.photoControl.bind(url: nil, name: fullName, colorSeed: user.id)
            }
        }
        else {
            self.usernameLabel.text = "deleted".localized()
            self.photoControl.bind(url: nil, name: "deleted".localized(), colorSeed: nil, color: Theme.colorBackgroundImage)
        }

        /* Created date */
        let createdAtDate = DateUtils.from(timestamp: comment.createdAt!)
        self.createdDateLabel.text = createdAtDate.shortTimeAgo(since: Date())
        self.setNeedsUpdateConstraints()
    }
	
    override public var intrinsicContentSize: CGSize {
        self.textLabel.bounds.size.width = maxWidth - (32 + 16)
        
        self.textLabel.sizeToFit()
        self.usernameLabel.sizeToFit()
        self.createdDateLabel.sizeToFit()

        let firstWidth = 32 + 16 + self.usernameLabel.width() + 8 + self.createdDateLabel.width() + 8
        let secondWidth = 32 + 16 + self.textLabel.width()
        let preferredWidth = max(firstWidth, secondWidth)
        
        let size = CGSize(width: preferredWidth, height: 19 + self.textLabel.height() + 8)
        return size
    }

//    override func sizeThatFits(_ size: CGSize) -> CGSize {
//        self.bounds.size.width = size.width
//        self.setNeedsLayout()
//        self.layoutIfNeeded()
//        var size = sizeThatFitsSubviews()
//        size.height += 16
//        return size
//    }
}
