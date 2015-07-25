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
    
    var entity: Entity?
    
    @IBOutlet weak var userPhoto: AirImageView!
    @IBOutlet weak var createdDate: UILabel!
    @IBOutlet weak var description_: TTTAttributedLabel!
    @IBOutlet weak var photo: AirImageView!
    @IBOutlet weak var photoHeight: NSLayoutConstraint!
    @IBOutlet weak var photoTopSpace: NSLayoutConstraint!
    
    weak var delegate: TableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "tapGestureRecognizerAction:")
        self.photo.addGestureRecognizer(tapGestureRecognizer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.contentView.setNeedsLayout()
        self.contentView.layoutIfNeeded()
        
        updatePreferredMaxLayoutWidth(self.createdDate)
        updatePreferredMaxLayoutWidth(self.description_)
    }
    
    // MARK: Private Internal
    
    func tapGestureRecognizerAction(sender: AnyObject) {
        if sender.view != nil {
            self.delegate?.tableViewCell(self, didTapOnView: sender.view!!)
        }
    }
    
    func updatePreferredMaxLayoutWidth(label: UILabel) -> Void {
        label.preferredMaxLayoutWidth = CGRectGetWidth(label.frame)
    }
}
