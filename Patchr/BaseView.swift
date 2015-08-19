//
//  BaseView.swift
//  Patchr
//
//  Created by Jay Massena on 8/6/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation

protocol ViewDelegate: NSObjectProtocol {
    func view(container: UIView, didTapOnView view: UIView)
}

class BaseView: UIView {
    var cell: UITableViewCell?    
    
    func updatePreferredMaxLayoutWidth(label: UILabel) -> Void {
        label.preferredMaxLayoutWidth = CGRectGetWidth(label.frame)
    }
}