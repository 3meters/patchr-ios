//
//  UserTableViewCell.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-04-06.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

@objc
protocol UserTableViewCellDelegate {
    //optional func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool
    optional func userTableViewCell(userTableViewCell: UserTableViewCell, approvalSwitchValueChanged approvalSwitch: UISwitch)
    optional func userTableViewCell(userTableViewCell: UserTableViewCell, removeButtonTapped removeButton: UIButton)
}

class UserTableViewCell: UITableViewCell {

    @IBOutlet weak var userPhoto: AirImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var area: UILabel!
    @IBOutlet weak var owner: UILabel!
    @IBOutlet weak var approved: UILabel!
    @IBOutlet weak var approvedSwitch: UISwitch!
    @IBOutlet weak var removeButton: UIButton!

    weak var delegate: UserTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.removeButton.imageView?.contentMode = UIViewContentMode.Center
    }

    @IBAction func approvedSwitchValueChangedAction(sender: UISwitch) {
        self.delegate?.userTableViewCell?(self, approvalSwitchValueChanged: self.approvedSwitch)
    }

    @IBAction func removeButtonTouchUpInsideAction(sender: UIButton) {
        self.delegate?.userTableViewCell?(self, removeButtonTapped: self.removeButton)
    }
}
