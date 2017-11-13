//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

@IBDesignable
class PresenceView: UIView {

    var online = false
    
    @IBInspectable var color: UIColor = Colors.accentColor {
        didSet {
            if online {
                showOnline()
            } else {
                showOffline()
            }
        }
    }

	override init(frame: CGRect) {
		/* Called when instantiated from code */
		super.init(frame: frame)
		initialize()
	}
	
	required init?(coder aDecoder: NSCoder) {
        /* Called when instantiated from nib/storyboard */
        super.init(coder: aDecoder)
        initialize()
	}
	
	func initialize() {
		
		self.clipsToBounds = true
        self.cornerRadius = 6
        showOffline()
	}
    
	override func layoutSubviews() {
		super.layoutSubviews()
	}
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        showOffline()
    }

	func bind(online: Any?) {
        if (online as? Bool) != nil {
            /* Set to true */
            showOnline()
        }
        else if (online as? Int64) != nil {
            /* Timestamp for when user went offline */
            showOffline()
        }
	}

    func showOnline() {
        self.layer.borderColor = Colors.clear.cgColor
        self.layer.borderWidth = 0
        self.layer.backgroundColor = self.color.cgColor
    }
    
    func showOffline() {
        self.layer.borderColor = self.color.cgColor
        self.layer.borderWidth = 1
        self.layer.backgroundColor = Colors.clear.cgColor
    }
}
