//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import Facade

class AirUIView: UIView {
	
    var hitInsets: UIEdgeInsets = UIEdgeInsets.zero
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let newRect = CGRect(x: 0 + hitInsets.left,
                             y: 0 + hitInsets.top,
                             width: self.frame.size.width - hitInsets.left - hitInsets.right,
                             height: self.frame.size.height - hitInsets.top - hitInsets.bottom)
        
        return newRect.contains(point)
    }
}
