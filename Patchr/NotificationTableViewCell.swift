//
//  NotificationTableViewCell.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-24.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

protocol NotificationTableViewCellDelegate: NSObjectProtocol {
    func tableViewCell(cell: NotificationTableViewCell, didTapOnView view: UIView)
}

class NotificationTableViewCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var notificationImageView: UIImageView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var notificationImageMaxHeightConstraint: NSLayoutConstraint!
    
    weak var delegate: NotificationTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "tapGestureRecognizerAction:")
        self.notificationImageView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    // MARK: Private Internal
    
    func tapGestureRecognizerAction(sender: AnyObject) {
        if sender.view != nil {
            self.delegate?.tableViewCell(self, didTapOnView: sender.view!)
        }
    }
}
