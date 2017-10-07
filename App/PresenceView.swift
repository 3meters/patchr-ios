//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

@IBDesignable
class PresenceView: UIView {

    var label = AirLabelDisplay()
	var indicator = UIView(frame: CGRect.zero)
    var target: AnyObject?
    
    @IBInspectable var rounded: Bool = true {
        didSet {
            self.layer.cornerRadius = self.rounded ? self.width() * 0.5 : self.radius
        }
    }
    
    @IBInspectable var radius: CGFloat = 0 {
        didSet {
            self.layer.cornerRadius = self.radius
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

		/* Time interval since went offline */
		self.label.font = Theme.fontCommentExtraSmall
		self.label.textColor = Colors.white
		self.label.textAlignment = .center
        self.label.isHidden = true
        
        showOffline()

		self.addSubview(self.indicator)
        self.addSubview(self.label)
	}
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
    }
    
	override func layoutSubviews() {
		super.layoutSubviews()
        self.indicator.layer.cornerRadius = self.rounded ? self.width() * 0.5 : self.radius
		self.indicator.fillSuperview()
		self.label.fillSuperview()
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
        self.indicator.layer.borderColor = Colors.clear.cgColor
        self.indicator.layer.borderWidth = 0
        self.indicator.layer.backgroundColor = Colors.accentColor.cgColor
    }
    
    func showOffline() {
        self.indicator.layer.borderColor = Colors.accentColor.cgColor
        self.indicator.layer.borderWidth = 1
        self.indicator.layer.backgroundColor = Colors.clear.cgColor
    }
}
