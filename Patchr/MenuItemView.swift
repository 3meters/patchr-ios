//
//  Created by Jay Massena on 10/18/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class MenuItemView: BaseView {

	var name    = AirLabel()
    var photo   = UIImageView(frame: CGRect.zero)
    
	init() {
		super.init(frame: CGRect.zero)
		initialize()
	}
    
    init(title: String, image: UIImage) {
        super.init(frame: CGRect.zero)
        initialize()
        self.photo.image = image
        self.name.text = title
    }
	
	override init(frame: CGRect) {
		/* Called when instantiated from code */
		super.init(frame: frame)
		initialize()
	}
	
	required init?(coder aDecoder: NSCoder) {
		/* Called when instantiated from storyboard or nib */
		super.init(coder: aDecoder)
		initialize()
	}
	
	func initialize() {
		self.clipsToBounds = true
        self.name.font = Theme.fontTextDisplay
		self.addSubview(self.photo)
		self.addSubview(self.name)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		self.photo.anchorCenterLeft(withLeftPadding: 32, width: 24, height: 24)
		self.name.sizeToFit()
		self.name.align(toTheRightOf: self.photo, matchingCenterAndFillingWidthWithLeftAndRightPadding: 16, height: 64)
	}
}
