//
//  AirButtonBase.swift
//  Patchr
//
//  Created by Jay Massena on 1/3/17.
//  Copyright © 2017 3meters. All rights reserved.
//

import Foundation

class AirButtonBase: UIButton {
    
    var hitInsets = UIEdgeInsets.zero
    var data: AnyObject?
    
    convenience init(frame: CGRect, hitInsets: UIEdgeInsets = .zero) {
        self.init(frame: frame)
        self.hitInsets = hitInsets
    }

    required init(coder aDecoder: NSCoder) {
        /* Called when instantiated from XIB or Storyboard */
        super.init(coder: aDecoder)!
    }
    
    override init(frame: CGRect) {
        /* Called when instantiated from code */
        super.init(frame: frame)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if !super.point(inside: point, with: event) {
            let relativeFrame = self.bounds
            let hitTestEdgeInsets = self.hitInsets
            let hitFrame = UIEdgeInsetsInsetRect(relativeFrame, hitTestEdgeInsets)
            Log.v("Hit test: \(hitFrame.contains(point))")
            return hitFrame.contains(point)
        }
        return true
        
//        let newRect = CGRect(x: 0 + hitInsets.left,
//                             y: 0 + hitInsets.top,
//                             width: self.frame.size.width - hitInsets.left - hitInsets.right,
//                             height: self.frame.size.height - hitInsets.top - hitInsets.bottom)
//        let hit = newRect.contains(point)
//        return hit
    }
}
