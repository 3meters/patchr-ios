//
//  UserTableViewCell.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-04-06.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

@objc
protocol UserApprovalViewDelegate {
    func userView(userView: UserApprovalView, approvalSwitchValueChanged approvalSwitch: UISwitch)
    func userView(userView: UserApprovalView, removeButtonTapped removeButton: UIButton)
}

class UserApprovalView: UserView {
    
    var entity:         Entity?
    weak var delegate:  UserApprovalViewDelegate?

    @IBOutlet weak var approved:        UILabel!
    @IBOutlet weak var approvedSwitch:  UISwitch!
    @IBOutlet weak var removeButton:    UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.removeButton.imageView?.contentMode = UIViewContentMode.Center
    }

    @IBAction func approvedSwitchValueChangedAction(sender: UISwitch) {
        self.delegate?.userView(self, approvalSwitchValueChanged: self.approvedSwitch)
    }

    @IBAction func removeButtonTouchUpInsideAction(sender: UIButton) {
        self.delegate?.userView(self, removeButtonTapped: self.removeButton)
    }
}
