//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class AirSearchField: UITextField {
	
	var overlayButton: AirLinkButton {
        let overlayButton = AirLinkButton(frame: CGRect(x:0, y:0, width:96, height:40))
		overlayButton.setTitle("Cancel", for: .normal)
		overlayButton.addTarget(self, action: #selector(AirSearchField.cancelEditingAction(sender:)), for: .touchUpInside)
		return overlayButton
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
	
	func initialize() {
		
        let imageView = UIImageView(frame: CGRect(x:8, y:0, width:20, height:20))
		imageView.image = UIImage(named: "imgSearchLight")
		imageView.tintColor = Colors.accentColorDarker
		
        let searchView = UIView(frame: CGRect(x:0, y:0, width:40, height:40))
		searchView.alpha = 0.5
		searchView.addSubview(imageView)
		imageView.anchorInCenter(withWidth: 24, height: 24)
		
		self.font = Theme.fontText
		self.textColor = Theme.colorText
		self.layer.cornerRadius = CGFloat(Theme.dimenButtonCornerRadius)
		self.layer.masksToBounds = true
		self.layer.borderColor = Theme.colorButtonBorder.cgColor
		self.layer.borderWidth = Theme.dimenButtonBorderWidth
		self.leftViewMode = UITextFieldViewMode.always
		self.leftView = searchView
		self.rightView = self.overlayButton
		self.rightViewMode = UITextFieldViewMode.whileEditing
		self.clearButtonMode = UITextFieldViewMode.whileEditing
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		self.overlayButton.anchorCenterRight(withRightPadding: 8, width: 96, height: 48)
	}
	
	func cancelEditingAction(sender: AnyObject) {
		self.resignFirstResponder()
	}
}
