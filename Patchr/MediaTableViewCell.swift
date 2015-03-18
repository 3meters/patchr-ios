//
//  MediaTableViewCell.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

protocol TableViewCellDelegate: NSObjectProtocol {
    func tableViewCell(cell: UITableViewCell, didTapOnView view: UIView)
}

class MediaTableViewCell: UITableViewCell {
    
    @IBOutlet weak var userAvatarImageView: UIImageView!
    @IBOutlet weak var createdDateLabel: UILabel!
    @IBOutlet weak var messageBodyLabel: UILabel!
    @IBOutlet weak var messageImageView: UIImageView!
    
    @IBOutlet weak var messageImageContainerHeight: NSLayoutConstraint!
    
    weak var delegate: TableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "tapGestureRecognizerAction:")
        self.messageImageView.addGestureRecognizer(tapGestureRecognizer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.setNeedsLayout()
        self.contentView.layoutIfNeeded()
        
        updatePreferredMaxLayoutWidth(self.createdDateLabel)
        updatePreferredMaxLayoutWidth(self.messageBodyLabel)
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
