//
//  AirImageView.swift
//  Patchr
//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import CLTokenInputView

class AirTokenView: CLTokenInputView {
    
    var rule = UIView()
    var searchImage = AirImageView(frame: CGRect.zero)
    var placeholder = AirLabelDisplay()
    
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
        self.searchImage.image = UIImage(named: "imgSearchLight")
        self.searchImage.tintColor = Theme.colorTextPlaceholder
        self.rule.backgroundColor = Theme.colorRule
        
        self.addSubview(self.rule)
        self.addSubview(self.searchImage)
        self.addSubview(self.placeholder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.placeholder.sizeToFit()
        self.searchImage.anchorCenterLeft(withLeftPadding: 16, width: 16, height: 16)
        self.placeholder.align(toTheRightOf: self.searchImage, matchingCenterWithLeftPadding: 8, width: self.placeholder.width(), height: self.placeholder.height())
        self.rule.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: Theme.dimenRuleThickness)
    }
    
    func editingBegin() {
        self.rule.backgroundColor = Theme.colorRuleActive
        self.searchImage.fadeOut(duration: 0.2)
        self.placeholder.fadeOut(duration: 0.2)
    }
    
    func editingEnd() {
        self.rule.backgroundColor = Theme.colorRule
        self.searchImage.fadeIn(duration: 0.2)
        self.placeholder.fadeIn(duration: 0.2)
    }
    
    override func add(_ token: CLToken) {
        super.add(token)
        if self.allTokens.count > 0 {
            self.searchImage.fadeOut(duration: 0.0)
            self.placeholder.fadeOut(duration: 0.0)
        }
    }
}
