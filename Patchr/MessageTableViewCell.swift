//
//  MessageTableViewCell.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-12.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

// TODO: Create a more generic protocol. This is basically the same as NotificationTableViewCellDelegate.
//  func tableViewCell(cell: UITableViewCell, didTapOnView view: UIView)
protocol MessageTableViewCellDelegate: NSObjectProtocol {
    func tableViewCell(cell: MessageTableViewCell, didTapOnView view: UIView)
}

class MessageTableViewCell: UITableViewCell {
    
    @IBOutlet weak var patchNameLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userAvatarImageView: UIImageView!
    @IBOutlet weak var createdDateLabel: UILabel!
    @IBOutlet weak var messageBodyLabel: UILabel!
    @IBOutlet weak var messageImageView: UIImageView!
    @IBOutlet weak var likesLabel: UILabel!

    @IBOutlet weak var messageImageContainerHeight: NSLayoutConstraint!
    
    weak var delegate: MessageTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "tapGestureRecognizerAction:")
        self.messageImageView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.setNeedsLayout()
        self.contentView.layoutIfNeeded()
        
        updatePreferredMaxLayoutWidth(self.patchNameLabel)
        updatePreferredMaxLayoutWidth(self.userNameLabel)
        updatePreferredMaxLayoutWidth(self.createdDateLabel)
        updatePreferredMaxLayoutWidth(self.messageBodyLabel)
        updatePreferredMaxLayoutWidth(self.likesLabel)
    }
    
    // MARK: Private Internal
    
    func tapGestureRecognizerAction(sender: AnyObject) {
        if sender.view != nil {
            self.delegate?.tableViewCell(self, didTapOnView: sender.view!)
        }
    }
    
    func updatePreferredMaxLayoutWidth(label: UILabel) -> Void {
        label.preferredMaxLayoutWidth = CGRectGetWidth(label.frame)
    }
    
}
