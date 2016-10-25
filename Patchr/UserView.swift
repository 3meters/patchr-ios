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
	var photo			= PhotoView()
	var area			= UILabel()
	var owner			= UILabel()
	
	init() {
		super.init(frame: CGRect.zero)
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
		self.name.contentHorizontalAlignment = .left
		self.name.addTarget(self, action: #selector(UserView.browseUser(sender:)), for: .touchUpInside)
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
		
		self.name.setTitle(entity.name, for: .normal)
		self.photo.bindToEntity(entity: entity)
		
		self.owner.isHidden = true
		self.area.isHidden = true
		
		if let user = entity as? User , user.area != nil {
			self.area.text = user.area.uppercased()
			self.area.isHidden = false
		}
		
		self.setNeedsLayout()	// Needed because elements can have changed dimensions
	}
		
	override func layoutSubviews() {
		super.layoutSubviews()
		
		let columnLeft = CGFloat(72 + 8)
		let columnWidth = self.width() - columnLeft
		
		self.photo.anchorTopLeft(withLeftPadding: 0, topPadding: 0, width: 72, height: 72)
		self.titleGroup.anchorTopLeft(withLeftPadding: columnLeft, topPadding: 6, width: columnWidth, height: 72)
		self.name.sizeToFit()
		self.name.anchorTopLeft(withLeftPadding: 0, topPadding: 0, width: self.name.width(), height: self.name.height() - 4)
		
		if !self.area.isHidden {
			self.area.bounds.size.width = self.titleGroup.width()
			self.area.sizeToFit()
			self.area.alignUnder(self.name, matchingLeftWithTopPadding: -2, width: columnWidth, height: self.area.height())
		}
		
		if !self.owner.isHidden {
			self.owner.sizeToFit()
			self.owner.alignUnder(self.area.isHidden ? self.name : self.area, matchingLeftWithTopPadding: 2, width: columnWidth, height: self.owner.height())
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
