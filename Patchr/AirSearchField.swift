//
//  AirTextField.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class AirSearchField: UITextField {
	
	var overlayButton: AirButtonLink {
		let overlayButton = AirButtonLink(frame: CGRectMake(0, 0, 96, 40))
		overlayButton.setTitle("Cancel", forState: .Normal)
		overlayButton.addTarget(self, action: Selector("cancelEditingAction:"), forControlEvents: .TouchUpInside)
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
		
		let imageView = UIImageView(frame: CGRectMake(8, 0, 20, 20))
		imageView.image = UIImage(named: "imgSearchLight")
		
		let searchView = UIView(frame: CGRectMake(0, 0, 40, 40))
		searchView.alpha = 0.5
		searchView.addSubview(imageView)
		imageView.anchorInCenterWithWidth(24, height: 24)
		
		self.font = Theme.fontText
		self.textColor = Theme.colorText
		self.layer.cornerRadius = CGFloat(Theme.dimenButtonCornerRadius)
		self.layer.masksToBounds = true
		self.layer.borderColor = Theme.colorButtonBorder.CGColor
		self.layer.borderWidth = Theme.dimenButtonBorderWidth
		self.leftViewMode = UITextFieldViewMode.Always
		self.leftView = searchView
		self.rightView = self.overlayButton
		self.rightViewMode = UITextFieldViewMode.WhileEditing
		self.clearButtonMode = UITextFieldViewMode.WhileEditing
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		self.overlayButton.anchorCenterRightWithRightPadding(8, width: 96, height: 48)
	}
	
	func cancelEditingAction(sender: AnyObject) {
		self.resignFirstResponder()
	}
}