//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

@IBDesignable
class AirLabelBase: UILabel {
	
    @IBInspectable open var dummyText: String?
    @IBInspectable open var showShadow: Bool {
        set {
            if newValue {
                self.showShadow(offset: CGSize(width: 2, height: 3)
                    , radius: 3.0
                    , rounded: true
                    , cornerRadius: self.layer.cornerRadius)
            }
            else {
                self.removeShadow()
            }
        }
        get {
            return (self.shadowOffset.width > 0)
        }
    }
    
    var insets = UIEdgeInsets.zero
    
    @IBInspectable open var bottomInset: CGFloat = 0
    @IBInspectable open var leftInset: CGFloat = 0
    @IBInspectable open var rightInset: CGFloat = 0
    @IBInspectable open var topInset: CGFloat = 0
    
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
        let insets = UIEdgeInsets(top: self.topInset, left: self.leftInset, bottom: self.bottomInset, right: self.rightInset)
		super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
	}
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.text = dummyText
    }
    
    override public var intrinsicContentSize: CGSize {
        var intrinsicSuperViewContentSize = super.intrinsicContentSize
        intrinsicSuperViewContentSize.height += (topInset + bottomInset)
        intrinsicSuperViewContentSize.width += (leftInset + rightInset)
        return intrinsicSuperViewContentSize
    }
    
	func initialize() {	}
}
