//
//  CaptionView.swift
//  Patchr
//
//  Created by Jay Massena on 5/12/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import UIKit
import IDMPhotoBrowser

class CaptionView: IDMCaptionView {
	
	var userName = AirLabelDisplay()
	var userPhoto = PhotoControl()
	var createdDate	= AirLabelDisplay()
	var caption	= AirLabelDisplay()
	var reactionButton: AirReactionButton!
	var displayPhoto: DisplayPhoto
	
	init!(displayPhoto: DisplayPhoto) {
		self.displayPhoto = displayPhoto
		super.init(photo: displayPhoto)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func layoutSubviews() {
		
		let columnLeft = CGFloat(16 + 32 + 8)
		let columnWidth = self.bounds.size.width - (columnLeft + 16)
		
		self.userPhoto.anchorTopLeft(withLeftPadding: 16, topPadding: 16, width: 32, height: 32)
		self.userPhoto.cornerRadius = 16
		
		self.createdDate.sizeToFit()
		self.userName.sizeToFit()
		if self.displayPhoto.caption != nil && self.displayPhoto.caption != "" {
			self.userName.align(toTheRightOf: self.userPhoto, matchingTopWithLeftPadding: 8, width: columnWidth - self.createdDate.width(), height: self.userName.height())
			self.createdDate.align(toTheRightOf: self.userName, matchingCenterWithLeftPadding: 0, width: columnWidth - self.userName.width(), height: self.createdDate.height())
			self.caption.bounds.size.width = columnWidth
			self.caption.sizeToFit()
			self.caption.alignUnder(self.userName, matchingLeftWithTopPadding: 0, width: self.caption.width(), height: self.caption.height())
		}
		else {
			self.userName.align(toTheRightOf: self.userPhoto, matchingCenterWithLeftPadding: 8, width: columnWidth - self.createdDate.width(), height: self.userName.height())
			self.createdDate.align(toTheRightOf: self.userName, matchingCenterWithLeftPadding: 0, width: columnWidth - self.userName.width(), height: self.createdDate.height())
		}
	}
	
	override func setupCaption() {
		initialize()
	}
	
	func initialize() {
		
		self.subviews.forEach({ $0.removeFromSuperview() })
		
		self.caption.numberOfLines = 3
		self.caption.font = Theme.fontTextList
		self.caption.lineBreakMode = .byTruncatingTail
		self.caption.text = self.displayPhoto.caption

		self.userName.font = Theme.fontTextListBold
		self.userName.numberOfLines = 1
		self.userName.text = self.displayPhoto.creatorName
		
        self.userPhoto.bind(url: self.displayPhoto.creatorUrl, name: self.displayPhoto.creatorName, colorSeed: nil)
		
		self.createdDate.font = Theme.fontComment
		self.createdDate.numberOfLines = 1
		self.createdDate.textColor = Theme.colorTextSecondary
		self.createdDate.textAlignment = .right
		self.createdDate.text = self.displayPhoto.createdDateLabel

		self.reactionButton = AirReactionButton(frame: CGRect.zero)

		self.backgroundColor = Theme.colorScrimCaption
		
		self.addSubview(self.userPhoto)
		self.addSubview(self.userName)
		self.addSubview(self.createdDate)
		self.addSubview(self.caption)
	}
	
	override func sizeThatFits(_ size: CGSize) -> CGSize {
		self.bounds.size.width = size.width
		self.setNeedsLayout()
		self.layoutIfNeeded()
		var size = sizeThatFitsSubviews()
		size.height += 16
		return size
	}
}
