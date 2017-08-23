//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class AirLabelBase: UILabel {
	
	var insets = UIEdgeInsets.zero
    
    convenience init(text: String?) {
        self.init(frame: CGRect.zero)
        self.text = text
        self.sizeToFit()
    }
    
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
	
	override func drawText(in rect: CGRect) -> Void {
		super.drawText(in: UIEdgeInsetsInsetRect(rect, self.insets))
	}
    
	func initialize() {	}
}