//
//  AirNavigationBar.swift
//  Teeny
//
//  Created by Jay Massena on 3/28/17.
//  Copyright © 2017 3meters. All rights reserved.
//

import Foundation

class AirNavigationBar: UINavigationBar {
    
    var navigationBarHeight: CGFloat = 44 {
        didSet {
            self.heightIncrease = CGFloat(self.navigationBarHeight - 44)
            var shift = self.heightIncrease / 2
            if UserDefaults.standard.bool(forKey: Prefs.statusBarHidden) {
                shift = 5
            }
            self.transform = CGAffineTransform(translationX: 0, y: -shift)
            self.setNeedsLayout()
        }
    }
    
    var heightIncrease = CGFloat(0)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    func initialize() {
        if UserDefaults.standard.bool(forKey: Prefs.statusBarHidden) {
            self.navigationBarHeight = CGFloat(74)
        }
        else {
            self.navigationBarHeight = CGFloat(54)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let shift = self.heightIncrease / 2
        var classNamesToReposition = ["_UINavigationBarBackground"]
        if #available(iOS 10.0, *) {
            classNamesToReposition = ["_UIBarBackground"]
        }
        
        for view: UIView in self.subviews {
            if classNamesToReposition.contains(NSStringFromClass(view.classForCoder)) {
                let bounds = self.bounds
                var frame = view.frame
                frame.origin.y = bounds.origin.y + shift - 20.0
                frame.size.height = bounds.size.height + 20.0
                view.frame = frame
            }
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let amendedSize = super.sizeThatFits(size)
        let newSize = CGSize(width: amendedSize.width, height: self.navigationBarHeight);
        return newSize
    }
}
