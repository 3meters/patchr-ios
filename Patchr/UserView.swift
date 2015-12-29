//
//  UserView.swift
//  Patchr
//
//  Created by Jay Massena on 10/18/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class UserView: BaseView {

	var name			= UILabel()
	var photo			= AirImageView(frame: CGRectZero)
	var area			= UILabel()
	var owner			= UILabel()
	var approved		= UILabel()
	var approvedSwitch	= UISwitch()
	var removeButton	= UIButton()

	weak var delegate:  UserApprovalViewDelegate?
	
	init() {
		super.init(frame: CGRectZero)
		initialize()
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

		/* User photo */
		self.photo.contentMode = UIViewContentMode.ScaleAspectFill
		self.photo.clipsToBounds = true
		self.photo.layer.cornerRadius = 48
		self.photo.layer.backgroundColor = Theme.colorBackgroundWindow.CGColor
		self.photo.sizeCategory = SizeCategory.profile
		self.addSubview(self.photo)

		/* User name */
		self.name.lineBreakMode = .ByTruncatingMiddle
		self.name.font = Theme.fontTextDisplay
		self.addSubview(self.name)
		
		/* User area */
		self.area.font = Theme.fontCommentSmall
		self.area.textColor = Theme.colorTextSecondary
		self.addSubview(self.area)
		
		/* Owner flag */
		self.owner.text = "OWNER"
		self.owner.font = Theme.fontCommentSmall
		self.owner.textColor = Theme.colorTint
		self.addSubview(self.owner)
		
		/* Remove button */
		self.removeButton.setImage(UIImage(named:"imgRemoveLight") , forState: UIControlState.Normal)
		self.removeButton.imageView?.contentMode = UIViewContentMode.Center
		self.removeButton.addTarget(self, action: Selector("removeButtonTouchUpInsideAction:"), forControlEvents: .TouchUpInside)
		self.addSubview(self.removeButton)
		
		/* Approved label */
		self.approved.text = "Approved:"
		self.approved.font = Theme.fontComment
		self.addSubview(self.approved)
		
		/* Approval switch */
		self.approvedSwitch.addTarget(self, action: Selector("approvedSwitchValueChangedAction:"), forControlEvents: .TouchUpInside)
		self.addSubview(self.approvedSwitch)
	}
	
	func bindToEntity(entity: AnyObject) {
		
		let entity = entity as! Entity
		
		self.entity = entity
		
		self.name.text = entity.name
		self.photo.setImageWithPhoto(entity.getPhotoManaged(), animate: self.photo.image == nil)
		
		if let user = entity as? User {
			self.area.text = user.area?.uppercaseString
			self.area.hidden = (self.area.text == nil)
			self.owner.hidden = true
			self.removeButton.hidden = true
			self.approved.hidden = true
			self.approvedSwitch.hidden = true
		}
		
		self.setNeedsLayout()
	}
	
	override func sizeThatFits(size: CGSize) -> CGSize {
		return CGSizeMake(self.width(), 113)
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		
		let columnLeft = CGFloat(96 + 8)
		let columnWidth = self.width() - columnLeft
		let nameSize = self.name.sizeThatFits(CGSizeMake(columnWidth, CGFloat.max))
		
		self.photo.anchorTopLeftWithLeftPadding(0, topPadding: 0, width: 96, height: 96)
		self.name.anchorTopLeftWithLeftPadding(columnLeft, topPadding: 6, width: columnWidth, height: nameSize.height)
		
		self.area.sizeToFit()
		self.owner.sizeToFit()
		self.approved.sizeToFit()
		
		self.area.alignUnder(self.name, matchingLeftWithTopPadding: 2, width: columnWidth, height: self.area.height())
		self.owner.alignUnder(self.area, matchingLeftWithTopPadding: 2, width: columnWidth, height: self.owner.height())
		self.approved.alignUnder(self.owner, matchingLeftWithTopPadding: 6, width: self.approved.width(), height: self.approved.height())
		
		self.approvedSwitch.alignToTheRightOf(self.approved, matchingCenterWithLeftPadding: 20, width: self.approvedSwitch.width(), height: self.approvedSwitch.height())
		self.removeButton.anchorTopRightWithRightPadding(0, topPadding: 0, width: 48, height: 48)
	}
	
	func approvedSwitchValueChangedAction(sender: UISwitch) {
		self.delegate?.userView(self, approvalSwitchValueChanged: self.approvedSwitch)
	}
	
	func removeButtonTouchUpInsideAction(sender: UIButton) {
		self.delegate?.userView(self, removeButtonTapped: self.removeButton)
	}
}

@objc
protocol UserApprovalViewDelegate {
	func userView(userView: UserView, approvalSwitchValueChanged approvalSwitch: UISwitch)
	func userView(userView: UserView, removeButtonTapped removeButton: UIButton)
}
