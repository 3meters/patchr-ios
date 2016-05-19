//
//  AirButton.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import pop

class AirRadialMenu: CKRadialMenu  {
	
	var imageView			= UIImageView()
	var imageInsets			= UIEdgeInsetsMake(10, 10, 10, 10)
	var parentView			: UIView!
	var contentView			: UIView!
	var blurVisualEffect	: UIVisualEffectView!
	var title				= AirLabelTitle()
	var message				= AirLabelDisplay()
	var showBackground		= true
	
	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
	
	required init(coder aDecoder: NSCoder) {
		/* Called when instantiated from XIB or Storyboard */
		super.init(coder: aDecoder)!
		initialize()
	}
	
	internal init(attachedToView view: UIView) {
		super.init(frame: CGRectZero)
		self.parentView = view
		initialize()
	}
	
	/*--------------------------------------------------------------------------------------------
	* Events
	*--------------------------------------------------------------------------------------------*/
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		let titleSize = self.title.sizeThatFits(CGSizeMake(288, CGFloat.max))
		let messageSize = self.message.sizeThatFits(CGSizeMake(288, CGFloat.max))
		let availableHeight = self.parentView.height() - 144
		let contentHeight = titleSize.height + messageSize.height + 12
		let topLayoutGuide = (availableHeight - contentHeight) / 2
		
		self.title.anchorTopCenterWithTopPadding(topLayoutGuide, width: 288, height: titleSize.height)
		self.message.alignUnder(self.title, matchingCenterWithTopPadding: 12, width: 288, height: messageSize.height)
		
		self.centerView.layer.cornerRadius = self.bounds.width / 2
		self.imageView.fillSuperviewWithLeftPadding(self.imageInsets.left
			, rightPadding: self.imageInsets.right
			, topPadding: self.imageInsets.top
			, bottomPadding: self.imageInsets.bottom)
	}
	
	func backgroundTapped(gester: UIGestureRecognizer) {
		toggleOff()
		self.retract()
	}
	
	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		
		self.centerView.backgroundColor = Colors.accentColor
		self.imageView.tintColor = Colors.white
		self.centerView.addSubview(self.imageView)
		self.clipsToBounds = false
		
		self.contentView = UIView(frame: self.parentView.bounds)
		self.blurVisualEffect = UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight))
		self.blurVisualEffect.frame = self.contentView.frame
		
		self.title.text = "Getting together? Make a patch so everyone can share photos, messages and stay connected."
		self.title.numberOfLines = 0
		self.title.textAlignment = .Center
		
		self.message.text = "Patches are perfect for any event, place, trip or interest.\n\nMasterpiece or experiment, patches are always easy to update or delete. Select a patch type below and get started!"
		self.message.numberOfLines = 0
		self.message.textAlignment = .Center
		
		let titleSize = self.title.sizeThatFits(CGSizeMake(288, CGFloat.max))
		let messageSize = self.message.sizeThatFits(CGSizeMake(288, CGFloat.max))
		let availableHeight = self.parentView.height() - 144
		let contentHeight = titleSize.height + messageSize.height + 12
		let topLayoutGuide = (availableHeight - contentHeight) / 2
		
		if topLayoutGuide < 48 {
			self.message.text = "Patches are perfect for any event, place, trip or interest. Select a patch type below and get started!"
		}
		
		self.contentView.addSubview(self.blurVisualEffect)
		self.blurVisualEffect.contentView.addSubview(self.title)
		self.blurVisualEffect.contentView.addSubview(self.message)
		
		let tap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(_:)))
		self.contentView.addGestureRecognizer(tap)
	}
	
	func toggleOn() {
		
		if !self.menuIsExpanded {
			expand()
			if self.showBackground {
				showBlur()
			}
			UIView.animateWithDuration(0.5
				, delay: 0
				, usingSpringWithDamping: 0.55
				, initialSpringVelocity: 0.3
				, options: [.CurveEaseInOut]
				, animations: {
					self.imageView.layer.transform = CATransform3DMakeRotation(self.degreesToRadians(135), CGFloat(0.01), CGFloat(0.01), CGFloat(1.0))
				}, completion: nil)
		}
	}
	
	func toggleOff() {
		
		if self.menuIsExpanded {
			retract()
			if self.showBackground {
				self.hideBlur()
			}
			UIView.animateWithDuration(0.5
				, delay: 0
				, usingSpringWithDamping: 0.6
				, initialSpringVelocity: 0.8
				, options: []
				, animations: {
					self.imageView.layer.transform = CATransform3DMakeRotation(self.degreesToRadians(0), CGFloat(0.01), CGFloat(0.01), CGFloat(1.0))
			}) {
				completed in
			}
		}
	}
	
	func showBlur() {
		self.contentView.alpha = 0
		self.parentView.insertSubview(self.contentView, belowSubview: self)
		self.contentView.fadeIn()
	}
	
	func hideBlur() {
		self.contentView.fadeOut() {
			finished in
			self.contentView.removeFromSuperview()
		}
	}
		
	private func degreesToRadians(degrees: CGFloat) -> CGFloat {
		return degrees / 180.0 * CGFloat(M_PI)
	}
}
