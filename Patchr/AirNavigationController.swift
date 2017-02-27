//
//  AirNavigationController.swift
//  Patchr
//
//  Created by Jay Massena on 5/20/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import UIKit

class AirNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

class AirNavigationBar: UINavigationBar {
    
    static let navigationBarHeight = CGFloat(54)
    static let heightIncrease = CGFloat(navigationBarHeight - 44)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        let shift = AirNavigationBar.heightIncrease / 2
        self.transform = CGAffineTransform(translationX: 0, y: -shift)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let shift = AirNavigationBar.heightIncrease / 2
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
        let newSize = CGSize(width: amendedSize.width, height: AirNavigationBar.navigationBarHeight);
        return newSize
    }
}
