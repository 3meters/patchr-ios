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
		
		self.addSubview(self.titleGroup)
	}
	
	override func bindToEntity(entity: AnyObject, location: CLLocation?) {
		
		let entity = entity as! Entity
		
		self.entity = entity
		
		self.name.setTitle(entity.name, forState: .Normal)
		self.photo.bindToEntity(entity)
		
		self.owner.hidden = true
		self.area.hidden = true
		
		if let user = entity as? User where user.area != nil {
			self.area.text = user.area.uppercaseString
			self.area.hidden = false
		}
		
		self.setNeedsLayout()	// Needed because elements can have changed dimensions
	}
		
	override func layoutSubviews() {
		super.layoutSubviews()
		
		let columnLeft = CGFloat(72 + 8)
		let columnWidth = self.width() - columnLeft
		
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
}