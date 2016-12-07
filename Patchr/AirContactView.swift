//
//  AirImageView.swift
//  Patchr
//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import CLTokenInputView

class AirContactView: CLTokenInputView {
    
    var rule = UIView()
    
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
    
    func initialize() {
        NotificationCenter.default.addObserver(self, selector: #selector(editingBegin(notification:)), name: NSNotification.Name.UITextFieldTextDidBeginEditing, object: nil)
        self.rule.backgroundColor = Theme.colorRule
        self.drawBottomBorder = true
        self.addSubview(self.rule)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.rule.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: Theme.dimenRuleThickness)
    }
    
    func editingBegin(notification: NSNotification) {
        if let textField = notification.object as? UITextField {
            if textField == self {
                self.rule.backgroundColor = Theme.colorRuleActive
            }
            else {
                self.rule.backgroundColor = Theme.colorRule
            }
        }
    }
}
