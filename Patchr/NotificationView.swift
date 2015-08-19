//
//  NotificationTableViewCell.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-24.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class NotificationView: BaseView {

    var entity: Entity?
    
    @IBOutlet weak var createdDate: UILabel!
    @IBOutlet weak var userPhoto: AirImageView!
    @IBOutlet weak var description_: UILabel!
    @IBOutlet weak var photo: AirImageView!
    @IBOutlet weak var photoHeight: NSLayoutConstraint!
    @IBOutlet weak var photoTopSpace: NSLayoutConstraint!    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var ageDot: UIView!
    
    weak var delegate: ViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "tapGestureRecognizerAction:")
        self.photo.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    // MARK: Private Internal
    
    func tapGestureRecognizerAction(sender: AnyObject) {
        if sender.view != nil && self.delegate != nil {
            self.delegate!.view(self, didTapOnView: sender.view!!)
        }
    }
}
