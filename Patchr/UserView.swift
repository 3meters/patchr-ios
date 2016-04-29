//
//  UserView.swift
//  Patchr
//
//  Created by Jay Massena on 10/18/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class UserView: BaseView {

	var titleGroup		= UIView()
	var name			= AirLinkButton()
	var photo			= UserPhotoView()
	var area			= UILabel()
	var owner			= UILabel()
	
	var ownerGroup		= AirRuleView()
	var approved		= UILabel()
	var approvedSwitch	= UISwitch()
	var removeButton	= AirLinkButton()

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
		self.addSubview(self.photo)

		/* User name */
		self.name.titleLabel?.font = Theme.fontTextDisplay
		self.name.contentHorizontalAlignment = .Left
		self.name.addTarget(self, action: #selector(UserView.browseUser(_:)), forControlEvents: .TouchUpInside)
		self.titleGroup.addSubview(self.name)
		
		/* User area */
		self.area.font = Theme.fontCommentSmall
		self.area.textColor = Theme.colorTextSecondary
		self.titleGroup.addSubview(self.area)
		
		/* Owner flag */
		self.owner.text = "OWNER"
		self.owner.font = Theme.fontCommentSmall
		self.owner.textColor = Colors.accentOnLight
		self.titleGroup.addSubview(self.owner)
		
		self.ownerGroup.ruleBottom.hidden = true
		self.ownerGroup.ruleLeft.hidden = false
		self.ownerGroup.ruleLeft.backgroundColor = Colors.gray90pcntColor
		
		/* Remove button */
		self.removeButton.setImage(UIImage(named:"imgRemoveLight") , forState: UIControlState.Normal)
		self.removeButton.imageView?.contentMode = UIViewContentMode.Center
		self.removeButton.addTarget(self, action: #selector(UserView.removeButtonTouchUpInsideAction(_:)), forControlEvents: .TouchUpInside)
		self.titleGroup.addSubview(self.removeButton)
		
		/* Approved label */
		self.approved.text = "Approved"
		self.approved.font = Theme.fontComment
		self.approved.textColor = Theme.colorTextSecondary
		self.ownerGroup.addSubview(self.approved)
		
		/* Approval switch */
		self.approvedSwitch.addTarget(self, action: #selector(UserView.approvedSwitchValueChangedAction(_:)), forControlEvents: .TouchUpInside)
		self.ownerGroup.addSubview(self.approvedSwitch)
		self.addSubview(self.ownerGroup)
		self.addSubview(self.titleGroup)
	}
	
	override func bindToEntity(entity: AnyObject, location: CLLocation?) {
		
		let entity = entity as! Entity
		
		self.entity = entity
		
		self.name.setTitle(entity.name, forState: .Normal)
		self.photo.bindToEntity(entity)
		
		self.ownerGroup.hidden = true
		self.owner.hidden = true
		self.removeButton.hidden = true
		self.area.hidden = true
		
		if let user = entity as? User where user.area != nil {
			self.area.text = user.area.uppercaseString
			self.area.hidden = false
		}
		
		self.setNeedsLayout()	// Needed because elements can have changed dimensions
	}
	
	func showOwnerUI() {
		self.ownerGroup.hidden = false
		self.removeButton.hidden = false
		self.setNeedsLayout()
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		let ownerWidth = CGFloat(SCREEN_320 ? 96 : 112)
		
		let columnLeft = CGFloat(72 + 8)
		let columnRight = CGFloat(self.ownerGroup.hidden ? 0 : ownerWidth)
		let columnWidth = self.width() - (columnLeft + columnRight)
		
		self.photo.anchorTopLeftWithLeftPadding(0, topPadding: 0, width: 72, height: 72)
		self.titleGroup.anchorTopLeftWithLeftPadding(columnLeft, topPadding: 6, width: columnWidth, height: 72)
		self.name.sizeToFit()
		self.name.anchorTopLeftWithLeftPadding(0, topPadding: 0, width: self.name.width(), height: self.name.height() - 4)
		
		if !self.area.hidden {
			self.area.bounds.size.width = self.titleGroup.width()
			self.area.sizeToFit()
			self.area.alignUnder(self.name, matchingLeftWithTopPadding: -2, width: columnWidth, height: self.area.height())
		}
		
		if !self.owner.hidden {
			self.owner.sizeToFit()
			self.owner.alignUnder(self.area.hidden ? self.name : self.area, matchingLeftWithTopPadding: 2, width: columnWidth, height: self.owner.height())
		}
		
		if !self.removeButton.hidden {
			if SCREEN_320 {
				self.removeButton.anchorBottomLeftWithLeftPadding(0, bottomPadding: 0, width: 24, height: 24)
			}
			else {
				self.name.bounds.size.width = columnWidth - (8 + 24 + 8)
				self.name.sizeToFit()
				self.name.anchorTopLeftWithLeftPadding(0, topPadding: 0, width: columnWidth - (8 + 24 + 8), height: self.name.height() - 4)
				self.removeButton.alignToTheRightOf(self.name, matchingCenterWithLeftPadding: 8, width: 24, height: 24)
			}
		}
		
		if !self.ownerGroup.hidden {
			self.ownerGroup.anchorCenterRightFillingHeightWithTopPadding(0, bottomPadding: 0, rightPadding: 0, width: ownerWidth)
			self.approved.sizeToFit()
			self.approvedSwitch.anchorTopCenterWithTopPadding(16, width: self.approvedSwitch.width(), height: self.approvedSwitch.height())
			self.approved.alignUnder(self.approvedSwitch, matchingCenterWithTopPadding: 4, width: self.approved.width(), height: self.approved.height())
		}
	}
	
	func browseUser(sender: AnyObject) {
		if self.entity != nil {
			let controller = UserDetailViewController()
			controller.entityId = self.entity!.id_
			controller.profileMode = false
			let hostController = UIViewController.topMostViewController()!
			hostController.navigationController?.pushViewController(controller, animated: true)
		}
	}
	
	func approvedSwitchValueChangedAction(sender: UISwitch) {
		self.delegate?.userView(self, approvalSwitchValueChanged: self.approvedSwitch)
	}
	
	func removeButtonTouchUpInsideAction(sender: UIButton) {
		self.delegate?.userView(self, removeButtonTapped: self.removeButton)
	}
}

@objc protocol UserApprovalViewDelegate {
	func userView(userView: UserView, approvalSwitchValueChanged approvalSwitch: UISwitch)
	func userView(userView: UserView, removeButtonTapped removeButton: UIButton)
}
